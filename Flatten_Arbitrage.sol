// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

// src/interface/IERC20.sol

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// src/interface/IUniswapV2Router01.sol

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

// src/interface/IUniswapV2Router02.sol

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// src/Arbitrage.sol

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
        IERC20(sell_token).approve(getRouter(routerIndex), type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = sell_token;
        path[1] = buy_token;

        uint256 amountOut = IUniswapV2Router02(getRouter(routerIndex))
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

