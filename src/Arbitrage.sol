// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./interface/IERC20.sol";
import "./interface/IUniswapV2Router02.sol";
import "./interface/IUniswapV2Pair.sol";
import "./interface/IArbitrage.sol";

contract Arbitrage is IArbitrage {
    address public owner;

    address WPLS = 0xA1077a294dDE1B09bB078844df40758a5D0f9a27;

    uint256 constant ONE_PLS = 10 ** 18;
    uint256 minProfitInPls = ONE_PLS * 300;

    address constant ROUTER_UNISWAP_V2 =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant ROUTER_SUSHI_SWAP_V2 =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address constant ROUTER_PULSEX_V1 =
        0x98bf93ebf5c380C0e6Ae8e192A7e2AE08edAcc02;
    address constant ROUTER_PULSEX_V2 =
        0x165C3410fC91EF562C50559f7d2289fEbed552d9;
    address constant ROUTER_SHIBASWAP =
        0x03f7724180AA6b939894B5Ca4314783B0b36b329;
    address constant ROUTER_9MM_V2 = 0xcC73b59F8D7b7c532703bDfea2808a28a488cF47;
    address constant ROUTER_9INCH_V2 =
        0xeB45a3c4aedd0F47F345fB4c8A1802BB5740d725;
    address constant ROUTER_PULSE_RATE_V2 =
        0x71bb8a2feD36aa2dEa9f8f9Cb43E038315Dd7ba3;

    constructor(bool skipApprove) {
        owner = msg.sender;

        if (!skipApprove) {
            approveToken(ROUTER_UNISWAP_V2, WPLS);
            approveToken(ROUTER_SUSHI_SWAP_V2, WPLS);
            approveToken(ROUTER_PULSEX_V1, WPLS);
            approveToken(ROUTER_PULSEX_V2, WPLS);
            approveToken(ROUTER_SHIBASWAP, WPLS);
            approveToken(ROUTER_9MM_V2, WPLS);
            approveToken(ROUTER_9INCH_V2, WPLS);
            approveToken(ROUTER_PULSE_RATE_V2, WPLS);
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this");
        _;
    }

    /**
     * @dev Fallback function to receive PLS
     */
    receive() external payable {}

    function execute(uint256 amountIn, Pair[] calldata path) public {
        uint256 arbProfit = getArbProfit(amountIn, path);

        if (arbProfit < minProfitInPls) {
            revert("epic fail");
        }

        uint256 balanceWplsBefore = IERC20(WPLS).balanceOf(address(this));

        executeArb(amountIn, path);

        uint256 balanceWplsAfter = IERC20(WPLS).balanceOf(address(this));

        emit ArbitrageExecuted(amountIn, balanceWplsBefore, balanceWplsAfter, path, 0);

        if (balanceWplsAfter > balanceWplsBefore) {
            // We have profit
            uint256 profit = balanceWplsAfter - balanceWplsBefore;

            if (profit >= minProfitInPls) {
                emit ArbitrageExecuted(amountIn, balanceWplsBefore, balanceWplsAfter, path, profit);
                return;
            } else {
                revert("not enough profit");
            }
        } else {
            revert("negative profit");
        }

        
    }

    // Check if arb is succeed
    function getArbProfit(
        uint256 amountIn,
        Pair[] calldata pairPath
    ) public view returns (uint256) {
        for (uint256 i = 0; i < pairPath.length; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                pairPath[i].pairAddress,
                pairPath[i].token0,
                pairPath[i].token1
            );

            // Store amount out to amountIn for use in the next iteration if there is one
            amountIn = IUniswapV2Router02(pairPath[i].router).getAmountOut(
                amountIn,
                reserveIn,
                reserveOut
            );
        }

        return amountIn;
    }

    // Execute arb
    function executeArb(uint256 amountIn, Pair[] calldata pairPath) public {
        address[] memory path = new address[](2);

        for (uint256 i = 0; i < pairPath.length; i++) {
            path[0] = pairPath[i].token0;
            path[1] = pairPath[i].token1;

            // Skip the first pair because it is WPLS and already approved
            if (i > 0) {
                uint256 allowance = IERC20(path[0]).allowance(
                    address(this),
                    pairPath[i].router
                );
                if (allowance < amountIn) {
                    IERC20(path[0]).approve(
                        pairPath[i].router,
                        type(uint256).max
                    );
                }
            }

            uint256 outTokenBalanceBefore = IERC20(path[1]).balanceOf(
                address(this)
            );

            // Store amount out to amountIn for use in the next iteration if there is one
            IUniswapV2Router02(pairPath[i].router)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    amountIn,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );

            amountIn =
                IERC20(path[1]).balanceOf(address(this)) -
                outTokenBalanceBefore;
        }
    }

    function getReserves(
        address pairAddress,
        address tokenA,
        address tokenB
    ) internal view returns (uint reserveA, uint reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(pairAddress)
            .getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    function getWplsBalance() public view returns (uint256) {
        return IERC20(WPLS).balanceOf(address(this));
    }

    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
    }

    function withdraw(address tokenAddress) public onlyOwner {
        uint256 amount = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transferFrom(address(this), msg.sender, amount);
    }

    function withdrawWpls() public onlyOwner {
        uint256 amount = IERC20(WPLS).balanceOf(address(this));
        IERC20(WPLS).transferFrom(address(this), msg.sender, amount);
    }

    // Function to withdraw native PLS
    function withdrawPLS() public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount >= 10 * ONE_PLS, "Insufficient balance");

        // Transfer the specified amount of PLS to the owner
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function approveToken(
        address approvee,
        address tokenAddress
    ) public onlyOwner {
        uint maxInt = type(uint256).max;
        IERC20(tokenAddress).approve(approvee, maxInt);
    }

    function setMinProfitInPls(uint256 _minProfitInPls) public onlyOwner {
        minProfitInPls = _minProfitInPls;
    }

    function setWplsAddress(address _wplsAddress) public onlyOwner {
        WPLS = _wplsAddress;
    }
}
