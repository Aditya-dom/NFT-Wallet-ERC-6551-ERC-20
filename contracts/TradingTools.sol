// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITradingTools.sol";
import "./PriceOracle.sol";

contract TradingTools is ITradingTools, ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;

    // Constants
    uint256 private constant MIN_EXECUTION_FEE = 0.001 ether;
    uint256 private constant MAX_EXECUTION_FEE = 0.1 ether;
    uint256 private constant MAX_ORDER_DURATION = 7 days;
    uint256 private constant MAX_PRICE_IMPACT = 100; // 1% max price impact
    uint256 private constant MIN_ORDER_VALUE = 10 * 10 ** 18; // Minimum order value (10 tokens)
    uint256 private constant MAX_USER_ORDER_VOLUME = 1_000_000 * 10 ** 18; // Maximum total order volume per user

    // State variables
    struct OrderState {
        mapping(uint256 => Order) orders;
        mapping(address => bool) executors;
        mapping(address => uint256) userOrderCount;
        mapping(address => uint256) userOrderVolume;
        uint256 nextOrderId;
        uint256 maxOrdersPerUser;
        uint256 executionFee;
        address treasury;
        address priceOracle;
    }

    OrderState private _state;

    // Events (in addition to inherited events)
    event OrderVolumeUpdated(address indexed user, uint256 totalVolume);
    event PriceImpactExceeded(uint256 orderId, uint256 priceImpact);

    constructor(
        address _priceOracle,
        address _treasury,
        uint256 _executionFee,
        uint256 _maxOrdersPerUser,
        address _initialOwner
    ) Ownable(_initialOwner) {
        // Validate constructor parameters
        if (_priceOracle == address(0) || _treasury == address(0))
            revert InvalidAddress();
        if (
            _executionFee < MIN_EXECUTION_FEE ||
            _executionFee > MAX_EXECUTION_FEE
        ) revert InvalidFee();

        _state.priceOracle = _priceOracle;
        _state.treasury = _treasury;
        _state.executionFee = _executionFee;
        _state.maxOrdersPerUser = _maxOrdersPerUser;
    }

    function createOrder(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _targetPrice,
        uint256 _minAmountOut,
        uint256 _deadline,
        OrderType _orderType,
        bool _isBuyOrder
    ) external payable nonReentrant whenNotPaused returns (uint256) {
        // Validate order parameters
        _validateOrderCreation(
            _tokenIn,
            _tokenOut,
            _amountIn,
            _targetPrice,
            _minAmountOut,
            _deadline,
            _orderType,
            _isBuyOrder
        );

        // Transfer tokens from user
        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);

        // Create order ID
        uint256 orderId = _state.nextOrderId++;

        // Store the order
        _state.orders[orderId] = Order({
            owner: msg.sender,
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            amountIn: _amountIn,
            targetPrice: _targetPrice,
            minAmountOut: _minAmountOut,
            deadline: _deadline,
            status: OrderStatus.PENDING,
            orderType: _orderType,
            isBuyOrder: _isBuyOrder,
            createdAt: block.timestamp,
            executedAt: 0,
            executor: address(0)
        });

        // Update user order tracking
        _state.userOrderCount[msg.sender]++;
        _state.userOrderVolume[msg.sender] += _amountIn;

        // Emit event
        emit OrderCreated(
            orderId,
            msg.sender,
            _orderType,
            _tokenIn,
            _tokenOut,
            _amountIn,
            _targetPrice,
            _minAmountOut
        );
        emit OrderVolumeUpdated(msg.sender, _state.userOrderVolume[msg.sender]);

        return orderId;
    }

    // Comprehensive order creation validation
    function _validateOrderCreation(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _targetPrice,
        uint256 _minAmountOut,
        uint256 _deadline,
        OrderType _orderType,
        bool _isBuyOrder
    ) internal view {
        // Basic amount and fee checks
        if (_amountIn < MIN_ORDER_VALUE) revert InvalidAmount();
        if (_minAmountOut == 0) revert InvalidAmount();
        if (msg.value != _state.executionFee) revert InvalidFee();

        // Deadline checks
        if (_deadline <= block.timestamp) revert InvalidDeadline();
        if (_deadline > block.timestamp + MAX_ORDER_DURATION)
            revert DeadlineTooFar();

        // User limit checks
        if (_state.userOrderCount[msg.sender] >= _state.maxOrdersPerUser)
            revert MaxOrdersExceeded();
        if (
            _state.userOrderVolume[msg.sender] + _amountIn >
            MAX_USER_ORDER_VOLUME
        ) revert OrderVolumeLimitExceeded();

        // Price oracle validation
        uint256 currentPrice = PriceOracle(_state.priceOracle).getPrice(
            _tokenIn,
            _tokenOut
        );

        // Validate target price based on order type and direction
        _validateTargetPrice(
            _orderType,
            _isBuyOrder,
            currentPrice,
            _targetPrice
        );
    }

    // Validate target price based on order type and direction
    function _validateTargetPrice(
        OrderType _orderType,
        bool _isBuyOrder,
        uint256 currentPrice,
        uint256 targetPrice
    ) internal pure {
        if (_orderType == OrderType.LIMIT) {
            if (_isBuyOrder) {
                // Buy limit: target price should be LOWER than current price
                if (targetPrice >= currentPrice) revert InvalidLimitPrice();
            } else {
                // Sell limit: target price should be HIGHER than current price
                if (targetPrice <= currentPrice) revert InvalidLimitPrice();
            }
        } else if (_orderType == OrderType.TAKE_PROFIT) {
            if (_isBuyOrder) {
                // Buy TP: target price should be LOWER than current price
                if (targetPrice >= currentPrice)
                    revert InvalidTakeProfitPrice();
            } else {
                // Sell TP: target price should be HIGHER than current price
                if (targetPrice <= currentPrice)
                    revert InvalidTakeProfitPrice();
            }
        } else if (_orderType == OrderType.STOP_LOSS) {
            if (_isBuyOrder) {
                // Buy SL: target price should be HIGHER than current price
                if (targetPrice <= currentPrice) revert InvalidStopLossPrice();
            } else {
                // Sell SL: target price should be LOWER than current price
                if (targetPrice >= currentPrice) revert InvalidStopLossPrice();
            }
        }
    }

    // Improved Order Execution Function
    function executeOrder(
        uint256 _orderId
    ) external nonReentrant whenNotPaused {
        // Retrieve the order
        Order storage order = _state.orders[_orderId];

        // Validate order status and deadline
        _validateOrderExecution(order);

        // Get current price
        uint256 currentPrice = PriceOracle(_state.priceOracle).getPrice(
            order.tokenIn,
            order.tokenOut
        );

        // Check if order should be executed based on improved logic
        if (!_shouldExecuteOrder(order, currentPrice)) {
            revert PriceMismatch();
        }

        // Calculate and validate price impact
        uint256 priceImpact = _calculatePriceImpact(order, currentPrice);
        if (priceImpact > MAX_PRICE_IMPACT) {
            emit PriceImpactExceeded(_orderId, priceImpact);
            revert ExcessivePriceImpact();
        }

        // Update order status
        order.status = OrderStatus.EXECUTED;
        order.executedAt = block.timestamp;
        order.executor = msg.sender;

        // Decrement user order tracking
        _state.userOrderCount[order.owner]--;
        _state.userOrderVolume[order.owner] -= order.amountIn;

        // Pay execution fee
        (bool success, ) = _state.treasury.call{value: _state.executionFee}("");
        if (!success) revert TransferFailed();

        // Emit events
        emit OrderExecuted(
            _orderId,
            msg.sender,
            order.amountIn,
            order.minAmountOut,
            currentPrice
        );
        emit OrderVolumeUpdated(
            order.owner,
            _state.userOrderVolume[order.owner]
        );
    }

    // Validate order execution conditions
    function _validateOrderExecution(Order storage order) internal view {
        if (order.status != OrderStatus.PENDING) revert InvalidOrder();
        if (block.timestamp > order.deadline) {
            revert OrderExpired();
        }
    }

    // Improved order execution logic
    function _shouldExecuteOrder(
        Order memory order,
        uint256 currentPrice
    ) internal pure returns (bool) {
        if (order.orderType == OrderType.LIMIT) {
            return
                order.isBuyOrder
                    ? currentPrice <= order.targetPrice // Buy: Execute when price drops
                    : currentPrice >= order.targetPrice; // Sell: Execute when price rises
        } else if (order.orderType == OrderType.TAKE_PROFIT) {
            return
                order.isBuyOrder
                    ? currentPrice <= order.targetPrice // Buy TP: Execute when price drops
                    : currentPrice >= order.targetPrice; // Sell TP: Execute when price rises
        } else if (order.orderType == OrderType.STOP_LOSS) {
            return
                order.isBuyOrder
                    ? currentPrice >= order.targetPrice // Buy SL: Execute when price rises
                    : currentPrice <= order.targetPrice; // Sell SL: Execute when price drops
        }
        return false;
    }

    // Calculate price impact
    function _calculatePriceImpact(
        Order memory order,
        uint256 currentPrice
    ) internal view returns (uint256) {
        // This is a placeholder. In a real implementation,
        // you'd calculate actual price impact based on order size and liquidity
        uint256 referencePrice = PriceOracle(_state.priceOracle).getPrice(
            order.tokenIn,
            order.tokenOut
        );

        if (referencePrice == 0) return 0;

        uint256 priceDiff = referencePrice > currentPrice
            ? referencePrice - currentPrice
            : currentPrice - referencePrice;

        return (priceDiff * 10000) / referencePrice;
    }

    // Admin functions

    function setExecutor(address _executor, bool _status) external onlyOwner {
        if (_executor == address(0)) revert InvalidAddress();
        _state.executors[_executor] = _status;
        emit ExecutorUpdated(_executor, _status);
    }

    function setExecutionFee(uint256 _newFee) external onlyOwner {
        if (_newFee < MIN_EXECUTION_FEE || _newFee > MAX_EXECUTION_FEE)
            revert InvalidFee();
        _state.executionFee = _newFee;
        emit FeeUpdated(_newFee);
    }

    function setTreasury(address _newTreasury) external onlyOwner {
        if (_newTreasury == address(0)) revert InvalidAddress();
        _state.treasury = _newTreasury;
        emit TreasuryUpdated(_newTreasury);
    }

    function setPriceOracle(address _newOracle) external onlyOwner {
        if (_newOracle == address(0)) revert InvalidAddress();
        _state.priceOracle = _newOracle;
    }

    function setMaxOrdersPerUser(uint256 _maxOrders) external onlyOwner {
        _state.maxOrdersPerUser = _maxOrders;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function emergencyWithdraw(
        address _token,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(_token, _amount);
    }

    // View functions
    function getOrder(uint256 _orderId) external view returns (Order memory) {
        return _state.orders[_orderId];
    }

    function getUserOrderCount(address _user) external view returns (uint256) {
        return _state.userOrderCount[_user];
    }

    function getUserOrderVolume(address _user) external view returns (uint256) {
        return _state.userOrderVolume[_user];
    }

    function getExecutionFee() external view returns (uint256) {
        return _state.executionFee;
    }
}

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/utils/Address.sol";
// import "./interfaces/ITradingTools.sol";
// import "./TradingToolsStorage.sol";
// import "./PriceOracle.sol";
// import "./interfaces/I1inchRouter.sol";
// import "./interfaces/IERC6551Account.sol";

