// SPDX-License-Identifier: MIT 
pragma solidity 0.8.17;

import "./interface/IERC20.sol";
import "./interface/IUniswapV2Router02.sol";

contract SimpleArbitrage {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this");
        _;
    }

    function deposit(uint256 amount, address token) public onlyOwner {
        require(amount > 0, "Deposit amount must be greater than 0");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount, address tokenAddress) public onlyOwner {
        IERC20(tokenAddress).transferFrom(address(this), msg.sender, amount);
    }

    function approveToken(
        address approvee,
        address tokenAddress
    ) public onlyOwner {
        uint maxInt = type(uint256).max;
        IERC20(tokenAddress).approve(approvee, maxInt);
    }

    function makeArbitrageSimple(
        uint256 amountToken0,
        address routerAddress0,
        address routerAddress1,
        address token0Address,
        address token1Address
    ) public {
        uint256 amountOut = _swapSimple(
            amountToken0,
            routerAddress0,
            token0Address,
            token1Address
        );

        uint256 amountFinal = _swapSimple(
            amountOut,
            routerAddress1,
            token1Address,
            token0Address
        );

        require(amountFinal > amountToken0, "Arbitrage not profitable");
    }

    function makeArbitrageSimpleNoCheck(
        uint256 amountToken0,
        address routerAddress0,
        address routerAddress1,
        address token0Address,
        address token1Address
    ) public {
        uint256 amountOut = _swapSimple(
            amountToken0,
            routerAddress0,
            token0Address,
            token1Address
        );

        _swapSimple(amountOut, routerAddress1, token1Address, token0Address);
    }

    function makeArbitrageSimpleWithPath(
        uint256 amountToken0,
        address routerAddress0,
        address routerAddress1,
        address[] calldata pathRouter0,
        address[] calldata pathRouter1
    ) public {
        uint256 amountOut = _swapSimpleWithPath(
            amountToken0,
            routerAddress0,
            pathRouter0
        );
        uint256 amountFinal = _swapSimpleWithPath(
            amountOut,
            routerAddress1,
            pathRouter1
        );

        require(amountFinal > amountToken0, "Arbitrage not profitable");
    }

    function _swapSimple(
        uint256 amountIn,
        address routerAddress,
        address sell_token,
        address buy_token
    ) internal returns (uint256) {
        IERC20(sell_token).approve(routerAddress, amountIn);

        address[] memory path = new address[](2);
        path[0] = sell_token;
        path[1] = buy_token;

        uint256 amountOut = IUniswapV2Router02(routerAddress)
            .swapExactTokensForTokens(
                amountIn,
                0,
                path,
                address(this),
                block.timestamp
            )[1];
        return amountOut;
    }

    function _swapSimpleWithPath(
        uint256 amountIn,
        address routerAddress,
        address[] calldata path
    ) internal returns (uint256) {
        IERC20(path[0]).approve(routerAddress, amountIn);

        uint256 amountOut = IUniswapV2Router02(routerAddress)
            .swapExactTokensForTokens(
                amountIn,
                0,
                path,
                address(this),
                block.timestamp
            )[1];
        return amountOut;
    }
}
