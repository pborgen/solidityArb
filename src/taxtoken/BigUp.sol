// __________.__        ____ ___
// \______   \__| ____ |    |   \______
//  |    |  _/  |/ ___\|    |   /\____ \
//  |    |   \  / /_/  >    |  / |  |_> >
//  |______  /__\___  /|______/  |   __/
//          \/  /_____/           |__|

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import "./ERC20.sol";
import "../interface/IDopeDistributor.sol";
import "../interface/IDexFactory.sol";

import "./DopeDistributor.sol";

contract BigUp is ERC20, Ownable {
    uint256 public feeBasisPoints = 100; // 1%
    uint256 public amountToHoldBeforeDistribute = 100_000_000_000_000_000_000;
    uint256 public gatheredFees = 0;

    address public rewardTokenAddress;

    IDopeDistributor public distributor;

    mapping(address => bool) private _isExcludedFromFees;

    event ExcludeFromFees(address indexed account, bool isExcluded);

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

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fee = 0;

        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            fee = (amount * feeBasisPoints) / 10000;
            gatheredFees = gatheredFees + fee;

            amount = amount - fee;
        }

        super._transfer(from, to, amount);

        if (gatheredFees >= amountToHoldBeforeDistribute) {
            super._transfer(address(this), address(distributor), gatheredFees);

            try
                distributor.process(address(this), rewardTokenAddress)
            {} catch {}

            gatheredFees = 0;
        }
    }

    function setDistributor(address _distributor) public onlyOwner {
        distributor = IDopeDistributor(_distributor);
    }

    function updateAmountToHoldBeforeDistribute(
        uint256 _amount
    ) public onlyOwner {
        require(_amount <= 500, "Amount must be at most 5%");
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
}
