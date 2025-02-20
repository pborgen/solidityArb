// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDividendDistributor {
    function initialize() external;
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution,
        uint256 _claimAfter
    ) external;
    function setShare(
        address shareholder,
        uint256 amount,
        bool exclude
    ) external;
    function deposit() external payable;
    function claimDividend(address shareholder) external;
    function getUnpaidEarnings(
        address shareholder
    ) external view returns (uint256);
    function getPaidDividends(
        address shareholder
    ) external view returns (uint256);
    function getTotalPaid() external view returns (uint256);
    function getClaimTime(address shareholder) external view returns (uint256);
    function getTotalDividends() external view returns (uint256);
    function getTotalDistributed() external view returns (uint256);
    function countShareholders() external view returns (uint256);
    function migrate(address newDistributor) external;
    function process() external;
}
