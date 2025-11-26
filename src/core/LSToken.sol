// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessManager} from "../access/AccessManager.sol";

contract LSToken is ERC20 {
    AccessManager public accessManager;

    error LSToken__Unauthorized(bytes32 role, address account);

    modifier onlyRole(bytes32 role) {
        if (!accessManager.hasRole(role, msg.sender)) {
            revert LSToken__Unauthorized(role, msg.sender);
        }
        _;
    }

    constructor(address _accessManager) ERC20("Liquid Staked Token", "LST") {
        accessManager = AccessManager(_accessManager);
    }

    function mint(address to, uint256 amount) external onlyRole(accessManager.MINTER_ROLE()) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(accessManager.BURNER_ROLE()) {
        _burn(from, amount);
    }
}

