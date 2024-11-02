// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/utils/Create2.sol";

contract ERC6551Registry {
    event AccountCreated(address indexed accountAddress);


    error InitializationFailed();

    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt,
        bytes calldata initData
    ) external returns (address accountAddress) {
        require(implementation != address(0), "Invalid implementation");
        require(tokenContract != address(0), "Invalid token contract");

        bytes memory code = _creationCode(
            implementation,
            chainId,
            tokenContract,
            tokenId,
            salt
        );

        accountAddress = Create2.computeAddress(
            bytes32(salt),
            keccak256(code)
        );

        if (accountAddress.code.length > 0) {
            return accountAddress;
        }

        accountAddress = Create2.deploy(0, bytes32(salt), code);

        if (initData.length > 0) {
            (bool success, ) = accountAddress.call(initData);
            if (!success) revert InitializationFailed();
        }

        emit AccountCreated(
            accountAddress
        );
    }

    function account(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    ) external view returns (address) {
        bytes32 bytecodeHash = keccak256(
            _creationCode(implementation, chainId, tokenContract, tokenId, salt)
        );

        return Create2.computeAddress(bytes32(salt), bytecodeHash);
    }

    function _creationCode(
        address implementation_,
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_,
        uint256 salt_
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
                implementation_,
                hex"5af43d82803e903d91602b57fd5bf3",
                abi.encode(salt_, chainId_, tokenContract_, tokenId_)
            );
    }
}
