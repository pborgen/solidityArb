// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "../interface/IDividendDistributor.sol";
import "../interface/IDexRouter.sol";


contract DividendDistributor is IDividendDistributor, Ownable {
    address public _token;
    IERC20 public immutable reward;
    address public immutable ETH;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] public shareholders;
    mapping(address => uint256) public shareholderIndexes;

    mapping(address => uint256) public shareholderClaims;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public unclaimed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 30 seconds;
    uint256 public minDistribution = 1;
    uint256 public gas = 800000;
    uint256 public currentIndex;

    address constant routerAddress = 0x165C3410fC91EF562C50559f7d2289fEbed552d9;
    IDexRouter constant dexRouter = IDexRouter(routerAddress);
    uint256 public slippage = 98;

    bool public initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    function getTotalDividends() external view override returns (uint256) {
        return totalDividends;
    }
    function getTotalDistributed() external view override returns (uint256) {
        return totalDistributed;
    }

    constructor(address rwd) Ownable(msg.sender) {
        reward = IERC20(rwd);
        aprv();
        ETH = dexRouter.WPLS();
    }

    function aprv() public {
        reward.approve(routerAddress, type(uint256).max);
    }

    function initialize() external override initialization {
        _token = msg.sender;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution,
        uint256 _gas
    ) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        gas = _gas;
    }

    function setShare(
        address shareholder,
        uint256 amount,
        bool exclude
    ) external override onlyToken {
        uint256 currentShare = shares[shareholder].amount;
        if (amount > 0 && currentShare == 0) {
            addShareholder(shareholder);
            shares[shareholder].totalExcluded = getCumulativeDividends(amount);
            shareholderClaims[shareholder] = block.timestamp;
        } else if (amount == 0 && currentShare > 0) {
            removeShareholder(shareholder);
        }

        uint256 unpaid = getUnpaidEarnings(shareholder);
        if (currentShare > 0 && !exclude) {
            if (unpaid > 0) {
                if (shouldDistribute(shareholder, unpaid)) {
                    distributeDividend(shareholder, unpaid);
                } else {
                    unclaimed += unpaid;
                }
            }
        }

        totalShares = (totalShares - currentShare) + amount;

        shares[shareholder].amount = amount;

        shares[shareholder].totalExcluded = getCumulativeDividends(amount);
    }

    function deposit() external payable override {
        uint256 amount;
        if (address(reward) != ETH) {
            address[] memory path = new address[](2);
            path[0] = dexRouter.WPLS();
            path[1] = address(reward);

            uint256 spend = address(this).balance;
            uint256[] memory amountsout = dexRouter.getAmountsOut(spend, path);

            uint256 curBal = reward.balanceOf(address(this));

            dexRouter.swapExactETHForTokens{value: spend}(
                (amountsout[1] * slippage) / 100,
                path,
                address(this),
                block.timestamp
            );

            amount = reward.balanceOf(address(this)) - curBal;
        } else {
            amount = msg.value;
        }

        totalDividends += amount;
        
        if (totalShares > 0)
            if (dividendsPerShare == 0)
                dividendsPerShare =
                    (dividendsPerShareAccuracyFactor * totalDividends) /
                    totalShares;
            else
                dividendsPerShare += ((dividendsPerShareAccuracyFactor *
                    amount) / totalShares);
    }

    function extractUnclaimed() external onlyOwner {
        uint256 uncl = unclaimed;
        unclaimed = 0;
        reward.transfer(msg.sender, uncl);
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

    function migrate(address newDistributor) external onlyToken {
        DividendDistributor newD = DividendDistributor(newDistributor);
        require(!newD.initialized(), "Already initialized");
        bool success;
        (success, ) = newDistributor.call{value: address(this).balance}("");
        reward.transfer(newDistributor, reward.balanceOf(address(this)));
        require(success, "Transfer failed");
    }

    function shouldDistribute(
        address shareholder,
        uint256 unpaidEarnings
    ) internal view returns (bool) {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            unpaidEarnings > minDistribution;
    }

    function getClaimTime(
        address shareholder
    ) external view override onlyToken returns (uint256) {
        uint256 scp = shareholderClaims[shareholder] + minPeriod;
        if (scp <= block.timestamp) {
            return 0;
        } else {
            return scp - block.timestamp;
        }
    }

    function distributeDividend(
        address shareholder,
        uint256 unpaidEarnings
    ) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        if (unpaidEarnings > 0) {
            totalDistributed = totalDistributed + unpaidEarnings;
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised += unpaidEarnings;
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
            if (address(reward) == ETH) {
                bool success;
                (success, ) = shareholder.call{value: unpaidEarnings}("");
            } else reward.transfer(shareholder, unpaidEarnings);
        }
    }

    function process() public override {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            uint256 unpaid = getUnpaidEarnings(shareholders[currentIndex]);
            if (shouldDistribute(shareholders[currentIndex], unpaid)) {
                distributeDividend(shareholders[currentIndex], unpaid);
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function claimDividend(address shareholder) external override onlyToken {
        uint256 unpaid = getUnpaidEarnings(shareholder);
        require(
            shouldDistribute(shareholder, unpaid),
            "Dividends not available yet"
        );
        distributeDividend(shareholder, unpaid);
    }

    function processClaim(address shareholder) external onlyOwner {
        uint256 unpaid = getUnpaidEarnings(shareholder);
        require(
            shouldDistribute(shareholder, unpaid),
            "Dividends not available yet"
        );
        distributeDividend(shareholder, unpaid);
    }

    function getUnpaidEarnings(
        address shareholder
    ) public view override returns (uint256) {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getPaidDividends(
        address shareholder
    ) external view override onlyToken returns (uint256) {
        return shares[shareholder].totalRealised;
    }

    function getTotalPaid() external view override onlyToken returns (uint256) {
        return totalDistributed;
    }

    function getCumulativeDividends(
        uint256 share
    ) internal view returns (uint256) {
        if (share == 0) {
            return 0;
        }
        return (share * dividendsPerShare) / dividendsPerShareAccuracyFactor;
    }

    function countShareholders() public view returns (uint256) {
        return shareholders.length;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}
