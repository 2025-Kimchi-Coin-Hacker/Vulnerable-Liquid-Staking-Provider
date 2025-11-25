// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal centralized access control (no multisig) to highlight governance centralization risk.
contract AccessManager {
    address public owner;
    mapping(address => bool) public operators;

    event OwnerChanged(address indexed newOwner);
    event OperatorSet(address indexed operator, bool allowed);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }

    function setOperator(address op, bool allowed) external onlyOwner {
        operators[op] = allowed;
        emit OperatorSet(op, allowed);
    }

    function isOperator(address op) external view returns (bool) {
        return operators[op];
    }
}
