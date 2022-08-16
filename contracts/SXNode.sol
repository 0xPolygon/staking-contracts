// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract SXNode is Initializable, UUPSUpgradeable, OwnableUpgradeable, AccessControlUpgradeable {
    using AddressUpgradeable for address;

    address[] public _validators;
    uint public _validatorsLastSetBlock;
    uint public _epochSize;

    address public _signer; //TODO: temporary for testing, delete this
    bytes public _sigBytes; //TODO: temporary for testing, delete this
    bytes32 public _hashedReport; //TODO: temporary for testing, delete this
    int32 public _reportedOutcome; //TODO: temporary for testing, delete this
    address public _lastReporter; //TODO: temporary for testing, delete this

    mapping(bytes32 => int64) private _reportedOutcomes;
    mapping(bytes32 => uint256) private _reportTime;

    event OutcomeReported(bytes32 marketHash, int32 outcome);
    
    // Modifiers
    modifier onlyAdmin() {
      require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Sender doesn't have admin role");
      _;
    }

    /// @notice Throws if the msg.sender is not part of current _validators list
    modifier onlyValidator() {
      bool isValidator = false;
      for(uint i; i < _validators.length; i++) {
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
      int32 outcome,
      uint64 epoch, 
      uint256 timestamp,
      bytes[] calldata signatures
    ) external onlyValidator notAlreadyReported(marketHash) {

      bytes32 reportHashed = keccak256(abi.encode(
        marketHash,
        outcome,
        epoch, 
        timestamp
      ));
      
      //TODO: temporary just for testing
      _reportedOutcome = outcome;
      _hashedReport = reportHashed;
      _sigBytes = signatures[0];
      _signer = recoverSigner(reportHashed, signatures[0]);
      
      address[] memory sigAddresses = new address[](signatures.length);
      uint16 sigCounter = 0;
      for (uint i=0; i < signatures.length; i++) {
        address signer = recoverSigner(reportHashed, signatures[i]);
        for (uint j=0; j < sigAddresses.length; j++) {
          require(signer != sigAddresses[j], "signatures array must be unique");
        }
        sigAddresses[i] = signer;

        //TODO: better to maintain mapping for _validators
        bool isSigValidator = false;
        for (uint k=0; k < _validators.length; k++) {
          if (_validators[k] == signer) {
            isSigValidator = true;
            break;
          }
        }
        require(isSigValidator, "all signatures must belong to current validator set");
        sigCounter++;
      }
      // validators => minSigs: 4 => 3 | 5,6 => 4 | 7 => 5 | 8,9 => 6 | ...
      uint r = _validators.length % 3;
      uint minSigs = 2 * (uint(_validators.length) / 3) + r;
      require(sigCounter >= minSigs, "not enough signatures");

      //TODO: perform any other validation now that we are done verifying signatures...

      _reportedOutcomes[marketHash] = outcome;
      _reportTime[marketHash] = block.timestamp;
      _lastReporter = msg.sender;

      emit OutcomeReported(marketHash, outcome);
    }

    function getReportedOutcome(bytes32 marketHash) public view returns (int64) {
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
    function reportedOutcome() public view returns (int32) {
      return _reportedOutcome;
    }

    //TODO: temporary for testing, delete this
    function hashedReport() public view returns (bytes32) {
      return _hashedReport;
    }

    //TODO: temporary for testing, delete this
    function lastReporter() public view returns (address) {
      return _lastReporter;
    }

    // recoverSigner splits signature and calls ecrecover on the message hash
    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address)
    {
      uint8 v;
      bytes32 r;
      bytes32 s;

      (v, r, s) = splitSignature(sig);

      // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
      if (v < 27) {
          v += 27;
      }

      return ecrecover(message, v, r, s);
    }

    // splits signature into v,r,s
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
