// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interface/IDividendDistributor.sol";
import "../interface/IDexRouter.sol";
import "../interface/IDexFactory.sol";
import "../interface/ILpPair.sol";
import "./DividendDistributor.sol";
import "./ERC20.sol";

contract REWARDr is ERC20, Ownable {
    IDexRouter public immutable dexRouter;
    address public lpPair;

    mapping(address => uint256) public walletProtection;
    bool public protectionDisabled = false;

    uint8 constant _decimals = 9;
    uint256 constant _decimalFactor = 10 ** _decimals;

    bool private swapping;
    uint256 public swapTokensAtAmount;
    uint256 public maxSwapTokens;

    IDividendDistributor public distributor;

    address public taxCollector;
    uint256 public taxSplit = 100;
    bool public autoProcess = true;

    bool public swapEnabled = true;

    uint256 public tradingActiveTime;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public isDividendExempt;
    mapping(address => bool) public pairs;

    event SetPair(address indexed pair, bool indexed value);
    event ExcludeFromFees(address indexed account, bool isExcluded);

    constructor(
        string memory name,
        string memory ticker,
        uint256 supply,
        address reward
    ) ERC20(name, ticker) Ownable(msg.sender) {
        address routerAddress = 0x165C3410fC91EF562C50559f7d2289fEbed552d9;
        dexRouter = IDexRouter(routerAddress);

        _approve(msg.sender, routerAddress, type(uint256).max);
        _approve(address(this), routerAddress, type(uint256).max);

        uint256 totalSupply = supply * _decimalFactor;

        swapTokensAtAmount = (totalSupply * 1) / 1000000;
        maxSwapTokens = (totalSupply * 5) / 1000;

        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);

        isDividendExempt[routerAddress] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(0xdead)] = true;

        _initialTransfer(msg.sender, totalSupply);

        DividendDistributor dist = new DividendDistributor(reward);
        setDistributor(address(dist), false);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function updateSwapTokens(
        uint256 atAmount,
        uint256 maxAmount
    ) external onlyOwner {
        require(
            maxAmount <= (totalSupply() * 1) / 100,
            "Max swap cannot be higher than 1% supply."
        );
        swapTokensAtAmount = atAmount;
        maxSwapTokens = maxAmount;
    }

    function setTaxCollector(address wallet) external onlyOwner {
        taxCollector = wallet;
    }

    function toggleSwap() external onlyOwner {
        swapEnabled = !swapEnabled;
    }

    function toggleProcess() external onlyOwner {
        autoProcess = !autoProcess;
    }

    function setPair(address pair, bool value) external {
        require(pair != lpPair, "The pair cannot be removed from pairs");
        require(
            msg.sender == owner() || msg.sender == taxCollector,
            "Unauthorised"
        );

        pairs[pair] = value;
        setDividendExempt(pair, true);
        emit SetPair(pair, value);
    }

    function getFees() public pure returns (uint256) {
        return 1;
    }

    function setSplit(uint256 _split) external onlyOwner {
        require(_split <= 100);
        taxSplit = _split;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setDividendExempt(address holder, bool exempt) public onlyOwner {
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0, true);
        } else {
            distributor.setShare(holder, balanceOf(holder), false);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (tradingActiveTime == 0) {
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to],
                "Trading not yet active"
            );
            super._transfer(from, to, amount);
        } else {
            if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
                uint256 fees = 0;
                uint256 _f = getFees();

                fees = (amount * _f) / 100;

                if (fees > 0) {
                    super._transfer(from, address(this), fees);
                }

                if (swapEnabled && !swapping && pairs[to]) {
                    swapping = true;
                    swapBack(amount);
                    swapping = false;
                }

                amount -= fees;
            }

            super._transfer(from, to, amount);

            if (autoProcess) {
                try distributor.process() {} catch {}
            }
        }

        _beforeTokenTransfer(from, to);

        if (!isDividendExempt[from]) {
            try distributor.setShare(from, balanceOf(from), false) {} catch {}
        }
        if (!isDividendExempt[to]) {
            try distributor.setShare(to, balanceOf(to), false) {} catch {}
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WPLS();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack(uint256 amount) private {
        uint256 amountToSwap = balanceOf(address(this));

        if (amountToSwap < swapTokensAtAmount) return;
        if (amountToSwap > maxSwapTokens) amountToSwap = maxSwapTokens;
        if (amountToSwap > amount) amountToSwap = amount;
        if (amountToSwap == 0) return;

        uint256 ethBalance = address(this).balance;

        swapTokensForEth(amountToSwap);

        uint256 generated = address(this).balance - ethBalance;

        if (generated > 0) {
            uint256 _split = (taxSplit * generated) / 100;
            if (_split > 0) try distributor.deposit{value: _split}() {} catch {}
            if (generated > _split) {
                bool success;
                (success, ) = taxCollector.call{value: address(this).balance}(
                    ""
                );
            }
        }
    }

    function withdrawTax() external {
        require(
            msg.sender == owner() || msg.sender == taxCollector,
            "Unauthorised"
        );
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }

    function addLP(
        uint256 nativeTokens,
        address pairedWith
    ) external payable onlyOwner {
        require(nativeTokens > 0, "No LP tokens specified");
        address ETH = dexRouter.WPLS();

        lpPair = IDexFactory(dexRouter.factory()).createPair(
            pairedWith,
            address(this)
        );
        pairs[lpPair] = true;
        isDividendExempt[lpPair] = true;

        super._transfer(
            msg.sender,
            address(this),
            nativeTokens * _decimalFactor
        );

        if (pairedWith == ETH) {
            dexRouter.addLiquidityETH{value: msg.value}(
                address(this),
                balanceOf(address(this)),
                0,
                0,
                msg.sender,
                block.timestamp
            );
        } else {
            IERC20Metadata tok = IERC20Metadata(pairedWith);
            //tok.transferFrom(msg.sender, address(this), pairedTokens * (10**tok.decimals()));
            dexRouter.addLiquidity(
                address(this),
                pairedWith,
                balanceOf(address(this)),
                tok.balanceOf(address(this)),
                0,
                0,
                msg.sender,
                block.timestamp
            );
        }
    }

    function launch() external onlyOwner {
        require(tradingActiveTime == 0);
        tradingActiveTime = block.number;
    }

    function setDistributor(
        address _distributor,
        bool migrate
    ) public onlyOwner {
        if (migrate) distributor.migrate(_distributor);

        distributor = IDividendDistributor(_distributor);
        distributor.initialize();
    }

    function claimDistributor(address _distributor) external onlyOwner {
        Ownable(_distributor).transferOwnership(msg.sender);
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution,
        uint256 _claimAfter
    ) external onlyOwner {
        distributor.setDistributionCriteria(
            _minPeriod,
            _minDistribution,
            _claimAfter
        );
    }

    function manualDeposit() external payable {
        distributor.deposit{value: msg.value}();
    }

    function getPoolStatistics()
        external
        view
        returns (
            uint256 totalRewards,
            uint256 totalRewardsPaid,
            uint256 rewardHolders
        )
    {
        totalRewards = distributor.getTotalDividends();
        totalRewardsPaid = distributor.getTotalDistributed();
        rewardHolders = distributor.countShareholders();
    }

    function myStatistics(
        address wallet
    ) external view returns (uint256 reward, uint256 rewardClaimed) {
        reward = distributor.getUnpaidEarnings(wallet);
        rewardClaimed = distributor.getPaidDividends(wallet);
    }

    function checkClaimTime(address wallet) external view returns (uint256) {
        return distributor.getClaimTime(wallet);
    }

    function claim() external {
        distributor.claimDividend(msg.sender);
    }

    function airdropToWallets(
        address[] memory wallets,
        uint256[] memory amountsInTokens,
        bool dividends
    ) external onlyOwner {
        require(
            wallets.length == amountsInTokens.length,
            "Arrays must be the same length"
        );

        for (uint256 i = 0; i < wallets.length; i++) {
            super._transfer(
                msg.sender,
                wallets[i],
                amountsInTokens[i] * _decimalFactor
            );
            if (dividends)
                distributor.setShare(
                    wallets[i],
                    amountsInTokens[i] * _decimalFactor,
                    false
                );
        }
    }

    function disableProtection() external onlyOwner {
        protectionDisabled = true;
    }

    function transferProtection(
        address[] calldata _wallets,
        uint256 _enabled
    ) external onlyOwner {
        if (_enabled > 0) require(!protectionDisabled, "Disabled");
        for (uint256 i = 0; i < _wallets.length; i++) {
            walletProtection[_wallets[i]] = _enabled;
        }
    }

    function _beforeTokenTransfer(address from, address to) internal view {
        require(
            walletProtection[from] == 0 || to == owner(),
            "Wallet protection enabled, please contact support"
        );
    }
}
