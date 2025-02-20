// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IArbitrage {

    struct Pair {
        address pairAddress;
        address token0;
        address token1;
        address router;
        bool doesNextPathUseSameRouter;
    }

    event ArbitrageExecuted(
        uint256 amountIn,
        uint256 amountWplsBefore,
        uint256 amountWplsAfter,
        Pair[] path,
        uint256 profit
    );

    event ArbitrageFail(
        uint256 amountIn,
        uint256 amountWplsBefore,
        uint256 amountWplsAfter,
        Pair[] path,
        string message
    );

    event ArbitrageEpicFail(
        uint256 amountIn,
        Pair[] path,
        string message
    );



    function execute(uint256 amountIn, Pair[] calldata path) external;

    // Check if arb is succeed
    function getArbProfit(
        uint256 amountIn,
        Pair[] calldata pairPath
    ) external view returns (uint256);

    function getWplsBalance() external view returns (uint256);

    function withdraw(address tokenAddress) external;

    function approveToken(address approvee, address tokenAddress) external;

    function setWplsAddress(address _wplsAddress) external;
}
