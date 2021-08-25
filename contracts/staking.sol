pragma solidity ^0.8.7;

import "hardhat/console.sol";

contract Staking {
    // Parameters
    uint128 public constant ValidatorThreshold = 1 ether;

    // Type
    struct Staker {
        bool isValidator;
        address addr;
        uint256 amount;
        uint256 index;
    }

    // Properties
    address[] public _validators;
    mapping(address => Staker) public _stakers;
    uint256 public _stakedAmount = 0;

    // Event
    event Staked(address indexed account, uint256 amount);

    event Unstaked(address indexed account, uint256 amount);

    // modifiers
    modifier onlyStaker() {
        Staker memory staker = _stakers[msg.sender];
        require(
            staker.addr != address(0) && staker.amount > 0,
            "Only staker can call function"
        );
        _;
    }

    constructor() {}

    // fallback
    // receive() external payable {}

    // view function
    function stakedAmount() public view returns (uint256) {
        return _stakedAmount;
    }

    function validators() public view returns (address[] memory) {
        return _validators;
    }

    // public function
    function stake() public payable {
        _stakedAmount += msg.value;

        Staker storage staker = _stakers[msg.sender];
        if (staker.addr == address(0)) {
            staker.addr = msg.sender;
            staker.amount = 0;
        }
        staker.amount += msg.value;

        if (!staker.isValidator && staker.amount >= ValidatorThreshold) {
            _validators.push(msg.sender);
            staker.isValidator = true;
            staker.index = _validators.length - 1;
        }

        emit Staked(msg.sender, msg.value);
    }

    function unstake() public onlyStaker {
        Staker storage staker = _stakers[msg.sender];
        uint256 amount = staker.amount;

        staker.amount = 0;
        if (staker.isValidator) {
            staker.isValidator = false;
            deleteFromValidators(staker);
        }

        _stakedAmount -= amount;
        payable(msg.sender).transfer(amount);
        emit Unstaked(msg.sender, amount);
    }

    function deleteFromValidators(Staker memory staker) private {
        require(
            staker.index < _validators.length &&
                _validators[staker.index] == staker.addr,
            "index out of range"
        );
        // index of removed address
        uint256 index = staker.index;
        uint256 lastIndex = _validators.length - 1;

        if (index != lastIndex) {
            // exchange between the element and last to pop for delete
            address lastAddr = _validators[lastIndex];
            Staker storage lastStaker = _stakers[lastAddr];

            require(lastStaker.addr != address(0));
            // exchange
            lastStaker.index = index;
            _validators[index] = lastAddr;
        }

        _validators.pop();
    }
}
