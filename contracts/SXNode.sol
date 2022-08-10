// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract SXNode is Initializable, UUPSUpgradeable, OwnableUpgradeable,AccessControlUpgradeable {
    using AddressUpgradeable for address;

    address[] public _validators;
    uint public _validatorsLastSetBlock;
    uint public _epochSize;
    uint public _outcome;
    
    // Modifiers
    modifier onlyEOA() {
        require(!msg.sender.isContract(), "Only EOA can call function");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Sender doesn't have admin role");
        _;
    }

    modifier onlyZeroAddress() {
      require(msg.sender == address(0), "Sender must be zero address");
      _;
    }

    function initialize(address[] memory initialValidators) public initializer {
      _validators = initialValidators;
      _validatorsLastSetBlock = 0;
      _epochSize = 100;
      
      __Ownable_init();
      __UUPSUpgradeable_init();
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    // sets the validators once per epoch as derived from the latest snapshot validator set
    // called by sxnode service preStateCommitHook
    function setValidators(address[] memory addresses) public onlyZeroAddress {
      require(block.number > _validatorsLastSetBlock, "Validator set cannot be updated more than once per block");
      require(block.number % _epochSize == 0, "Validator set can only be updated at end of an epoch");
      _validatorsLastSetBlock = block.number;
      _validators = addresses;
    }
   
   // gets the validators
    function getValidators() public view returns(address[] memory) {
      return _validators;
    }

    // sets the signed reporting payload
    // called by sxnode service once majority of validator sigs has been met
    function reportOutcome(uint outcome) external {
      bool isValidator = false;
      for(uint256 i; i < _validators.length; i++) {
        if (_validators[i] == msg.sender) {
          isValidator = true;
          break;
        }
      }
      require(isValidator, "Sender must be part of the validator set");
      _outcome = outcome;
    }

    // gets the signed reporting outcome for the specified marketHash
    function getOutcome() external view returns(uint) {
      return _outcome;
    }

    // sets the epoch size which is used to restrict the setValidators() function
    function setEpochSize(uint epochSize) external virtual onlyAdmin {
      _epochSize = epochSize;
    }

    // gets the epoch size
    function getEpochSize() external view returns(uint) {
      return _epochSize;
    }
   
    function getVersion() public pure virtual returns (string memory) {
      return "V1";
    }
}
