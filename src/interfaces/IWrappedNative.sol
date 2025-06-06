// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IWrappedNative.
/// @author mgnfy-view.
/// @notice Interface for the wrapped native token.
interface IWrappedNative {
    function deposit() external payable;
    function withdraw(uint256 _wad) external;
}
