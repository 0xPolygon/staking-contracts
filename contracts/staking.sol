pragma solidity ^0.8.7;

contract Staking {
    // Parameters
    uint128 public constant ValidatorThreshold = 1 ether;

    // Properties
    address[] public _validators;
    mapping(address => bool) _addressToIsValidator;
    mapping(address => uint256) _addressToStakedAmount;
    mapping(address => uint256) _addressToValidatorIndex;
    uint256 _stakedAmount;

    // Event
    event Staked(address indexed account, uint256 amount);

    event Unstaked(address indexed account, uint256 amount);

    // modifiers
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

    function validators() public view returns (address[] memory) {
        return _validators;
    }

    // public function
    receive() external payable {
        _stake(msg.value);
    }

    function stake() public payable {
        _stake(msg.value);
    }

    function unstake() public onlyStaker {
        _unstake();
    }

    function _stake(uint256 amount) private {
        _stakedAmount += amount;
        _addressToStakedAmount[msg.sender] += amount;

        if (
            !_addressToIsValidator[msg.sender] &&
            _addressToStakedAmount[msg.sender] >= ValidatorThreshold
        ) {
            // append to validator set
            _addressToIsValidator[msg.sender] = true;
            _addressToValidatorIndex[msg.sender] = _validators.length;
            _validators.push(msg.sender);
        }

        emit Staked(msg.sender, amount);
    }

    function _unstake() private {
        uint256 amount = _addressToStakedAmount[msg.sender];

        _addressToStakedAmount[msg.sender] = 0;
        if (_addressToIsValidator[msg.sender]) {
            _deleteFromValidators(msg.sender);
        }

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
}
