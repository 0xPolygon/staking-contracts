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

    address public _signer; //TODO: temporary for testing, delete this
    bytes public _sigBytes; //TODO: temporary for testing, delete this
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
      bytes[] memory signatures
    ) external onlyValidator notAlreadyReported(marketHash) {

      bytes32 reportHashed = keccak256(
        abi.encodePacked(
          marketHash, 
          reportedOutcome, 
          epoch, 
          timestamp
          )
        );
      
      _hashedReport = reportHashed;

      _sigBytes = signatures[0];
      _signer = recoverSigner(reportHashed, signatures[0]);
      
      

      //TODO: 1. test onlyValidator and notAlreadyReported modifiers
      //TODO: 2. ensure hashed is identical to how we hash on edge nodes (using temporary getLastSigner getter)
      //TODO: 3. consider signatures and _validators to ensure that:
      //TODO:    a) all signatures are unique and correspond to addresses that are part of the current _validators
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
    function getSigner() public view returns (address) {
      return _signer;
    }

     //TODO: temporary for testing, delete this
    function sigBytes() public view returns (bytes memory) {
      return _sigBytes;
    }

     //TODO: temporary for testing, delete this
    function hashedReport() public view returns (bytes32) {
      return _hashedReport;
    }

    // see https://gitlab.com/nextgenbt/betx/sportx-contracts/-/blob/master/contracts/libraries/LibOrder.sol#L78
    // see https://programtheblockchain.com/posts/2018/02/17/signing-and-verifying-messages-in-ethereum/
    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address)
    {
      uint8 v;
      bytes32 r;
      bytes32 s;

      (v, r, s) = splitSignature(sig);

      return ecrecover(message, v, r, s);
    }

    // see https://programtheblockchain.com/posts/2018/02/17/signing-and-verifying-messages-in-ethereum/
    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32)
    {
      require(sig.length == 65);

      bytes32 r;
      bytes32 s;
      uint8 v;

      assembly {
          // first 32 bytes, after the length prefix
          r := mload(add(sig, 32))
          // second 32 bytes
          s := mload(add(sig, 64))
          // final byte (first byte of the next 32 bytes)
          v := byte(0, mload(add(sig, 96)))
      }

      return (v, r, s);
    }
   
    function getVersion() public pure virtual returns (string memory) {
      return "V1";
    }
}
