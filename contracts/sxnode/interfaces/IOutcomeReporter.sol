// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.7;

/**
    @title Interface to be used with SXNode
 */
interface IOutcomeReporter {
    
    /**
      @notice Sets the list of validator addresses to the specified list.
      @notice Called by setValidators() of SXNode which is called from SX validator nodes via hook once per epoch.
    */
    function setValidators(address[] memory addresses) external;

    /**
      @notice Gets the current list of validators as set on OutcomeReporter.
    */
    function getValidators() external view returns(address[] memory);

    /**
      @notice Reports outcome for the given marketHash after asserting we've reached the proper validator signature threshold.
    */
    function reportOutcome(bytes32 marketHash, int32 outcome, uint64 epoch, uint256 timestamp, bytes[] calldata signatures) external;
}
