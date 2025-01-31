// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IDopeDistributor {
    function process(address _token, address _tokenAddressToBuy) external;
}
