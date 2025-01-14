// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./interface/IERC20.sol";
import "./interface/IUniswapV2Router02.sol";

contract Arbitrage {
    address public owner;

    mapping(address => bool) public authorizedAddresses;
    mapping(uint8 => address) public routerMap;

    address constant WPLS = 0xA1077a294dDE1B09bB078844df40758a5D0f9a27;

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
    address constant ROUTER_EZSWAP_V2 =
        0x05d5F20500eD8d9E012647E6CFe1b2Bf89f5b926;

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

        authorizedAddresses[owner] = true;
        authorizedAddresses[0xD73AA11744022Eb262d026f884DBA307c463c131] = true;
        authorizedAddresses[0x2b3A602abB7e35675693ff2b9f97E077D3c6AB2E] = true;

        routerMap[1] = ROUTER_UNISWAP_V2;
        routerMap[2] = ROUTER_SUSHI_SWAP_V2;
        routerMap[3] = ROUTER_PULSEX_V1;
        routerMap[4] = ROUTER_PULSEX_V2;
        routerMap[5] = ROUTER_SHIBASWAP;
        routerMap[6] = ROUTER_9MM_V2;
        routerMap[7] = ROUTER_9INCH_V2;
        routerMap[8] = ROUTER_PULSE_RATE_V2;
        routerMap[9] = ROUTER_EZSWAP_V2;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this");
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedAddresses[msg.sender], "Not authorized");
        _;
    }

    /**
     * @dev Fallback function to receive PLS
     */
    receive() external payable {}

    /**
     * @dev Add an address to the authorized list
     * @param _address The address to add to the authorized list
     */
    function authorizeAddress(address _address) public onlyOwner {
        authorizedAddresses[_address] = true;
    }

    /**
     * @dev Remove an address from the authorized list
     * @param _address The address to remove from the authorized list
     */
    function revokeAuthorization(address _address) public onlyOwner {
        authorizedAddresses[_address] = false;
    }

    /**
    /**
     * @dev Set the router for a given index
     * @param index The index of the router to set
     * @param router The address of the router to set
     */
    function setRouter(uint8 index, address router) public onlyOwner {
        routerMap[index] = router;
    }

    /**
     * @dev Get the router for a given index
     * @param index The index of the router to get
     * @return The address of the router
     */
    function getRouter(uint8 index) public view returns (address) {
        return routerMap[index];
    }

    function withdraw(address tokenAddress) public onlyOwner {
        uint256 amount = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transferFrom(address(this), msg.sender, amount);
    }

    // Function to withdraw native PLS
    function withdrawPLS() public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount >= 1_000_000_000_000_000_000, "Insufficient balance");

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

    function makeArbitrageTriangle(
        uint256 amountToken0,
        uint8 routerIndex0,
        uint8 routerIndex1,
        uint8 routerIndex2,
        address token1Address,
        address token2Address
    ) public onlyAuthorized {
        uint256 amountOut1 = _swapSimple(
            amountToken0,
            routerIndex0,
            WPLS,
            token1Address
        );

        uint256 amountOut2 = _swapSimple(
            amountOut1,
            routerIndex1,
            token1Address,
            token2Address
        );

        uint256 amountOut3 = _swapSimple(
            amountOut2,
            routerIndex2,
            token2Address,
            WPLS
        );

        require(amountOut3 > amountToken0, "Arbitrage not profitable");
    }

    function makeArbitrageTriangleNoCheck(
        uint256 amountToken0,
        uint8 routerIndex0,
        uint8 routerIndex1,
        uint8 routerIndex2,
        address token1Address,
        address token2Address
    ) public onlyAuthorized {
        uint256 amountOut1 = _swapSimple(
            amountToken0,
            routerIndex0,
            WPLS,
            token1Address
        );

        uint256 amountOut2 = _swapSimple(
            amountOut1,
            routerIndex1,
            token1Address,
            token2Address
        );

        _swapSimple(amountOut2, routerIndex2, token2Address, WPLS);
    }

    function makeArbitrageSimple(
        uint256 amountToken0,
        uint8 routerIndex0,
        uint8 routerIndex1,
        address token0Address,
        address token1Address
    ) public onlyAuthorized {
        uint256 amountOut = _swapSimple(
            amountToken0,
            routerIndex0,
            token0Address,
            token1Address
        );

        uint256 amountFinal = _swapSimple(
            amountOut,
            routerIndex1,
            token1Address,
            token0Address
        );

        require(amountFinal > amountToken0, "Arbitrage not profitable");
    }

    function makeArbitrageSimpleNoCheck(
        uint256 amountToken0,
        uint8 routerIndex0,
        uint8 routerIndex1,
        address token0Address,
        address token1Address
    ) public onlyAuthorized {
        uint256 amountOut = _swapSimple(
            amountToken0,
            routerIndex0,
            token0Address,
            token1Address
        );

        _swapSimple(amountOut, routerIndex1, token1Address, token0Address);
    }

    function _swapSimple(
        uint256 amountIn,
        uint8 routerIndex,
        address sell_token,
        address buy_token
    ) internal returns (uint256) {
        if (sell_token != WPLS) {
            IERC20(sell_token).approve(
                routerMap[routerIndex],
                type(uint256).max
            );
        }

        address[] memory path = new address[](2);
        path[0] = sell_token;
        path[1] = buy_token;

        uint256 amountOut = IUniswapV2Router02(routerMap[routerIndex])
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
        uint8 routerIndex,
        address[] calldata path
    ) internal returns (uint256) {
        address routerAddress = routerMap[routerIndex];
        if (path[0] != WPLS) {
            IERC20(path[0]).approve(routerAddress, amountIn);
        }

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
