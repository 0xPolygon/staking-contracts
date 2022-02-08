pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

contract Staking {
    using Address for address;

    // Parameters
    uint128 public constant ValidatorThreshold = 1 ether;

    // Properties
    address[] public _validators;
    mapping(address => bool) _addressToIsValidator;
    mapping(address => uint256) _addressToStakedAmount;
    mapping(address => uint256) _addressToValidatorIndex;
    uint256 _stakedAmount;
    uint32 _maximumNumValidators;
    uint32 _minimumNumValidators;

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

    constructor(uint32 minNumValidators, uint32 maxNumValidators) {
        _maximumNumValidators = maxNumValidators;
        _minimumNumValidators = minNumValidators;
    }

    // View functions
    function stakedAmount() public view returns (uint256) {
        return _stakedAmount;
    }

    function validators() public view returns (address[] memory) {
        return _validators;
    }

    function isValidator(address addr) public view returns (bool) {
        return _addressToIsValidator[addr];
    }

    function accountStake(address addr) public view returns (uint256) {
        return _addressToStakedAmount[addr];
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
        require(
            _validators.length < _maximumNumValidators,
            "Validator set has reached full capacity"
        );
        _stakedAmount += msg.value;
        _addressToStakedAmount[msg.sender] += msg.value;

        if (
            !_addressToIsValidator[msg.sender] &&
            _addressToStakedAmount[msg.sender] >= ValidatorThreshold
        ) {
            _appendToValidatorSet(msg.sender);
        }

        emit Staked(msg.sender, msg.value);
    }

    function _unstake() private {
        require(
            _validators.length > _minimumNumValidators,
            "Number of validators can't be less than MinimumRequiredNumValidators"
        );

        uint256 amount = _addressToStakedAmount[msg.sender];

        if (_addressToIsValidator[msg.sender]) {
            _deleteFromValidators(msg.sender);
        }

        _addressToStakedAmount[msg.sender] = 0;
        _stakedAmount -= amount;
        payable(msg.sender).transfer(amount);
        emit Unstaked(msg.sender, amount);
    }

    function _deleteFromValidators(address staker) private {
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
        _validators.pop();
    }

    function _appendToValidatorSet(address newValidator) private {
        _addressToIsValidator[newValidator] = true;
        _addressToValidatorIndex[newValidator] = _validators.length;
        _validators.push(newValidator);
    }
}
