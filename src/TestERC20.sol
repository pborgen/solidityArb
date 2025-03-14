// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    uint256 oneToken = 10 ** decimals();

    constructor() ERC20("TestERC20", "TEST") {
        _mint(msg.sender, oneToken * 1_000_000_000_000);
    }
}
