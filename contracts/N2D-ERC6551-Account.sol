// SPDX-License-Identifier: MIT

/*
Follow/Subscribe Youtube, Github, IM, Tiktok
for more amazing content!!
@Net2Dev
███╗░░██╗███████╗████████╗██████╗░██████╗░███████╗██╗░░░██╗
████╗░██║██╔════╝╚══██╔══╝╚════██╗██╔══██╗██╔════╝██║░░░██║
██╔██╗██║█████╗░░░░░██║░░░░░███╔═╝██║░░██║█████╗░░╚██╗░██╔╝
██║╚████║██╔══╝░░░░░██║░░░██╔══╝░░██║░░██║██╔══╝░░░╚████╔╝░
██║░╚███║███████╗░░░██║░░░███████╗██████╔╝███████╗░░╚██╔╝░░
╚═╝░░╚══╝╚══════╝░░░╚═╝░░░╚══════╝╚═════╝░╚══════╝░░░╚═╝░░░
THIS CONTRACT IS AVAILABLE FOR EDUCATIONAL 
PURPOSES ONLY. YOU ARE SOLELY REPONSIBLE 
FOR ITS USE. I AM NOT RESPONSIBLE FOR ANY
OTHER USE. THIS IS TRAINING/EDUCATIONAL
MATERIAL. ONLY USE IT IF YOU AGREE TO THE
TERMS SPECIFIED ABOVE.
*/

pragma solidity ^0.8.23;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol"; // signature validation standard
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
// import "https://github.com/net2devcrypto/ERC-6551-NFT-Wallets-Web3-Front-End-NextJS/blob/main/imports/IERC6551.sol";
// import "https://github.com/net2devcrypto/ERC-6551-NFT-Wallets-Web3-Front-End-NextJS/blob/main/imports/ERC6551Bytecode.sol";
import "../imports/IERC6551.sol";
import "../imports/ERC6551Bytecode.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // reentrancy protection when external calls are made

contract ERC6551Account is IERC165, IERC1271, IERC6551Account, ReentrancyGuard {
    using SafeERC20 for IERC20;

    //////////////////////////////////////////
    //////////////// ERRORS //////////////////
    //////////////////////////////////////////
    error ERC6551Account__NotOwner();
    error ERC6551Account__ExternalCallFailed();
    error ERC6551Account__LowBalanceToTransferFunds();
    error ERC6551Account__LowERC20TokenBalance();
    error ERC6551Account__FailedDueToZeroAddressTransfer();
    error ERC6551Account__IncorrectArraySize();



    //////////////////////////////////////////
    /////////////// Functions ////////////////
    //////////////////////////////////////////
    function executeCall(address to, uint256 value, bytes calldata data)
        external
        payable
        nonReentrant
        returns (bytes memory result)
    {
        if (to == address(0)) {
            revert ERC6551Account__FailedDueToZeroAddressTransfer();
        }

        if (msg.sender != owner()) {
            revert ERC6551Account__NotOwner();
        }

        if (address(this).balance < value) {
            revert ERC6551Account__LowBalanceToTransferFunds();
        }

        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function batchTransferEth(address[] calldata to, uint256[] calldata amounts) external payable nonReentrant {
        if (msg.sender != owner()) {
            revert ERC6551Account__NotOwner();
        }

        uint256 toArraySize = to.length;
        uint256 amountsArraySize = amounts.length;

        if (toArraySize != amountsArraySize) {
            revert ERC6551Account__IncorrectArraySize();
        }

        for (uint256 i = 0; i < toArraySize; i++) {
            if (address(this).balance < amounts[i]) {
                revert ERC6551Account__LowBalanceToTransferFunds();
            }

            if (to[i] == address(0)) {
                revert ERC6551Account__FailedDueToZeroAddressTransfer();
            }

            (bool success,) = to[i].call{value: amounts[i]}("");
            if (!success) {
                revert ERC6551Account__ExternalCallFailed();
            }
        }
    }

    function simpleEthTransferAccount(address payable to, uint256 amount) external payable nonReentrant {
        if (to == address(0)) {
            revert ERC6551Account__FailedDueToZeroAddressTransfer();
        }

        if (msg.sender != owner()) {
            revert ERC6551Account__NotOwner();
        }

        if (address(this).balance < amount) {
            revert ERC6551Account__LowBalanceToTransferFunds();
        }

        (bool success,) = to.call{value: amount}("");
        if (!success) {
            revert ERC6551Account__ExternalCallFailed();
        }
    }

    // added non renetrancy in case dealing with erc 1155 token standard
    function sendCustomErcTransfer(address to, uint256 amount, IERC20 erc20contract) external nonReentrant {
        if (to == address(0)) {
            revert ERC6551Account__FailedDueToZeroAddressTransfer();
        }

        if (msg.sender != owner()) {
            revert ERC6551Account__NotOwner();
        }

        uint256 balance = erc20contract.balanceOf(address(this));

        if (balance < amount) {
            revert ERC6551Account__LowERC20TokenBalance();
        }

        erc20contract.transfer(to, amount);
    }

    function nftInfo() external view returns (uint256 chainId, address tokenContract, uint256 tokenId) {
        uint256 length = address(this).code.length;
        return abi.decode(Bytecode.codeAt(address(this), length - 0x60, length), (uint256, address, uint256));
    }

    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = this.nftInfo();
        if (chainId != block.chainid) return address(0);
        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return (interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC6551Account).interfaceId);
    }

    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 signValues) {
        bool isValid = SignatureChecker.isValidSignatureNow(owner(), hash, signature);
        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }
        return "end";
    }

    function nonce() external view override returns (uint256) {}
    receive() external payable {}

    fallback() external payable {}
}
