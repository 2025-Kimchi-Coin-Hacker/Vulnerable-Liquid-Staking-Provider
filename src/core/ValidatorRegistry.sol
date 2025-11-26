// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessManager} from "./access/AccessManager.sol";

contract ValidatorRegistry {
    struct Validator {
        address operator;
        bytes pubkey;
        bool isActive;
        uint256 totalStake;
    }

    Validator[] public validators;
    AccessManager public accessManager;

    event ValidatorAdded(address indexed operator, bytes pubkey);
    event ValidatorUpdated(uint256 indexed index, bool isActive);

    constructor(address _accessManager) {
        accessManager = AccessManager(_accessManager);
    }
    
    function addValidator(address _operator, bytes calldata _pubkey) external {
        validators.push(Validator({
            operator: _operator,
            pubkey: _pubkey,
            isActive: true,
            totalStake: 0
        }));
        emit ValidatorAdded(_operator, _pubkey);
    }

    function getValidatorCount() external view returns (uint256) {
        return validators.length;
    }
    
    function distributeStakeToValidators(uint256 totalAmount) external {

        uint256 count = validators.length;
        if (count == 0) return;

        uint256 amountPerValidator = totalAmount / count;

        for (uint256 i = 0; i < count; i++) {
            if (validators[i].isActive) {
                validators[i].totalStake += amountPerValidator;
            }
        }
    }
}
