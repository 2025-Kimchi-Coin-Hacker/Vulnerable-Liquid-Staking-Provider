// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRewardDistributor {
    function accrue(address user, uint256 amount) external;
    function claim() external;
    function pending(address user) external view returns (uint256);
}
