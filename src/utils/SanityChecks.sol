// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title SanityChecks.
/// @author mgnfy-view.
/// @notice
library SanityChecks {
    /// @dev Zero address.
    address internal constant ZERO_ADDRESS = address(0);

    error SanityChecks__AddressZero();
    error SanityChecks__ValueZero();
    error SanityChecks__NotEqual();

    /// @notice Reverts if the given address is zero address.
    /// @param _address The input address.
    function requireNotAddressZero(address _address) internal pure {
        if (_address == ZERO_ADDRESS) revert SanityChecks__AddressZero();
    }

    /// @notice Reverts if the given value is 0.
    /// @param _value The input value.
    function requireNotValueZero(uint256 _value) internal pure {
        if (_value == 0) revert SanityChecks__ValueZero();
    }

    /// @notice Reverts if the given values are not equal.
    /// @param _value1 The first input value.
    /// @param _value2 The second input value.
    function requireEqual(uint256 _value1, uint256 _value2) internal pure {
        if (_value1 != _value2) revert SanityChecks__NotEqual();
    }
}
