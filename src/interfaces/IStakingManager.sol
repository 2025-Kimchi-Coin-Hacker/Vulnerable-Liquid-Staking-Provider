// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStakingManager {
    function deposit() external payable;
    function withdraw(uint256 shares) external;
    function slashValidator(uint256 id, uint256 amount) external;
}
