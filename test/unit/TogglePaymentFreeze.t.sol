// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { console } from "forge-std-1.9.7/src/console.sol";

import { IPaymentSplitter } from "@src/interfaces/IPaymentSplitter.sol";

import { BaseTest } from "@test/utils/BaseTest.sol";

contract TogglePaymentFreezeTests is BaseTest {
    uint256 public amount;

    function setUp() public override {
        super.setUp();

        address[] memory payees = new address[](1);
        payees[0] = users[0];
        address[] memory tokens = new address[](1);
        tokens[0] = address(wrappedNative);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);

        amount = 1 ether;

        vm.deal(owner, amount);

        vm.prank(owner);
        (bool success,) = payable(address(paymentSplitter)).call{ value: amount }("");

        if (!success) revert();
    }

    function test_freezePayment() external {
        vm.prank(owner);
        paymentSplitter.togglePaymentFreeze(address(wrappedNative));

        assertTrue(paymentSplitter.isPaymentFreezed(address(wrappedNative)));

        vm.prank(users[0]);
        vm.expectRevert(
            abi.encodeWithSelector(IPaymentSplitter.PaymentSplitter__PaymentFreezed.selector, address(wrappedNative))
        );
        paymentSplitter.release(address(wrappedNative), users[0], false);
    }

    function test_unfreezePayment() external {
        vm.prank(owner);
        paymentSplitter.togglePaymentFreeze(address(wrappedNative));

        vm.prank(owner);
        paymentSplitter.togglePaymentFreeze(address(wrappedNative));

        vm.prank(users[0]);
        paymentSplitter.release(address(wrappedNative), users[0], false);

        IPaymentSplitter.TokenConfig memory tokenConfig = paymentSplitter.getTokenConfig(address(wrappedNative));
        IPaymentSplitter.PayeeDetails memory userDetails =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[0]);
        uint256 expectedAccumulatedPaymentPerShare = (amount * 1e18) / userDetails.shares;

        assertEq(tokenConfig.lastBalanceTracked, 0);
        assertEq(tokenConfig.accumulatedPaymentPerShare, expectedAccumulatedPaymentPerShare);

        assertEq(userDetails.paymentDebt, expectedAccumulatedPaymentPerShare * userDetails.shares);
    }
}
