// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IWrappedNative } from "@src/interfaces/IWrappedNative.sol";

/// @title NativeWrapper.
/// @author mgnfy-view.
/// @notice Wraps all received native tokena amount.
abstract contract NativeWrapper {
    /// @dev The wrapped native token contract address.
    IWrappedNative internal immutable i_wrappedNative;

    /// @notice Initializes the contract.
    /// @param _wrappedNative Address of the wrapped native token contract.
    constructor(address _wrappedNative) {
        i_wrappedNative = IWrappedNative(_wrappedNative);
    }

    /// @notice Receives gas token and wraps it.
    receive() external payable {
        i_wrappedNative.deposit{ value: msg.value }();
    }
}