// contract TradingTools is
//     ITradingTools,
//     TradingToolsStorage,
//     ReentrancyGuard,
//     Pausable,
//     Ownable
// {
//     using SafeERC20 for IERC20;
//     using Address for address;

//     address public oneInchRouter;
//     address public swapTarget; // The actual DEX or aggregator implementation

//     uint256 private constant MAX_BPS = 10000;
//     uint256 private constant MIN_EXECUTION_FEE = 0.001 ether;
//     uint256 private constant MAX_EXECUTION_FEE = 0.1 ether;

//     constructor(
//         address _priceOracle,
//         address _treasury,
//         uint256 _executionFee,
//         uint256 _maxOrdersPerUser,
//         address _oneInchRouter,
//         address _swapTarget
//     ) {
//         if (
//             _priceOracle == address(0) ||
//             _treasury == address(0) ||
//             _oneInchRouter == address(0) ||
//             _swapTarget == address(0)
//         ) revert InvalidAddress();
//         if (
//             _executionFee < MIN_EXECUTION_FEE ||
//             _executionFee > MAX_EXECUTION_FEE
//         ) revert InvalidFee();

//         _state.priceOracle = _priceOracle;
//         _state.treasury = _treasury;
//         _state.executionFee = _executionFee;
//         _state.maxOrdersPerUser = _maxOrdersPerUser;
//         oneInchRouter = _oneInchRouter;
//         swapTarget = _swapTarget;
//     }

