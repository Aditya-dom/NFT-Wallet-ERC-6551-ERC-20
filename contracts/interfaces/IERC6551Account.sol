// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC6551Account {
    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);
}
