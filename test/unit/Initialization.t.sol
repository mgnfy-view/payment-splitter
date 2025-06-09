// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { console } from "forge-std-1.9.7/src/console.sol";

import { IPaymentSplitter } from "@src/interfaces/IPaymentSplitter.sol";

import { BaseTest } from "@test/utils/BaseTest.sol";

contract InitializationTests is BaseTest {
    function test_checkInitialization() external view {
        assertEq(paymentSplitter.owner(), owner);
        assertEq(paymentSplitter.getWrappedNativeToken(), address(wrappedNative));
    }
}