//     receive() external payable {}

//     function createOrder(
//         address _tokenIn,
//         address _tokenOut,
//         uint256 _amountIn,
//         uint256 _targetPrice,
//         uint256 _minAmountOut,
//         uint256 _deadline,
//         OrderType _orderType
//     ) external payable nonReentrant whenNotPaused returns (uint256) {
//         // Validations
//         if (_amountIn == 0 || _minAmountOut == 0) revert InvalidAmount();
//         if (_deadline <= block.timestamp) revert InvalidDeadline();
//         if (_targetPrice == 0) revert InvalidPrice();
//         if (msg.value != _state.executionFee) revert InvalidFee();
//         if (_state.userOrderCount[msg.sender] >= _state.maxOrdersPerUser)
//             revert MaxOrdersExceeded();

//         // Transfer tokens
//         IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);

//         // Create order
//         uint256 orderId = _state.nextOrderId++;
//         _state.orders[orderId] = Order({
//             owner: msg.sender,
//             tokenIn: _tokenIn,
//             tokenOut: _tokenOut,
//             amountIn: _amountIn,
//             targetPrice: _targetPrice,
//             minAmountOut: _minAmountOut,
//             deadline: _deadline,
//             status: OrderStatus.PENDING,
//             orderType: _orderType,
//             createdAt: block.timestamp,
//             executedAt: 0,
//             executor: address(0)
//         });

