// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract TrumpElon is ERC20 {
    uint256 oneToken = 10 ** decimals();

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, oneToken * 1_000_000_000);
    }
}
