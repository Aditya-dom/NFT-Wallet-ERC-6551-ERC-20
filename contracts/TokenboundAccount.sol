// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract TokenboundAccount {

    error TokenboundAccount__InvalidController();
    error TokenboundAccount__ExecuteCallFailed();


    address public controller;

    modifier onlyController() {
        if (msg.sender != controller) revert TokenboundAccount__InvalidController();
        _;
    }

    constructor(address _controller) {
        controller = _controller;
    }

    function restrictedFunction() external onlyController {
        // Only accessible by the controller
    }

    function transferController(address newController) external onlyController {
        controller = newController;
    }

    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) external onlyController returns (bytes memory) {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) revert TokenboundAccount__ExecuteCallFailed();
        return result;
    }
}