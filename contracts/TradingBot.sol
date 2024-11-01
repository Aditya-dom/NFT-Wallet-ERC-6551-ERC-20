// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TradingBot {
    struct Order {
        address user;
        uint256 amount; // Amount of tokens to trade
        uint256 price; // Set the price for the order
        bool isBuy; // True= If buy order and False= if sell order
        bool active; // Order status
        uint256 takeProfit; //Take the profit price set by the user
        uint256 stopLoss; //Stop the loss price set by the user
    }

    mapping(uint256 => Order) public orders; // Order Ids for order mapping

    uint256 public orderCount; // Order counter

    //Defining events for order function
    event OrderPlaced(
        uint256 indexed orderId,
        address indexed user,
        uint256 amount,
        uint256 price,
        bool isBuy
    );
    event OrderExecuted(
        uint256 indexed orderId,
        address indexed user,
        uint256 amount,
        uint256 price
    );
    event OrderCancelled(uint256 indexed orderId, address indexed user);
    event TPExecuted(
        uint256 indexed orderId,
        address indexed user,
        uint256 amount,
        uint256 price
    );
    event SLExecuted(
        uint256 indexed orderId,
        address indexed user,
        uint256 amount,
        uint256 price
    );

    //Function to place order

    function placeOrder(
        uint256 amount,
        uint256 price,
        bool isBuy,
        uint256 takeProfit,
        uint256 stopLoss
    ) external {
        orderCount++;
        orders[orderCount] = Order(
            msg.sender,
            amount,
            price,
            isBuy,
            true,
            takeProfit,
            stopLoss
        );

        emit OrderPlaced(orderCount, msg.sender, amount, price, isBuy);
    }

    //Function to execute an Order
    function executeOrder(uint256 orderId, uint256 marketPrice) external {
        Order storage order = orders[orderId];
        require(order.active, "Order is not active");

        //checking if market price meets the order price

        if (order.isBuy && marketPrice <= order.price) {
            //Executing buy order logic
            _transferTokens(msg.sender, order.amount); //Creating a custom function to transer tokens
            order.active = false;
            emit OrderExecuted(orderId, msg.sender, order.amount, marketPrice);   
        } else if (!order.isBuy && marketPrice >= order.price) {
            //Executing sell order
            _transferTokens(msg.sender, order.amount);
            order.active = false;
            emit OrderExecuted(orderId, msg.sender, order.amount, ,marketPrice);
        }

        if(marketPrice >= order.takeProfit) {
            //Executing TP
            _transferTokens(msg.sender, order.amount);
            order.active = false;
            emit TPExecuted(orderId, msg.sender, order.amount, marketPrice );
        } else if (marketPrice <= order.stopLoss) {
            //Executing Stop Loss
            _transferTokens(msg.sender, order.amount);
            order.active = false;
            emit SLExecuted(orderId, msg.sender, order.amount, marketPrice );
        }
    }

    // Function to cancel the order

    function cancellOrder(uint256 orderId) external {
        Order storage order= orders[orderId];
        require(order.active, "Order is not active");
        require(order.user == msg.sender, "Only the owner can cancel");
        order.active = false;
        emit OrderCancelled(orderId, msg.sender);
    }
}
