// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/ITradingTools.sol";

contract TradingToolsStorage {
    struct TradingToolsState {
        mapping(uint256 => ITradingTools.Order) orders;
        mapping(address => bool) executors;
        mapping(address => uint256) userOrderCount;
        uint256 nextOrderId;
        uint256 maxOrdersPerUser;
        uint256 executionFee;
        address treasury;
        address priceOracle;
        bool paused;
    }

    TradingToolsState internal _state;
}
