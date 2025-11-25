// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LSToken} from "./LSToken.sol";
import {ValidatorRegistry} from "./ValidatorRegistry.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {SimpleOracle} from "../oracle/SimpleOracle.sol";
import {RewardDistributor} from "../rewards/RewardDistributor.sol";

/// @notice Deliberately vulnerable liquid staking primitive for research/CTF use only.
/// Checklist coverage:
/// - Reentrancy on withdraw and reward claim.
/// - Unbounded loops over validators (DoS).
/// - Open oracle manipulation and inflationary minting.
/// - Slashing depegs supply vs backing.
/// - Centralized owner-only controls (no multisig).
/// - Withdraw credentials can be frontrun (via registry).
contract StakingManager {
    LSToken public immutable token;
    ValidatorRegistry public immutable registry;
    IOracle public oracle;
    RewardDistributor public immutable rewards;

    address public owner;
    address public depositContract;
    uint256 public totalStaked;

    event Deposit(address indexed user, uint256 amount, uint256 shares);
    event Withdraw(address indexed user, uint256 shares, uint256 amount);
    event OracleUpdated(address newOracle);
    event DepositContractUpdated(address newDeposit);
    event Slashed(uint256 indexed validatorId, uint256 amount);
    event InflationMint(address indexed to, uint256 shares);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        token = new LSToken("Kimchi Liquid Staked ETH", "kimLST");
        registry = new ValidatorRegistry();
        oracle = new SimpleOracle();
        rewards = new RewardDistributor(address(this));
    }

    receive() external payable {
        deposit();
    }

    /// @notice Permissionless validator add; withdraw credentials can be overwritten.
    function registerValidator(address operator, bytes32 withdrawCredentials) external {
        registry.registerValidator(operator, withdrawCredentials);
    }

    /// @notice Anyone can set oracle by pointing to any contract implementing IOracle.
    function setOracle(address newOracle) external onlyOwner {
        oracle = IOracle(newOracle);
        emit OracleUpdated(newOracle);
    }

    /// @notice Owner can set deposit contract; no multi-sig.
    function setDepositContract(address newDeposit) external onlyOwner {
        depositContract = newDeposit;
        emit DepositContractUpdated(newDeposit);
    }

    /// @notice Owner can mint unbacked shares, causing instant depeg.
    function mintWithoutBacking(address to, uint256 shares) external onlyOwner {
        token.mint(to, shares);
        emit InflationMint(to, shares);
    }

    /// @notice Anyone can manipulate price before calling this to mint cheap/expensive shares.
    function deposit() public payable {
        require(msg.value > 0, "no value");

        _touchValidators(msg.value);
        uint256 rate = oracle.getRate();
        uint256 shares = (msg.value * rate) / 1e18;
        totalStaked += msg.value;

        // Ship 1% to rewards pool but still count full amount as staked => accounting mismatch.
        uint256 rewardCut = msg.value / 100;
        if (rewardCut > 0) {
            (bool funded,) = payable(address(rewards)).call{value: rewardCut}("");
            require(funded, "fund rewards failed");
            rewards.accrue(msg.sender, rewardCut);
        }

        token.mint(msg.sender, shares);
        emit Deposit(msg.sender, msg.value, shares);
    }

    /// @dev Vulnerable: external call before burning shares allows reentrancy to drain funds.
    function withdraw(uint256 shares) external {
        require(shares > 0, "zero");
        require(token.balanceOf(msg.sender) >= shares, "balance");

        uint256 rate = oracle.getRate();
        uint256 amount = (shares * 1e18) / (rate == 0 ? 1 : rate);

        (bool ok,) = payable(msg.sender).call{value: amount}("");
        require(ok, "transfer failed");

        // If reentered and already burned, this is skipped.
        if (token.balanceOf(msg.sender) >= shares) {
            token.burn(msg.sender, shares);
        }
        if (totalStaked >= amount) {
            totalStaked -= amount;
        }

        emit Withdraw(msg.sender, shares, amount);
    }

    /// @notice Owner-triggered slashing reduces ETH backing but keeps share supply intact (depeg).
    function slashValidator(uint256 validatorId, uint256 amount) external onlyOwner {
        registry.slash(validatorId, amount);
        if (totalStaked >= amount) {
            totalStaked -= amount;
        }
        emit Slashed(validatorId, amount);
    }

    /// @notice Batch deposit to external beacon contract; iterations can be set arbitrarily (DoS).
    function pushToBeacon(uint256 iterations) external {
        require(depositContract != address(0), "no deposit");
        uint256 each = address(this).balance / (iterations == 0 ? 1 : iterations);
        for (uint256 i; i < iterations; i++) {
            (bool ok,) = depositContract.call{value: each}("");
            require(ok, "beacon deposit failed");
        }
    }

    /// @dev Vulnerable reward claim path (in RewardDistributor) called directly by users.
    function claimRewards() external {
        rewards.claim();
    }

    // ---- internal helpers ----

    function _touchValidators(uint256 amount) internal {
        // Unbounded storage writes; can be forced to exceed realistic gas limits.
        uint256 len = registry.validatorCount();
        for (uint256 i = 0; i < len; i++) {
            (, bytes32 cred, uint256 bal,, bool active) = registry.getValidator(i);
            if (active) {
                // meaningless math; demonstrates state changes in a loop
                uint256 newBalance = bal + amount / (len == 0 ? 1 : len);
                registry.setBalance(i, newBalance);
                // allow overwriting withdrawCredentials to show impact, even in deposit
                registry.updateWithdrawCredentials(i, cred);
            }
        }
    }
}
