// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LSToken} from "./LSToken.sol";

/// @notice Deliberately vulnerable liquid staking primitive for research/CTF use only.
/// - Contains a reentrancy-unsafe withdraw flow.
/// - Uses unbounded validator loops that can be abused for gas griefing/DoS.
contract StakingManager {
    LSToken public immutable token;
    address public immutable owner;
    uint256 public totalStaked;
    address public depositContract;
    uint256 public oracleRate = 1e18; // manipulable price: 1e18 = 1:1

    struct Validator {
        address operator;
        bytes32 withdrawCredentials;
        uint256 virtualBalance; // pseudo-accounting only
        uint64 score;
        uint256 collateral;
        uint256 slashCount;
        bool active;
    }

    Validator[] public validators;
    mapping(address => uint256) public rewardOf; // rewards owed to users (vulnerable claim)

    event PendingDepositPushed(address depositContract, uint256 amount);
    event OracleRateUpdated(uint256 newRate);

    constructor() {
        owner = msg.sender;
        token = new LSToken("Kimchi Liquid Staked ETH", "kimLST");
    }

    receive() external payable {
        deposit();
    }

    /// @notice Anyone can spam validators; the loop in deposit/withdrawal accounting
    /// will iterate over all of them and can be forced to run out of gas. No checks
    /// on withdraw credentials create frontrun/ownership risks.
    function registerValidator(address operator, bytes32 withdrawCredentials) external {
        validators.push(
            Validator({
                operator: operator,
                withdrawCredentials: withdrawCredentials,
                virtualBalance: 0,
                score: 1,
                collateral: 0,
                slashCount: 0,
                active: true
            })
        );
    }

    /// @notice Single-signer control; no multisig.
    function setDepositContract(address _depositContract) external {
        require(msg.sender == owner, "not owner");
        depositContract = _depositContract;
    }

    /// @notice Open oracle updater: allows sandwich/manipulation of price before deposits.
    function updateOracleRate(uint256 newRate) external {
        oracleRate = newRate;
        emit OracleRateUpdated(newRate);
    }

    /// @notice Owner can mint unbacked shares (inflation attack / depeg).
    function mintWithoutBacking(address to, uint256 shares) external {
        require(msg.sender == owner, "not owner");
        token.mint(to, shares);
    }

    function deposit() public payable {
        require(msg.value > 0, "no value");
        _touchValidators(msg.value);
        totalStaked += msg.value;
        // manipulable oracleRate sets share price, enabling sandwich oracles and depegs.
        uint256 shares = (msg.value * oracleRate) / 1e18;
        token.mint(msg.sender, shares);
        rewardOf[msg.sender] += msg.value / 100; // naive reward accrual (1%)
    }

    /// @dev Vulnerable: external call before burning shares allows reentrancy to drain funds.
    /// Additionally, sloppy post-call checks make it easy to skip burning after reentrancy.
    function withdraw(uint256 amount) external {
        require(amount > 0, "zero");
        require(token.balanceOf(msg.sender) >= amount, "balance");

        uint256 owed = amount;
        (bool ok,) = payable(msg.sender).call{value: owed}("");
        require(ok, "transfer failed");

        // If the user reentered and already burned, this silently skips burn + leaves stale supply.
        if (token.balanceOf(msg.sender) >= amount) {
            token.burn(msg.sender, amount);
        }
        if (totalStaked >= owed) {
            totalStaked -= owed;
        }
    }

    function validatorCount() external view returns (uint256) {
        return validators.length;
    }

    /// @notice Owner-triggered slashing reduces ETH backing but does not reprice shares -> depeg.
    function slashValidator(uint256 validatorId, uint256 amount) external {
        require(msg.sender == owner, "not owner");
        Validator storage val = validators[validatorId];
        val.collateral += amount;
        val.slashCount += 1;
        if (totalStaked >= amount) {
            totalStaked -= amount;
        }
    }

    /// @notice Batch deposit to beacon deposit contract with arbitrary iterations -> gas heavy.
    function pushToBeacon(uint256 iterations) external {
        require(depositContract != address(0), "no deposit");
        uint256 each = address(this).balance / (iterations == 0 ? 1 : iterations);
        for (uint256 i; i < iterations; i++) {
            // Dummy payload; relies on external depositContract implementation.
            (bool ok,) = depositContract.call{value: each}("");
            require(ok, "beacon deposit failed");
            emit PendingDepositPushed(depositContract, each);
        }
    }

    /// @dev Vulnerable reward claim: external call before state clear enables reentrancy reward loops.
    function claimRewards() external {
        uint256 amount = rewardOf[msg.sender];
        require(amount > 0, "no rewards");
        (bool ok,) = payable(msg.sender).call{value: amount}("");
        require(ok, "reward send failed");
        rewardOf[msg.sender] = 0;
    }

    // ---- internal helpers ----

    function _touchValidators(uint256 amount) internal {
        // Unbounded storage writes; can be forced to exceed realistic gas limits.
        uint256 len = validators.length;
        for (uint256 i = 0; i < len; i++) {
            validators[i].virtualBalance += amount / (len == 0 ? 1 : len);
            validators[i].score += 1;
        }
    }
}
