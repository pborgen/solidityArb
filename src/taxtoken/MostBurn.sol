// __________.__        ____ ___
// \______   \__| ____ |    |   \______
//  |    |  _/  |/ ___\|    |   /\____ \
//  |    |   \  / /_/  >    |  / |  |_> >
//  |______  /__\___  /|______/  |   __/
//          \/  /_____/           |__|

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import "./ERC20.sol";
import "../interface/IDopeDistributor.sol";
import "../interface/IDexFactory.sol";

import "./DopeDistributor.sol";

contract MostBurn is ERC20, Ownable {
    uint256 public fee = 1; // 1%
    uint256 public amountToHoldBeforeDistribute =
        100_000_000_000_000_000_000_000;
    uint256 public feeCollectedSum = 0;

    address public rewardTokenAddress;

    IDopeDistributor public distributor;

    mapping(address => bool) private _isExcludedFromFees;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event DistributorEvent(string message);

    constructor(
        string memory _name,
        string memory _ticker,
        uint256 _totalSupply,
        address _distributorAddress,
        address _rewardTokenAddress
    ) ERC20(_name, _ticker) Ownable(msg.sender) {
        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);

        _initialTransfer(msg.sender, _totalSupply);

        distributor = IDopeDistributor(_distributorAddress);
        rewardTokenAddress = _rewardTokenAddress;
    }

    receive() external payable {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (msg.sender == address(0)) {
            super._transfer(from, to, amount);
            return;
        }

        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            uint256 currentFee = (amount / 100) * fee;
            feeCollectedSum = feeCollectedSum + currentFee;

            if (currentFee > 0) {
                super._transfer(from, address(this), currentFee);
            }

            amount -= currentFee;
        }

        super._transfer(from, to, amount);

        if (feeCollectedSum >= amountToHoldBeforeDistribute) {
            super._transfer(
                address(this),
                address(distributor),
                feeCollectedSum
            );

            try
                distributor.process(address(this), rewardTokenAddress)
            {} catch {
                emit DistributorEvent("Distributor failed to process");
            }

            feeCollectedSum = 0;
        }
    }

    function setDistributor(address _distributor) public onlyOwner {
        distributor = IDopeDistributor(_distributor);
    }

    function updateAmountToHoldBeforeDistribute(
        uint256 _amount
    ) public onlyOwner {
        amountToHoldBeforeDistribute = _amount;
    }

    function cleanUpPls() public onlyOwner {
        super._transfer(address(this), msg.sender, balanceOf(address(this)));
    }

    function cleanUpToken(address _token) public onlyOwner {
        IERC20(_token).transfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }
}
