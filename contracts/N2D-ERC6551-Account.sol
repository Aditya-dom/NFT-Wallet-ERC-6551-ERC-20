// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "../imports/IERC6551.sol";
import "../imports/ERC6551Bytecode.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ERC6551Account is
    IERC165,
    IERC1271,
    IERC6551Account,
    IERC721Receiver,
    IERC1155Receiver,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    // Add state variables
    uint256 private _nonce;
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() {
        _supportedInterfaces[type(IERC165).interfaceId] = true;
        _supportedInterfaces[type(IERC6551Account).interfaceId] = true;
    }

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable nonReentrant returns (bytes memory result) {
        require(msg.sender == owner(), "Not token owner");
        require(to != address(0), "Invalid target address");

        _nonce++;

        bool success;
        (success, result) = to.call{value: value, gas: gasleft() - 2000}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function send(
        address payable to,
        uint256 amount
    ) external payable nonReentrant {
        require(msg.sender == owner(), "Not token owner");
        require(to != address(0), "Invalid target address");
        require(address(this).balance >= amount, "Insufficient funds");

        _nonce++;
        to.transfer(amount);
    }

    function sendCustom(
        address to,
        uint256 amount,
        IERC20 erc20contract
    ) external nonReentrant {
        require(msg.sender == owner(), "Not token owner");
        require(to != address(0), "Invalid target address");

        uint256 balance = erc20contract.balanceOf(address(this));
        require(balance >= amount, "Insufficient funds");

        _nonce++;
        erc20contract.transfer(to, amount);
    }

    function nftInfo()
        external
        view
        returns (uint256 chainId, address tokenContract, uint256 tokenId)
    {
        uint256 length = address(this).code.length;
        return
            abi.decode(
                Bytecode.codeAt(address(this), length - 0x60, length),
                (uint256, address, uint256)
            );
    }

    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = this
            .nftInfo();
        if (chainId != block.chainid) return address(0);
        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external view override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external view override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view returns (bytes4 magicValue) {
        bool isValid = SignatureChecker.isValidSignatureNow(
            owner(),
            hash,
            signature
        );

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return bytes4(0);
    }

    function nonce() external view override returns (uint256) {
        return _nonce;
    }

    receive() external payable {}
}