//         _state.userOrderCount[msg.sender]++;

//         emit OrderCreated(
//             orderId,
//             msg.sender,
//             _orderType,
//             _tokenIn,
//             _tokenOut,
//             _amountIn,
//             _targetPrice,
//             _minAmountOut
//         );

//         return orderId;
//     }

//     function executeOrder(
//         uint256 _orderId
//     ) external nonReentrant whenNotPaused {
//         Order storage order = _state.orders[_orderId];

//         if (order.status != OrderStatus.PENDING) revert InvalidOrder();
//         if (!_state.executors[msg.sender] && msg.sender != order.owner)
//             revert Unauthorized();
//         if (block.timestamp > order.deadline) {
//             order.status = OrderStatus.EXPIRED;
//             revert OrderExpired();
//         }

//         uint256 currentPrice = PriceOracle(_state.priceOracle).getPrice(
//             order.tokenIn,
//             order.tokenOut
//         );

//         bool shouldExecute = _shouldExecuteOrder(order, currentPrice);
//         if (!shouldExecute) revert PriceMismatch();

//         // Execute swap
//         uint256 balanceBefore = IERC20(order.tokenOut).balanceOf(order.owner);
//         _executeSwap(order);
//         uint256 balanceAfter = IERC20(order.tokenOut).balanceOf(order.owner);
//         uint256 amountOut = balanceAfter - balanceBefore;

//         if (amountOut < order.minAmountOut) revert InsufficientOutput();

//         // Update order status
//         order.status = OrderStatus.EXECUTED;
//         order.executedAt = block.timestamp;
//         order.executor = msg.sender;
//         _state.userOrderCount[order.owner]--;

//         // Pay execution fee
//         (bool success, ) = _state.treasury.call{value: _state.executionFee}("");
//         if (!success) revert TransferFailed();

//         emit OrderExecuted(
//             _orderId,
//             msg.sender,
//             order.amountIn,
//             amountOut,
//             currentPrice
//         );
//     }

//     function cancelOrder(uint256 _orderId) external nonReentrant {
//         Order storage order = _state.orders[_orderId];

//         if (msg.sender != order.owner) revert Unauthorized();
//         if (order.status != OrderStatus.PENDING) revert InvalidOrder();

//         order.status = OrderStatus.CANCELLED;
//         _state.userOrderCount[order.owner]--;

//         // Refund tokens and execution fee
//         IERC20(order.tokenIn).safeTransfer(order.owner, order.amountIn);
//         (bool success, ) = order.owner.call{value: _state.executionFee}("");
//         if (!success) revert TransferFailed();

//         emit OrderCancelled(_orderId, msg.sender);
//     }

//     function _shouldExecuteOrder(
//         Order memory order,
//         uint256 currentPrice
//     ) internal pure returns (bool) {
//         if (order.orderType == OrderType.LIMIT) {
//             return currentPrice <= order.targetPrice;
//         } else if (order.orderType == OrderType.TAKE_PROFIT) {
//             return currentPrice >= order.targetPrice;
//         } else if (order.orderType == OrderType.STOP_LOSS) {
//             return currentPrice <= order.targetPrice;
//         }
//         return false;
//     }

