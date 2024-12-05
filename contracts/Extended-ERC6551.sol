// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract ExtendedERC6551Account is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public immutable uniswapRouter;

    constructor(address _uniswapRouter) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }

    // Buy tokens using ETH
    function buyTokens(
        address token,
        uint256 minTokensOut
    ) external payable nonReentrant {
        require(msg.value > 0, "ETH required");

        address;
        path[0] = uniswapRouter.WETH();
        path[1] = token;

        uint256 deadline = block.timestamp + 300; // 5 minutes

        uniswapRouter.swapExactETHForTokens{value: msg.value}(
            minTokensOut,
            path,
            address(this),
            deadline
        );
    }

    // Sell tokens for ETH
    function sellTokens(
        address token,
        uint256 tokenAmount,
        uint256 minEthOut
    ) external nonReentrant {
        IERC20(token).safeApprove(address(uniswapRouter), tokenAmount);

        address;
        path[0] = token;
        path[1] = uniswapRouter.WETH();

        uint256 deadline = block.timestamp + 300; // 5 minutes

        uniswapRouter.swapExactTokensForETH(
            tokenAmount,
            minEthOut,
            path,
            address(this),
            deadline
        );
    }

    // Swap tokens
    function swapTokens(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToTokensOut
    ) external nonReentrant {
        IERC20(fromToken).safeApprove(address(uniswapRouter), fromAmount);

        address;
        path[0] = fromToken;
        path[1] = toToken;

        uint256 deadline = block.timestamp + 300; // 5 minutes

        uniswapRouter.swapExactTokensForTokens(
            fromAmount,
            minToTokensOut,
            path,
            address(this),
            deadline
        );
    }

    // Receive ETH into the contract
    receive() external payable {}
}
