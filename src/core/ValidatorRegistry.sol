// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IValidatorRegistry} from "../interfaces/IValidatorRegistry.sol";

/// @notice Simple, permissionless validator registry to illustrate frontrun/centralization risks.
contract ValidatorRegistry is IValidatorRegistry {
    struct Validator {
        address operator;
        bytes32 withdrawCredentials;
        uint256 balance;
        uint256 slashCount;
        bool active;
    }

    Validator[] internal validators;

    event ValidatorAdded(uint256 indexed id, address indexed operator, bytes32 withdrawCredentials);
    event WithdrawCredentialsUpdated(uint256 indexed id, bytes32 newCreds);
    event ValidatorSlashed(uint256 indexed id, uint256 amount);

    /// @dev Anyone can register a validator with arbitrary withdraw credentials.
    function registerValidator(address operator, bytes32 withdrawCredentials) external override returns (uint256) {
        validators.push(
            Validator({
                operator: operator, withdrawCredentials: withdrawCredentials, balance: 0, slashCount: 0, active: true
            })
        );
        emit ValidatorAdded(validators.length - 1, operator, withdrawCredentials);
        return validators.length - 1;
    }

    /// @dev Anyone can override withdraw credentials, demonstrating immutable cred risks when frontrun.
    function updateWithdrawCredentials(uint256 id, bytes32 newCreds) external override {
        validators[id].withdrawCredentials = newCreds;
        emit WithdrawCredentialsUpdated(id, newCreds);
    }

    function slash(uint256 id, uint256 amount) external override {
        validators[id].slashCount += 1;
        validators[id].balance = validators[id].balance > amount ? validators[id].balance - amount : 0;
        emit ValidatorSlashed(id, amount);
    }

    function setBalance(uint256 id, uint256 amount) external override {
        validators[id].balance = amount;
    }

    function validatorCount() external view override returns (uint256) {
        return validators.length;
    }

    function getValidator(uint256 id)
        external
        view
        override
        returns (address operator, bytes32 withdrawCredentials, uint256 balance, uint256 slashCount, bool active)
    {
        Validator memory v = validators[id];
        return (v.operator, v.withdrawCredentials, v.balance, v.slashCount, v.active);
    }
}