//     function _executeSwap(Order memory order) internal {
//         uint256 initialBalance = IERC20(order.tokenOut).balanceOf(order.owner);

//         I1inchRouter.SwapDescription memory desc = I1inchRouter
//             .SwapDescription({
//                 srcToken: order.tokenIn,
//                 dstToken: order.tokenOut,
//                 srcReceiver: swapTarget, // The DEX or aggregator that will receive the source tokens
//                 dstReceiver: order.owner, // The TBA wallet that will receive the output tokens
//                 amount: order.amountIn,
//                 minReturnAmount: order.minAmountOut,
//                 flags: 0 // No special flags
//             });

//         IERC20(order.tokenIn).safeApprove(swapTarget, 0);
//         IERC20(order.tokenIn).safeApprove(swapTarget, order.amountIn);

//         // Execute the swap through the TBA wallet
//         try
//             IERC6551Account(order.owner).executeCall(
//                 oneInchRouter,
//                 0, // No ETH value sent
//                 abi.encodeWithSelector(
//                     I1inchRouter.swap.selector,
//                     address(this),
//                     desc,
//                     "", // No permit data
//                     "" // Swap data would come from 1inch API
//                 )
//             )
//         returns (bytes memory result) {
//             // Decode swap results
//             (uint256 returnAmount, uint256 spentAmount) = abi.decode(
//                 result,
//                 (uint256, uint256)
//             );

//             // Verify the swap was successful
//             uint256 finalBalance = IERC20(order.tokenOut).balanceOf(
//                 order.owner
//             );
//             uint256 actualReceived = finalBalance - initialBalance;

//             if (actualReceived < order.minAmountOut) {
//                 revert InsufficientOutput();
//             }

//             // Emit successful execution event
//             emit OrderExecuted(
//                 0, // orderId should be passed in or tracked
//                 msg.sender,
//                 spentAmount,
//                 actualReceived,
//                 PriceOracle(_state.priceOracle).getPrice(
//                     order.tokenIn,
//                     order.tokenOut
//                 )
//             );
//         } catch {
//             revert ExecutionFailed();
//         }
//     }

//     // Admin functions

//     function setOneInchRouter(address _newRouter) external onlyOwner {
//         if (_newRouter == address(0)) revert InvalidAddress();
//         oneInchRouter = _newRouter;
//     }

//     function setSwapTarget(address _newTarget) external onlyOwner {
//         if (_newTarget == address(0)) revert InvalidAddress();
//         swapTarget = _newTarget;
//     }

//     function setExecutor(address _executor, bool _status) external onlyOwner {
//         if (_executor == address(0)) revert InvalidAddress();
//         _state.executors[_executor] = _status;
//         emit ExecutorUpdated(_executor, _status);
//     }

//     function setExecutionFee(uint256 _newFee) external onlyOwner {
//         if (_newFee < MIN_EXECUTION_FEE || _newFee > MAX_EXECUTION_FEE)
//             revert InvalidFee();
//         _state.executionFee = _newFee;
//         emit FeeUpdated(_newFee);
//     }

//     function setTreasury(address _newTreasury) external onlyOwner {
//         if (_newTreasury == address(0)) revert InvalidAddress();
//         _state.treasury = _newTreasury;
//         emit TreasuryUpdated(_newTreasury);
//     }

//     function setPriceOracle(address _newOracle) external onlyOwner {
//         if (_newOracle == address(0)) revert InvalidAddress();
//         _state.priceOracle = _newOracle;
//     }

//     function setMaxOrdersPerUser(uint256 _maxOrders) external onlyOwner {
//         _state.maxOrdersPerUser = _maxOrders;
//     }

//     function pause() external onlyOwner {
//         _pause();
//     }

//     function unpause() external onlyOwner {
//         _unpause();
//     }

//     function emergencyWithdraw(
//         address _token,
//         uint256 _amount
//     ) external onlyOwner {
//         IERC20(_token).safeTransfer(msg.sender, _amount);
//         emit EmergencyWithdraw(_token, _amount);
//     }

//     function getOrder(uint256 _orderId) external view returns (Order memory) {
//         return _state.orders[_orderId];
//     }

//     function getUserOrderCount(address _user) external view returns (uint256) {
//         return _state.userOrderCount[_user];
//     }

//     function getExecutionFee() external view returns (uint256) {
//         return _state.executionFee;
//     }
// }
