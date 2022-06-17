// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
    @title Manages deposited native SX to be paid out as block validator rewards.
    @notice This contract is currently used by our SXPoS staking contract, which is permissioned to
    call {payoutBlockRewards()} - the function used to pay out validators SX rewards every epoch.
    @notice This contract requires periodic top ups of native tokens.
 */
contract BlockRewards is AccessControl {
    address public _stakingContractAddress;
    bool public _isEnabled;

    event Fund(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event BlockRewardsPaid(address indexed addr, uint block, uint256 amount);

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Sender must be an admin.");
        _;
    }

    modifier onlyStakingContract() {
        require(_stakingContractAddress == msg.sender, "Sender must be SXPoS staking contract.");
        _;
    }

    modifier onlyEnabled() {
        require(_isEnabled == true, "BlockRewards payouts must be enabled by an admin.");
        _;
    }

    /**
      @notice Initializes BlockRewards, assigns {msg.sender} as the admin (referenced by onlyAdmin),
      assigns {stakingContractAddress} used by onlyStakingContract modifier.
      @param stakingContractAddress Address of the SXPoS staking contract, permissioned to call payoutBlockRewards().
  */
    constructor(address stakingContractAddress) public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _stakingContractAddress = stakingContractAddress;
        _isEnabled = true;
    }

    /**
      @notice Assigns {stakingContractAddress} used by onlyStakingContract.
      @notice Only callable by admin.
      @param stakingContractAddress Address of the SXPoS staking contract, permissioned to call payoutBlockRewards().
  */
    function setStakingContractAddress(address stakingContractAddress) external onlyAdmin {
        _stakingContractAddress = stakingContractAddress;
    }

    receive() external payable {
        fund();
    }

    /**
      @notice Fund the contract with {msg.value} from {msg.sender}.
      @notice Emits {Fund} event.
  */
    function fund() public payable {
        emit Fund(msg.sender, msg.value);
    }

    /**
      @notice Withdraw {amount} from the contract.
      @notice Only callable by admin.
      @notice Emits {Withdraw} event.
  */
    function withdraw(uint256 amount) external onlyAdmin {
        require(address(this).balance >= amount, "Insufficient balance.");

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");

        emit Withdraw(msg.sender, amount);
    }

    /**
      @notice Enables block rewards payouts.
      @notice Only callable by admin.
  */
    function enable() external onlyAdmin {
      _isEnabled = true;
    }

    /**
      @notice Disables block rewards payouts.
      @notice Only callable by admin.
  */
    function disable() external onlyAdmin {
      _isEnabled = false;
    }

    /**
      @notice Sends the specified {recipient} native SX specified by {amount}.
      @notice Only callable by SXPoS staking contract.
      @notice Emits {BridgeExit} event.
  */
    function payoutBlockRewards(address recipient, uint256 amount) external onlyStakingContract onlyEnabled {
        require(address(this).balance >= amount, "Insufficient balance.");

        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Transfer failed.");

        emit BlockRewardsPaid(recipient, block.number, amount);
    }
}
