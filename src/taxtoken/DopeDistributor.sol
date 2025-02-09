//  __      __.__              .__
// /  \    /  \__| ____   ____ |__| ____    ____
// \   \/\/   /  |/    \ /    \|  |/    \  / ___\
//  \        /|  |   |  \   |  \  |   |  \/ /_/  >
//   \__/\  / |__|___|  /___|  /__|___|  /\___  /
//        \/          \/     \/        \//_____/

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
    IDexRouter dexRouter = IDexRouter(routerAddress);

    address collector = 0xBBd48Ad4ef9994E514d0EA2277E2fEc3B32e79F2;

    constructor() Ownable(msg.sender) {}

    function process(
        address _token,
        address _tokenAddressToBuy
    ) external override {
        swapTokensForTokens(_token, _tokenAddressToBuy);

        IERC20 tokenToBuy = IERC20(_tokenAddressToBuy);

        tokenToBuy.transfer(collector, tokenToBuy.balanceOf(address(this)));
    }

    function swapTokensForTokens(address _tokenIn, address _tokenOut) private {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        uint256 amountIn = IERC20(_tokenIn).balanceOf(address(this));

        if (
            IERC20(_tokenIn).allowance(address(this), routerAddress) <= amountIn
        ) {
            IERC20(_tokenIn).approve(routerAddress, type(uint256).max);
        }

        dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapTokensForEth(address _token) private {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = WPLS;

        uint256 amountIn = IERC20(_token).balanceOf(address(this));

        if (
            IERC20(_token).allowance(address(this), routerAddress) <= amountIn
        ) {
            IERC20(_token).approve(routerAddress, type(uint256).max);
        }

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp
        );
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
        dexRouter = IDexRouter(routerAddress);
    }

    function updateCollector(address _collector) external onlyOwner {
        collector = _collector;
    }
}
