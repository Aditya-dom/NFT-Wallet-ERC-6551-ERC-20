// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITradingTools {
    enum OrderType {
        LIMIT,
        TAKE_PROFIT,
        STOP_LOSS
    }
    enum OrderStatus {
        PENDING,
        EXECUTED,
        CANCELLED,
        EXPIRED
    }

    struct Order {
        address owner;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 targetPrice;
        uint256 minAmountOut;
        uint256 deadline;
        OrderStatus status;
        OrderType orderType;
        bool isBuyOrder;
        uint256 createdAt;
        uint256 executedAt;
        address executor;
    }

    event OrderCreated(
        uint256 indexed orderId,
        address indexed owner,
        OrderType orderType,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 targetPrice,
        uint256 minAmountOut
    );
    event OrderExecuted(
        uint256 indexed orderId,
        address indexed executor,
        uint256 amountIn,
        uint256 amountOut,
        uint256 executionPrice
    );
    event OrderCancelled(uint256 indexed orderId, address indexed canceller);
    event FeeUpdated(uint256 newFee);
    event TreasuryUpdated(address newTreasury);
    event ExecutorUpdated(address executor, bool status);
    event EmergencyWithdraw(address token, uint256 amount);

    error InvalidPrice();
    error InvalidDeadline();
    error InvalidAmount();
    error InvalidOrder();
    error Unauthorized();
    error OrderExpired();
    error ExecutionFailed();
    error InsufficientOutput();
    error MaxOrdersExceeded();
    error InvalidFee();
    error InvalidAddress();
    error TransferFailed();
    error PriceMismatch();
    error DeadlineTooFar();
    error OrderVolumeLimitExceeded();
    error InvalidLimitPrice();
    error InvalidTakeProfitPrice();
    error InvalidStopLossPrice();
    error ExcessivePriceImpact();
}
