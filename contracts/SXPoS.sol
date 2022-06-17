// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {IBlockRewards} from "./interfaces/IBlockRewards.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract SXPoS is Initializable, UUPSUpgradeable, OwnableUpgradeable,AccessControlUpgradeable {
    using AddressUpgradeable for address;

    // Parameters
    uint128 public _validatorThreshold;

    // Properties
    address[] public _validators;
    mapping(address => bool) public _addressToIsValidator;
    mapping(address => uint) public _addressToLastBlockReward;
    mapping(address => uint256) public _addressToStakedAmount;
    mapping(address => uint256) public _addressToValidatorIndex;
    uint256 public _stakedAmount;
    uint256 public _minimumNumValidators;
    uint256 public _maximumNumValidators;
    uint256 public _blockReward;
    address public _blockRewardsContract;
    uint public _epochSize;
    
    // Events
    event Staked(address indexed account, uint256 amount);

    event Unstaked(address indexed account, uint256 amount);

    // Modifiers
    modifier onlyEOA() {
        require(!msg.sender.isContract(), "Only EOA can call function");
        _;
    }

    modifier onlyStaker() {
        require(
            _addressToStakedAmount[msg.sender] > 0,
            "Only staker can call function"
        );
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Sender doesn't have admin role");
        _;
    }

    function initialize(uint256 blockReward,uint256 minNumValidators, uint256 maxNumValidators) initializer public {

        _validatorThreshold = 1 ether;
        _blockReward = blockReward;
        require(
            minNumValidators <= maxNumValidators,
            "Min validators num can not be greater than max num of validators"
        );
        _minimumNumValidators = minNumValidators;
        _maximumNumValidators = maxNumValidators;
        
        __Ownable_init();
        __UUPSUpgradeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setValidatorThreshold(uint128 validatorThreshold) external onlyAdmin {
      _validatorThreshold = validatorThreshold;
    }

    function setValidatorCounts(uint256 minNumValidators, uint256 maxNumValidators) external onlyAdmin {
        require(
            minNumValidators <= maxNumValidators,
            "Min validators num can not be greater than max num of validators"
        );
        
        //TODO: will need to drop existing validators that surpass the max validator count

        _minimumNumValidators = minNumValidators;
        _maximumNumValidators = maxNumValidators;
    }

    function setBlockReward(uint256 blockReward) external virtual onlyAdmin {
        _blockReward = blockReward;
    }

    function getBlockReward() external view returns(uint256) {
      return _blockReward;
    }

    function setEpochSize(uint epochSize) external virtual onlyAdmin {
      _epochSize = epochSize;
    }

    function getEpochSize() external view returns(uint) {
      return _epochSize;
    }

    function setBlockRewardsContract(address blockRewardsContract) public onlyAdmin {
        _blockRewardsContract = blockRewardsContract;
    }

    function stakedAmount() public view returns (uint256) {
        return _stakedAmount;
    }

    function validators() public returns (address[] memory) {
        // pay out validators once per epoch
        if (_isValidator(msg.sender) && ((block.number - _addressToLastBlockReward[msg.sender]) >= _epochSize)) {
            require(_blockRewardsContract != address(0), "BlockRewards contract address not set, unable to pay out block rewards.");
            
            uint256 amount = (_blockReward * _epochSize) / _validators.length;
            if (amount > 0) {
              _addressToLastBlockReward[msg.sender] = block.number;
              IBlockRewards blockRewards = IBlockRewards(_blockRewardsContract);
              blockRewards.payoutBlockRewards(msg.sender, amount);
            }
        }

        return _validators;
    }

    function isValidator(address addr) public view returns (bool) {
        return _addressToIsValidator[addr];
    }

    function accountStake(address addr) public view returns (uint256) {
        return _addressToStakedAmount[addr];
    }

    function minimumNumValidators() public view returns (uint256) {
        return _minimumNumValidators;
    }

    function maximumNumValidators() public view returns (uint256) {
        return _maximumNumValidators;
    }

    function getVersion() pure public virtual returns (string memory) {
      return "V1";
    }

    // Public functions
    receive() external payable onlyEOA {
        _stake();
    }

    function stake() public payable onlyEOA {
        _stake();
    }

    function unstake() public onlyEOA onlyStaker {
        _unstake();
    }

    // Private functions
    function _stake() private {
        _stakedAmount += msg.value;
        _addressToStakedAmount[msg.sender] += msg.value;

        if (_canBecomeValidator(msg.sender)) {
            _appendToValidatorSet(msg.sender);
        }

        emit Staked(msg.sender, msg.value);
    }

    function _unstake() private {
        uint256 amount = _addressToStakedAmount[msg.sender];

        _addressToStakedAmount[msg.sender] = 0;
        _stakedAmount -= amount;

        if (_isValidator(msg.sender)) {
            _deleteFromValidators(msg.sender);
        }

        payable(msg.sender).transfer(amount);
        emit Unstaked(msg.sender, amount);
    }

    function _deleteFromValidators(address staker) private {
        require(
            _validators.length > _minimumNumValidators,
            "Validators can't be less than the minimum required validator num"
        );

        require(
            _addressToValidatorIndex[staker] < _validators.length,
            "index out of range"
        );

        // index of removed address
        uint256 index = _addressToValidatorIndex[staker];
        uint256 lastIndex = _validators.length - 1;

        if (index != lastIndex) {
            // exchange between the element and last to pop for delete
            address lastAddr = _validators[lastIndex];
            _validators[index] = lastAddr;
            _addressToValidatorIndex[lastAddr] = index;
        }

        _addressToIsValidator[staker] = false;
        _addressToValidatorIndex[staker] = 0;
        delete _addressToLastBlockReward[staker];
        _validators.pop();
    }

    function _appendToValidatorSet(address newValidator) private {
        require(
            _validators.length < _maximumNumValidators,
            "Validator set has reached full capacity"
        );

        _addressToIsValidator[newValidator] = true;
        _addressToValidatorIndex[newValidator] = _validators.length;
        _addressToLastBlockReward[newValidator] = block.number;
        _validators.push(newValidator);
    }

    function _isValidator(address account) private view returns (bool) {
        return _addressToIsValidator[account];
    }

    function _canBecomeValidator(address account) private view returns (bool) {
        return
            !_isValidator(account) &&
            _addressToStakedAmount[account] >= _validatorThreshold;
    }

}
