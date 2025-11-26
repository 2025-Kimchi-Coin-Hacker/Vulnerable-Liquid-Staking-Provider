// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IValidatorRegistry {
    function addValidator(address operator, bytes calldata pubkey, bytes calldata withdrawalCreds) external;
    function distributeStake() external; 
    function getValidatorCount() external view returns (uint256);
}
