// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRewardDistributor {
    function distributeRewards() external payable;
    function claimRewards() external;
    function pendingRewards(address user) external view returns (uint256);
}
