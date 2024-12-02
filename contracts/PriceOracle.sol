// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract PriceOracle is Ownable {
    using SafeERC20 for IERC20;

    mapping(address => address) public priceFeeds;
    mapping(address => uint8) public decimals;
    uint256 public constant PRICE_PRECISION = 1e18;
    uint256 public stalePriceDelay = 3600; // 1 hour

    event PriceFeedUpdated(address token, address feed);
    event StalePriceDelayUpdated(uint256 newDelay);

    error InvalidPriceFeed();
    error StalePrice();
    error PriceFeedNotSet();

    constructor(
        address initialOwner,
        uint256 _stalePriceDelay
    ) Ownable(initialOwner) {
        stalePriceDelay = _stalePriceDelay;
    }

    function setPriceFeed(
        address token,
        address feed,
        uint8 _decimals
    ) external onlyOwner {
        if (feed == address(0)) revert InvalidPriceFeed();
        priceFeeds[token] = feed;
        decimals[token] = _decimals;
        emit PriceFeedUpdated(token, feed);
    }

    function getPrice(
        address tokenIn,
        address tokenOut
    ) external view returns (uint256) {
        if (
            priceFeeds[tokenIn] == address(0) ||
            priceFeeds[tokenOut] == address(0)
        ) revert PriceFeedNotSet();

        (
            uint80 roundId1,
            int256 price1,
            uint256 startedAt1,
            uint256 updatedAt1,
            uint80 answeredInRound1
        ) = AggregatorV3Interface(priceFeeds[tokenIn]).latestRoundData();

        if (
            price1 <= 0 ||
            updatedAt1 == 0 ||
            answeredInRound1 < roundId1 ||
            block.timestamp - updatedAt1 > stalePriceDelay
        ) revert StalePrice();

        (
            uint80 roundId2,
            int256 price2,
            uint256 startedAt2,
            uint256 updatedAt2,
            uint80 answeredInRound2
        ) = AggregatorV3Interface(priceFeeds[tokenOut]).latestRoundData();

        if (
            price2 <= 0 ||
            updatedAt2 == 0 ||
            answeredInRound2 < roundId2 ||
            block.timestamp - updatedAt2 > stalePriceDelay
        ) revert StalePrice();

        uint256 normalizedPrice1 = uint256(price1) *
            (10 ** (PRICE_PRECISION - decimals[tokenIn]));
        uint256 normalizedPrice2 = uint256(price2) *
            (10 ** (PRICE_PRECISION - decimals[tokenOut]));

        return (normalizedPrice1 * PRICE_PRECISION) / normalizedPrice2;
    }

    function setStalePriceDelay(uint256 _stalePriceDelay) external onlyOwner {
        stalePriceDelay = _stalePriceDelay;
        emit StalePriceDelayUpdated(_stalePriceDelay);
    }
}
