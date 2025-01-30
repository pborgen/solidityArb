// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "../interface/IDividendDistributor.sol";
import "../interface/IDexRouter.sol";
import "../interface/IDopeDistributor.sol";

contract DopeDistributor is IDopeDistributor, Ownable {
    address constant WPLS = 0xA1077a294dDE1B09bB078844df40758a5D0f9a27;
    address routerAddress = 0x165C3410fC91EF562C50559f7d2289fEbed552d9;
    IDexRouter constant dexRouter = IDexRouter(routerAddress);

    constructor() Ownable(msg.sender) {}

    function process(address _token) external override {
        uint256 amount;

        swapTokensForEth(_token, amount);
    }

    function swapTokensForEth(address _token, uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = WPLS;

        if (
            IERC20(_token).allowance(address(this), routerAddress) < tokenAmount
        ) {
            IERC20(_token).approve(routerAddress, type(uint256).max);
        }

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function approveAddress(address _address) external onlyOwner {
        reward.approve(_address, type(uint256).max);
    }

    function cleanUpPls() external onlyOwner {
        bool success;
        (success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function cleanUpToken(address _token) external onlyOwner {
        IERC20(_token).transfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }

    function updateRouterAddress(address _routerAddress) external onlyOwner {
        routerAddress = _routerAddress;
    }
}
