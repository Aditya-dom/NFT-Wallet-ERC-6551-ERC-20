// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenboundAccount {
    address public controller;

    modifier onlyController() {
        require(msg.sender == controller, "Caller is not the controller");
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
        require(success, "Call failed");
        return result;
    }
}