// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IValidatorRegistry {
    function registerValidator(address operator, bytes32 withdrawCredentials) external returns (uint256);
    function updateWithdrawCredentials(uint256 id, bytes32 newCreds) external;
    function slash(uint256 id, uint256 amount) external;
    function setBalance(uint256 id, uint256 amount) external;
    function validatorCount() external view returns (uint256);
    function getValidator(uint256 id)
        external
        view
        returns (address operator, bytes32 withdrawCredentials, uint256 balance, uint256 slashCount, bool active);
}
