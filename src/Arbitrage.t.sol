// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interface/IUniswapV2Router02.sol";
import "./interface/IUniswapV2Pair.sol";
import "./interface/IArbitrage.sol";

import "forge-std/Test.sol";
import "./Arbitrage.sol";
import "./MyErc20.sol" as MyErc20Alias;

contract ArbitrageTest is Test {
    IArbitrage arbitrage;
    MyErc20Alias.MyErc20 tokenWplsErc20;
    MyErc20Alias.MyErc20 tokenHexErc20;

    uint256 constant initialWplsBalanceInArbitrageContract = 1000 * 1e18;

    address deployer = address(1);
    address erc20Creator = address(2);
    address runner = address(3);

    IUniswapV2Router02 routerPulseXV1;
    IUniswapV2Router02 routerPulseXV2;

    IUniswapV2Pair pair0PulseXV1;
    IUniswapV2Pair pair1PulseXV2;

    function setUp() public {
        vm.startPrank(deployer);

        // Deploy the Router
        routerPulseXV1 = new MockIUniswapV2Router02();
        routerPulseXV2 = new MockIUniswapV2Router02();

        // Create a pairs
        pair0PulseXV1 = new MockIUniswapV2Pair();
        pair1PulseXV2 = new MockIUniswapV2Pair();

        arbitrage = new Arbitrage(true);
        arbitrage.setWplsAddress(address(tokenWplsErc20));

        vm.stopPrank();

        vm.startPrank(erc20Creator);

        tokenWplsErc20 = new MyErc20Alias.MyErc20("WPLS", "WPLS");
        tokenHexErc20 = new MyErc20Alias.MyErc20("HEX", "HEX");

        // Send some wpls to the mev contract
        tokenWplsErc20.transfer(
            address(arbitrage),
            initialWplsBalanceInArbitrageContract
        );
        vm.stopPrank();

        vm.startPrank(deployer);

        // Approve the MEV contract to spend WPLS on the below routers
        arbitrage.approveToken(
            address(routerPulseXV1),
            address(tokenWplsErc20)
        );
        arbitrage.approveToken(
            address(routerPulseXV2),
            address(tokenWplsErc20)
        );

        vm.stopPrank();

        // Verify the initial balance of WPLS in the arbitrage contract
        assertEq(
            tokenWplsErc20.balanceOf(address(arbitrage)),
            initialWplsBalanceInArbitrageContract
        );
    }

    function testGetProfit() public {
        uint256 amountIn = 1 * 1e18;

        Arbitrage.Pair[] memory path = new Arbitrage.Pair[](2);
        path[0] = IArbitrage.Pair(
            address(pair0PulseXV1),
            address(tokenWplsErc20),
            address(tokenHexErc20),
            address(routerPulseXV1),
            false,
            3000
        );
        path[1] = IArbitrage.Pair(
            address(pair1PulseXV2),
            address(tokenHexErc20),
            address(tokenWplsErc20),
            address(routerPulseXV2),
            false,
            3000
        );

        uint256 profit = arbitrage.getArbProfit(amountIn, path);
        console.log("Profit: %s", profit);
        assertGt(profit, 0, "Profit should be greater than 0");
    }

    // Mock router for testing purposes
    // MockRouter mockRouter;
    // address mockRouterAddress;

    //     function testExecuteArbitrage() public {
    //         // Setup mock paths and pairs
    //         Arbitrage.Pair[] memory path = new Arbitrage.Pair[](2);
    //         path[0] = Arbitrage.Pair(
    //             mockRouterAddress,
    //             WPLS,
    //             address(0x1),
    //             mockRouterAddress,
    //             false
    //         );
    //         path[1] = Arbitrage.Pair(
    //             mockRouterAddress,
    //             address(0x1),
    //             WPLS,
    //             mockRouterAddress,
    //             false
    //         );

    //         // Mock the arbitrage profit to be above the minimum
    //         uint256 amountIn = 1000 * 1e18; // 1000 PLS in wei
    //         vm.mockCall(
    //             mockRouterAddress,
    //             abi.encodeWithSelector(IUniswapV2Router02.getAmountOut.selector),
    //             abi.encode(amountIn * 2)
    //         ); // Mock a 2x return for simplicity

    //         uint256 balanceBefore = arbitrage.getWplsBalance();
    //         arbitrage.execute(amountIn, path);
    //         uint256 balanceAfter = arbitrage.getWplsBalance();

    //         assertGt(
    //             balanceAfter,
    //             balanceBefore,
    //             "Arbitrage should increase balance"
    //         );
    //     }

    //     function testFailArbitrageNotProfitable() public {
    //         // Setup for arbitrage that isn't profitable
    //         Arbitrage.Pair[] memory path = new Arbitrage.Pair[](2);
    //         path[0] = Arbitrage.Pair(
    //             mockRouterAddress,
    //             WPLS,
    //             address(0x1),
    //             mockRouterAddress,
    //             false
    //         );
    //         path[1] = Arbitrage.Pair(
    //             mockRouterAddress,
    //             address(0x1),
    //             WPLS,
    //             mockRouterAddress,
    //             false
    //         );

    //         // Mock the arbitrage profit to be below the minimum
    //         uint256 amountIn = 1000 * 1e18;
    //         vm.mockCall(
    //             mockRouterAddress,
    //             abi.encodeWithSelector(IUniswapV2Router02.getAmountOut.selector),
    //             abi.encode(amountIn)
    //         ); // No profit

    //         arbitrage.execute(amountIn, path);
    //     }

    //     function testWithdraw() public {
    //         // Assume some balance for testing
    //         deal(WPLS, address(arbitrage), 100 * 1e18); // Give contract some WPLS for testing

    //         uint256 balanceBefore = IERC20(WPLS).balanceOf(address(arbitrage));
    //         arbitrage.withdraw(WPLS);
    //         uint256 balanceAfter = IERC20(WPLS).balanceOf(address(arbitrage));

    //         assertEq(balanceAfter, 0, "All WPLS should be withdrawn");
    //     }

    //     function testSetMinProfit() public {
    //         uint256 newMinProfit = 500 * 1e18;
    //         arbitrage.setMinProfitInPls(newMinProfit);
    //         assertEq(
    //             arbitrage.minProfitInPls(),
    //             newMinProfit,
    //             "Min profit should be updated"
    //         );
    //     }

    //     function testFailWithdrawPLSNotEnoughBalance() public {
    //         arbitrage.withdrawPLS(); // Should fail since no PLS balance
    //     }
    // }

    // // Mock Router for testing purposes, only implementing necessary methods
    // contract MockRouter is IUniswapV2Router02 {
    //     function getAmountOut(
    //         uint amountIn,
    //         uint,
    //         uint
    //     ) external pure override returns (uint) {
    //         return amountIn; // Return the same amount for simplicity
    //     }

    //     function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //         uint amountIn,
    //         uint amountOutMin,
    //         address[] calldata path,
    //         address to,
    //         uint deadline
    //     ) external override {
    //         // Just for test to ensure function is called
    //     }
}

