// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/// @title OutcomeReporter
/// @notice Handles outcomes reported by SX Network validator nodes
contract OutcomeReporter is Initializable, UUPSUpgradeable, OwnableUpgradeable, AccessControlUpgradeable {
    using AddressUpgradeable for address;

    address private _SXNode;

    address[] public _validators;
    uint public _validatorsLastSetBlock;
    uint public _epochSize;

    address public _signer; //TODO: temporary for testing, delete this
    bytes public _sigBytes; //TODO: temporary for testing, delete this
    bytes32 public _hashedReport; //TODO: temporary for testing, delete this
    int32 public _reportedOutcome; //TODO: temporary for testing, delete this
    address public _lastReporter; //TODO: temporary for testing, delete 
    bytes32 public _lastMarketHash; //TODO: temporary for testing, delete 

    mapping(bytes32 => int64) private _reportedOutcomes;
    mapping(bytes32 => uint256) private _reportTime;

    event OutcomeReported(bytes32 marketHash, int32 outcome);
    
    /// @notice Throws if the sender does not have admin role, set on initialize
    modifier onlyAdmin() {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Sender doesn't have admin role");
      _;
    }

    /// @notice Throws if the sender is not the SXNode contract
    modifier onlySXNode() {
      require(_SXNode != address(0), "SXNode address not set!");
      require(_SXNode == _msgSender(), "Sender must be SXNode contract");
      _;
    }

    /// @notice Throws if the market is already reported
    /// @param marketHash The market to check
    modifier notAlreadyReported(bytes32 marketHash) {
      require(_reportTime[marketHash] == 0, "MARKET_ALREADY_REPORTED");
      _;
    }

    /// @notice initialize function
    /// @param initialValidators The initial validators to set
    /// @param sxNode The SXNode address used by onlySXNode modifier
    function initialize(address[] memory initialValidators, address sxNode) public initializer {
      _validators = initialValidators;
      _SXNode = sxNode;
      _validatorsLastSetBlock = 0;
      
      __Ownable_init();
      __UUPSUpgradeable_init();
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @notice Gets the current version, useful during upgrades
    function getVersion() public pure virtual returns (string memory) {
      return "V1";
    }

    /// @notice Sets the SXNode contract address
    /// @param sxNode The SXNode contract address used by onlySXNode modifier.
    function setSXNodeAddress(address sxNode) public onlyAdmin {
      _SXNode = sxNode;
    }

    /// @notice Sets the validators once per epoch to match the latest snapshot validator set
    /// @notice Called by SXNode
    function setValidators(address[] memory addresses) public onlySXNode {
      require(block.number > _validatorsLastSetBlock, "Validator set cannot be updated more than once per block");
      _validatorsLastSetBlock = block.number;
      _validators = addresses;
    }
   
    /// @notice Gets the list of validators set at the last epoch
    function getValidators() public view returns(address[] memory) {
      return _validators;
    }

    /// @notice Sets the signed reporting payload
    /// @notice Called by SXNode
    /// @param marketHash The market to report
    /// @param outcome The outcome to report
    /// @param epoch The epoch of the report payload
    /// @param timestamp The timestamp of the report payload
    /// @param signatures The array containing the quorum of validator signatures for consensus
    function reportOutcome(bytes32 marketHash, int32 outcome, uint64 epoch, uint256 timestamp, bytes[] calldata signatures) 
        external onlySXNode notAlreadyReported(marketHash) {
      bytes32 reportHashed = keccak256(abi.encode(marketHash, outcome, epoch, timestamp));
      
      //TODO: temporary just for testing
      _lastMarketHash = marketHash;
      _reportedOutcome = outcome;
      _hashedReport = reportHashed;
      _sigBytes = signatures[0];
      _signer = recoverSigner(reportHashed, signatures[0]);
      _lastReporter = _msgSender();
      
      address[] memory sigAddresses = new address[](signatures.length);
      uint16 sigCounter = 0;
      for (uint i=0; i < signatures.length; i++) {
        address signer = recoverSigner(reportHashed, signatures[i]);
        for (uint j=0; j < sigAddresses.length; j++) {
          require(signer != sigAddresses[j], "signatures array must be unique");
        }
        sigAddresses[i] = signer;

        //TODO: better to maintain mapping for _validators for faster indexing?
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
      // validators => minSigs: 
      // 4 => 3
      // 5,6 => 4
      // 7 => 5
      // 8,9 => 6
      // ...
      uint r = _validators.length % 3;
      uint minSigs = 2 * (uint(_validators.length) / 3) + r;
      require(sigCounter >= minSigs, "not enough signatures");

      //TODO: perform any other validation now that we are done verifying signatures...

      _reportedOutcomes[marketHash] = outcome;
      _reportTime[marketHash] = block.timestamp;

      emit OutcomeReported(marketHash, outcome);
    }

    /// @notice Gets the reported outcome for the specified marketHash
    /// @param marketHash The market to report
    function getReportedOutcome(bytes32 marketHash) public view returns (int64) {
      return _reportedOutcomes[marketHash];
    }

    /// @notice Gets the reported outcome timestamp for the specified marketHash
    /// @param marketHash The market to report
    function getReportTime(bytes32 marketHash) public view returns (uint256) {
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

    //TODO: temporary for testing, delete this
    function lastMarketHash() public view returns (bytes32) {
      return _lastMarketHash;
    }

    /// @notice Splits signature and calls ecrecover on the message hash
    /// @param message The keccak256 abi encoded report payload
    /// @param sig The signature of a validator
    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
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

    /// @notice Splits signature into v,r,s
    /// @param sig The signature of a validator
    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
      require(sig.length == 65, "Signature length must be 65");

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
}
