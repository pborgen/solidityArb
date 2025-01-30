// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "../interface/IDividendDistributor.sol";
import "../interface/IDexRouter.sol";
import "../interface/IDopeDistributor.sol";

contract DopeDistributor is IDopeDistributor, Ownable {
    address public _token;
    IERC20 public immutable reward;
    address public immutable ETH;

    address constant routerAddress = 0x165C3410fC91EF562C50559f7d2289fEbed552d9;
    IDexRouter constant dexRouter = IDexRouter(routerAddress);
    uint256 public slippage = 98;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address _reward) Ownable(msg.sender) {
        reward = IERC20(_reward);
        approveRouterForAddress();
        ETH = dexRouter.WPLS();
    }

    function approveRouterForAddress() public {
        reward.approve(routerAddress, type(uint256).max);
    }

    function deposit() external payable override {
        uint256 amount;
        if (address(reward) != ETH) {
            address[] memory path = new address[](2);
            path[0] = dexRouter.WPLS();
            path[1] = address(reward);

            uint256 spend = address(this).balance;
            uint256[] memory amountsOut = dexRouter.getAmountsOut(spend, path);

            uint256 curBal = reward.balanceOf(address(this));

            dexRouter.swapExactETHForTokens{value: spend}(
                (amountsOut[1] * slippage) / 100,
                path,
                address(this),
                block.timestamp
            );

            amount = reward.balanceOf(address(this)) - curBal;
        } else {
            amount = msg.value;
        }
    }

    function extractLostETH() external onlyOwner {
        bool success;
        (success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function setSlippage(uint256 _slip) external onlyOwner {
        require(_slip <= 100, "Min slippage reached");
        require(_slip >= 50, "Probably too much slippage");
        slippage = _slip;
    }
}