contract MockIUniswapV2Router02 is IUniswapV2Router02 {
    address constant WPLS = 0xA1077a294dDE1B09bB078844df40758a5D0f9a27;

    function factory() external pure returns (address) {
        return address(0xdead);
    }

    function WETH() external pure returns (address) {
        return WPLS;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        return (0, 0, 0);
    }

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
    {
        return (0, 0, 0);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        return (0, 0);
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH) {
        return (0, 0);
    }

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
    ) external returns (uint256 amountA, uint256 amountB) {
        return (0, 0);
    }

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
    ) external returns (uint256 amountToken, uint256 amountETH) {
        return (0, 0);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        return new uint256[](path.length);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        return new uint256[](path.length);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts) {
        return new uint256[](path.length);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        return new uint256[](path.length);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        return new uint256[](path.length);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts) {
        return new uint256[](path.length);
    }

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB) {
        return amountA;
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut) {
        return amountIn;
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn) {
        return amountOut;
    }

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts) {
        return new uint256[](path.length);
    }

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts) {
        return new uint256[](path.length);
    }

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH) {
        return 0;
    }

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
    ) external returns (uint256 amountETH) {
        return 0;
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        return;
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable {
        return;
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        return;
    }
}

contract MockIUniswapV2Pair is IUniswapV2Pair {
    function getReserves() external view returns (uint112, uint112, uint32) {
        return (1 * 1e18, 1 * 1e18, 1);
    }
}
