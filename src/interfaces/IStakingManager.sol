// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStakingManager {
    function stake() external payable;
    function unstake(uint256 shares) external;
    function reportSlashing(uint256 penalty) external;
    function totalAssets() external view returns (uint256);
}
