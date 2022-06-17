// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.7;

/**
    @title Interface to be used with SXPoS
 */
interface IBlockRewards {
    /**
      @notice Sends the specified {validator} native SX specified by {amount}.
      @notice Called by validators() of SXPoS.
    */
    function payoutBlockRewards(address validator, uint256 amount) external;
}
