pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

contract Staking {
    using Address for address;

    // Parameters
    uint128 public constant ValidatorThreshold = 1 ether;
    uint32 public constant MinimumRequiredNumValidators = 4;

    // Properties
    address[] public _validators;
    mapping(address => bool) _addressToIsValidator;
    mapping(address => uint256) _addressToStakedAmount;
    mapping(address => uint256) _addressToValidatorIndex;
    uint256 _stakedAmount;
    uint256 _minimumStakedAmountByValidator;
    address _lowestValidator;

    // Event
    event Staked(address indexed account, uint256 amount);

    event Unstaked(address indexed account, uint256 amount);

    // modifiers
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

    constructor() {}

    // view function
    function stakedAmount() public view returns (uint256) {
        return _stakedAmount;
    }

    function minimumStakedAmountByValidator() public view returns (uint256) {
        return _minimumStakedAmountByValidator;
    }

    function validators() public view returns (address[] memory) {
        return _validators;
    }

    // public functions
    receive() external payable onlyEOA {
        _stake();
    }

    function stake() public payable onlyEOA {
        _stake();
    }

    function unstake() public onlyEOA onlyStaker {
        _unstake();
    }

    // private functions
    function _stake() private {
        _stakedAmount += msg.value;
        _addressToStakedAmount[msg.sender] += msg.value;

        if (
            !_addressToIsValidator[msg.sender] &&
            _addressToStakedAmount[msg.sender] >= ValidatorThreshold
        ) {
            // append to validator set
            _addressToIsValidator[msg.sender] = true;
            _addressToValidatorIndex[msg.sender] = _validators.length;
            _validators.push(msg.sender);
        }

        _updateMinimumStakedAmount();
        emit Staked(msg.sender, msg.value);
    }

    function _unstake() private {
        require(
            _validators.length > MinimumRequiredNumValidators,
            "Number of validators can't be less than MinimumRequiredNumValidators"
        );

        uint256 amount = _addressToStakedAmount[msg.sender];

        if (_addressToIsValidator[msg.sender]) {
            _deleteFromValidators(msg.sender);
            _updateMinimumStakedAmount();
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

    function _updateMinimumStakedAmount() private {
        if (_validators.length == 0) {
            return;
        }

        uint256 min = _addressToStakedAmount[_validators[0]];

        for (uint32 i = 1; i < _validators.length; i++) {
            if (_addressToStakedAmount[_validators[i]] < min) {
                min = _addressToStakedAmount[_validators[i]];
                _lowestValidator = _validators[i];
            }
        }
        _minimumStakedAmountByValidator = min;
    }
}
