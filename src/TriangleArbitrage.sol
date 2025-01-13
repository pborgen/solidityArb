// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./interface/IERC20.sol";
import "./interface/IUniswapV2Router02.sol";

contract TriangleArbitrage {
    address public owner;
    address constant WPLS = 0xA1077a294dDE1B09bB078844df40758a5D0f9a27;

    address constant ROUTER_UNISWAP_V2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant ROUTER_SUSHI_SWAP_V2 = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address constant ROUTER_PULSEX_V1 = 0x98bf93ebf5c380C0e6Ae8e192A7e2AE08edAcc02;
    address constant ROUTER_PULSEX_V2 = 0x165C3410fC91EF562C50559f7d2289fEbed552d9;
    address constant ROUTER_SHIBASWAP = 0x03f7724180AA6b939894B5Ca4314783B0b36b329;
    address constant ROUTER_9MM_V2 = 0xcC73b59F8D7b7c532703bDfea2808a28a488cF47;
    address constant ROUTER_9INCH_V2 = 0xeB45a3c4aedd0F47F345fB4c8A1802BB5740d725;
    address constant ROUTER_PULSE_RATE_V2 = 0x71bb8a2feD36aa2dEa9f8f9Cb43E038315Dd7ba3;
    address constant ROUTER_EZSWAP_V2 = 0x05d5F20500eD8d9E012647E6CFe1b2Bf89f5b926;
  
    constructor() {
        owner = msg.sender;

        approveToken(ROUTER_UNISWAP_V2, WPLS);
        approveToken(ROUTER_SUSHI_SWAP_V2, WPLS);
        approveToken(ROUTER_PULSEX_V1, WPLS);
        approveToken(ROUTER_PULSEX_V2, WPLS);
        approveToken(ROUTER_SHIBASWAP, WPLS);
        approveToken(ROUTER_9MM_V2, WPLS);
        approveToken(ROUTER_9INCH_V2, WPLS);
        approveToken(ROUTER_PULSE_RATE_V2, WPLS);
        approveToken(ROUTER_EZSWAP_V2, WPLS);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this");
        _;
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

    function makeArbitrage(
        uint256 amountToken0,
        address routerAddress0,
        address routerAddress1,
        address routerAddress2,
        address token1Address,
        address token2Address
    ) public {
        uint256 amountOut1 = _swapSimple(
            amountToken0,
            routerAddress0,
            WPLS,
            token1Address
        );

        uint256 amountOut2 = _swapSimple(
            amountOut1,
            routerAddress1,
            token1Address,
            token2Address
        );

        uint256 amountOut3 = _swapSimple(
            amountOut2,
            routerAddress2,
            token2Address,
            WPLS
        );

        require(amountOut3 > amountToken0, "Arbitrage not profitable");
    }

    function makeArbitrageNoCheck(
        uint256 amountToken0,
        address routerAddress0,
        address routerAddress1,
        address routerAddress2,
        address token1Address,
        address token2Address
    ) public {
        uint256 amountOut1 = _swapSimple(
            amountToken0,
            routerAddress0,
            WPLS,
            token1Address
        );

        uint256 amountOut2 = _swapSimple(
            amountOut1,
            routerAddress1,
            token1Address,
            token2Address
        );

        _swapSimple(amountOut2, routerAddress2, token2Address, WPLS);
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
