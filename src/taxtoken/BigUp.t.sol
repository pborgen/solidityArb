// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../taxtoken/BigUp.sol";
import "../interface/IDopeDistributor.sol";

contract MockDopeDistributor is IDopeDistributor {
    function process(
        address /* token */,
        address /* rewardToken */
    ) external override {
        // Minimal mock: no implementation needed for basic tests
    }
}

contract BigUpTest is Test {
    address public deployer = makeAddr("deployer");
    address public addr1 = makeAddr("addr1");
    address public addr2 = makeAddr("addr2");

    BigUp public bigUp;
    MockDopeDistributor public distributor;

    // Initial parameters
    string private constant NAME = "BigUp";
    string private constant SYMBOL = "BUP";
    uint256 private constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18; // 1 billion tokens

    function setUp() public {
        // Deploy the mock DopeDistributor
        vm.prank(deployer);
        distributor = new MockDopeDistributor();

        // Deploy BigUp with the mock distributor and a dummy reward token address (0x0 for this test)
        vm.prank(deployer);
        bigUp = new BigUp(
            NAME,
            SYMBOL,
            TOTAL_SUPPLY,
            address(distributor),
            address(0)
        );

        vm.prank(deployer);
        bigUp.transfer(addr1, 100_000 * 10 ** 18);

        console.log("balanceOf addr1", bigUp.balanceOf(addr1));
    }

    /// @notice Test that the constructor sets the correct total supply and owner balance
    // function testInitialSetup() public {
    //     // Check total supply
    //     assertEq(bigUp.totalSupply(), TOTAL_SUPPLY, "Total supply mismatch");

    //     // Check fee basis points default (3% as per BigUp code)
    //     assertEq(bigUp.feeBasisPoints(), 300, "Fee basis points should be 300 (3%)");
    // }

    /// @notice Test a standard transfer to verify fees are deducted and accumulated
    function testFeeOnTransfer() public {
        console.log("balanceOf addr1", bigUp.balanceOf(addr1));
        // Create a recipient address
        address recipient = address(0x123);

        // Transfer amount
        uint256 transferAmount = 1_000 * 10 ** 18;

        // Transfer tokens from this contract (owner) to recipient
        vm.prank(addr1);
        bigUp.transfer(recipient, transferAmount);

        // Calculate the expected fee
        // fee = (amount * feeBasisPoints) / 10000
        uint256 fee = (transferAmount * bigUp.feeBasisPoints()) / 10000;

        // Check the fee has been added to gatheredFees
        assertEq(bigUp.gatheredFees(), fee, "gatheredFees mismatch");

        // Recipient should receive transferAmount - fee
        uint256 expectedNetAmount = transferAmount - fee;
        assertEq(
            bigUp.balanceOf(recipient),
            expectedNetAmount,
            "Recipient balance mismatch"
        );
    }

    /// @notice Test that fees are transferred to the distributor when gatheredFees >= amountToHoldBeforeDistribute
    function testFeesSentToDistributor() public {
        // amountToHoldBeforeDistribute is 10_000_000_000_000_000_000 by default in BigUp
        // We'll reduce it so we don't need a huge test transfer
        vm.prank(deployer);
        bigUp.updateAmountToHoldBeforeDistribute(1_000 * 10 ** 18);

        // Transfer enough tokens to surpass the threshold
        // This will trigger fee distribution
        vm.prank(addr1);
        bigUp.transfer(address(0x456), 50_000 * 10 ** 18);

        // gatheredFees should reset to 0 after distribution
        uint256 gatheredAfter = bigUp.gatheredFees();
        assertEq(gatheredAfter, 0, "gatheredFees should reset to zero");

        // Check if the distributor got tokens.
        // The exact amount the distributor receives = last known fee (based on BigUp logic).
        // For demonstration, we'll just confirm the call didn't fail.
        // (If you track the distributor's token balance, ensure the distributor or token
        // contract provides a way to check balances or events.)
    }
}
