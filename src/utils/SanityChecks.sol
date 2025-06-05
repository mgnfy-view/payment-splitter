// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library SanityChecks {
    address internal constant ZERO_ADDRESS = address(0);

    error SanityChecks__AddressZero();
    error SanityChecks__ValueZero();
    error SanityChecks__NotEqual();

    function requireNotAddressZero(address _address) internal pure {
        if (_address == ZERO_ADDRESS) revert SanityChecks__AddressZero();
    }

    function requireNotValueZero(uint256 _value) internal pure {
        if (_value == 0) revert SanityChecks__ValueZero();
    }

    function requireEqual(uint256 _value1, uint256 _value2) internal pure {
        if (_value1 != _value2) revert SanityChecks__NotEqual();
    }
}
