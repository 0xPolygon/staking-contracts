// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {IOutcomeReporter} from "./interfaces/IOutcomeReporter.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/// @title SXNode
/// @notice This contract is called by SX Network validator nodes
contract SXNode is Initializable, UUPSUpgradeable, OwnableUpgradeable, AccessControlUpgradeable {
    using AddressUpgradeable for address;

    IOutcomeReporter public _outcomeReporter;

    /// @notice Throws if the sender does not have admin role, set on initialize
    modifier onlyAdmin() {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Sender doesn't have admin role");
      _;
    }

    /// @notice Throws if the msg.sender is not zero address
    modifier onlyZeroAddress() {
      require(_msgSender() == address(0), "Sender must be zero address");
      _;
    }

    /// @notice initialize function
    function initialize() public initializer {
      __Ownable_init();
      __UUPSUpgradeable_init();
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @notice Gets the current version, useful during upgrades
    function getVersion() public pure virtual returns (string memory) {
      return "V1";
    }

    /*
    * OutcomeReporter functions
    */

    /// @notice Sets the outcomeReporter contract address to be used when calling reporting-specific functions
    /// @notice Only callable by admin
    function setOutcomeReporter(address outcomeReporter) public onlyAdmin {
      _outcomeReporter = IOutcomeReporter(outcomeReporter);
    }

    /// @notice Sets the validators once per epoch to match the latest snapshot validator set
    /// @notice Called by SX Network validators via hook
    function setValidators(address[] memory addresses) public onlyZeroAddress {
      _outcomeReporter.setValidators(addresses);
    }
   
    /// @notice Sets the signed reporting payload
    /// @notice Called by SX Network validator once majority of validator sigs has been met
    /// @param marketHash The market to report
    /// @param outcome The outcome to report
    /// @param epoch The epoch of the report payload
    /// @param timestamp The timestamp of the report payload
    /// @param signatures The array containing the quorum of validator signatures for consensus
    function reportOutcome(
      bytes32 marketHash, 
      int32 outcome,
      uint64 epoch, 
      uint256 timestamp,
      bytes[] calldata signatures
    ) external {
      address[] memory validators = _outcomeReporter.getValidators();
      bool isValidator = false;
      for(uint i; i < validators.length; i++) {
        if (validators[i] == _msgSender()) {
          isValidator = true;
          break;
        }
      }
      require(isValidator, "Sender must be part of the validator set");

      _outcomeReporter.reportOutcome(marketHash, outcome, epoch, timestamp, signatures);
    }


}
