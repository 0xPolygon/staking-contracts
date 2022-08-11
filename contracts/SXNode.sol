// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

library LibOutcome {
  enum Outcome {
    VOID,
    OUTCOME_ONE,
    OUTCOME_TWO
  }
}

contract SXNode is Initializable, UUPSUpgradeable, OwnableUpgradeable, AccessControlUpgradeable {
    using AddressUpgradeable for address;

    address[] public _validators;
    uint public _validatorsLastSetBlock;
    uint public _epochSize;

    bytes32 public _hashedReport; //TODO: temporary for testing, delete this
    mapping(bytes32 => LibOutcome.Outcome) private _reportedOutcomes;
    mapping(bytes32 => uint256) private _reportTime;

    event OutcomeReported(bytes32 marketHash, LibOutcome.Outcome outcome);

    struct ReportPayload {
      bytes32 marketHash;
      uint8 outcome;
      uint64 epoch;
      uint256 timestamp;
    }  
    
    // Modifiers
    modifier onlyAdmin() {
      require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Sender doesn't have admin role");
      _;
    }

    /// @notice Throws if the msg.sender is not part of current _validators list
    modifier onlyValidator() {
      bool isValidator = false;
      for(uint256 i; i < _validators.length; i++) {
        if (_validators[i] == msg.sender) {
          isValidator = true;
          break;
        }
      }
      require(isValidator, "Sender must be part of the validator set");
      _;
    }

    /// @notice Throws if the msg.sender is not zero address
    modifier onlyZeroAddress() {
      require(msg.sender == address(0), "Sender must be zero address");
      _;
    }

    /// @notice Throws if the market is already reported
    /// @param marketHash The market to check.
    modifier notAlreadyReported(bytes32 marketHash) {
      require(_reportTime[marketHash] == 0, "MARKET_ALREADY_REPORTED");
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

    // sets the epoch size which is used to restrict the setValidators() function
    function setEpochSize(uint epochSize) external virtual onlyAdmin {
      _epochSize = epochSize;
    }

    // gets the epoch size
    function getEpochSize() external view returns(uint) {
      return _epochSize;
    }

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
    function reportOutcome(
      bytes32 marketHash, 
      LibOutcome.Outcome reportedOutcome,
      uint64 epoch, 
      uint256 timestamp,
      string[] memory signatures
    ) external onlyValidator notAlreadyReported(marketHash) {

      ReportPayload memory reportPayload = ReportPayload(marketHash, uint8(reportedOutcome), epoch, timestamp);
      _hashedReport = keccak256(abi.encode(reportPayload.marketHash, reportPayload.outcome, reportPayload.epoch, reportPayload.timestamp));


      //TODO: 1. test onlyValidator and notAlreadyReported modifiers
      //TODO: 2. ensure hashed is identical to how we hash on edge nodes (using temporary getLatestReportHash getter)
      //TODO: 3. consider signatures and _validators to ensure that:
      //TODO:    a) all signatures are unique and correspond to publicKeys that are part of the current _validators
      //TODO:      i) when providing the keccaked payload with each unhashed signature, we should get all public keys and therefore addresses involved
      //TODO:    b) at least 2/3 signatures when compared to the total _validators
      //TODO:      i) for case where _validators has more than chain validators, hopefully 2/3 should still work - luckily we wont be modifying our set too often
      //TODO:      ii) for case where _validators has less than chain validators, hopefully 2/3 should still work - luckily we wont be modifying our set too often
      //TODO:      iii) we should ensure to only vote on / off max 1 validator per epoch
      //TODO: 4. other validation? e.g. team names exist, etc

      _reportedOutcomes[marketHash] = reportedOutcome;
      _reportTime[marketHash] = block.timestamp;

      emit OutcomeReported(marketHash, reportedOutcome);
    }

    function getReportedOutcome(bytes32 marketHash) public view returns (LibOutcome.Outcome) {
      return _reportedOutcomes[marketHash];
    }

    function get_reportTime(bytes32 marketHash) public view returns (uint256) {
      return _reportTime[marketHash];
    }

    //TODO: temporary for testing, delete this
    function getLatestReportHash() public view returns (bytes32) {
      return _hashedReport;
    }
   
    function getVersion() public pure virtual returns (string memory) {
      return "V1";
    }
}
