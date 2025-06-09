// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { console } from "forge-std-1.9.7/src/console.sol";

import { IPaymentSplitter } from "@src/interfaces/IPaymentSplitter.sol";

import { BaseTest } from "@test/utils/BaseTest.sol";

contract NativeWrapperTests is BaseTest {
    function test_wrapNativeToken() external {
        uint256 amount = 1 ether;

        vm.deal(owner, amount);

        vm.prank(owner);
        (bool success,) = payable(address(paymentSplitter)).call{ value: amount }("");

        if (!success) revert();

        uint256 wrappedNativeBalance = wrappedNative.balanceOf(address(paymentSplitter));

        assertEq(wrappedNativeBalance, amount);
    }
}
