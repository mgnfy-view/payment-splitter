// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { console } from "forge-std-1.9.7/src/console.sol";

import { IPaymentSplitter } from "@src/interfaces/IPaymentSplitter.sol";

import { NativeTokenRejector } from "@test/mocks/NativeTokenRejector.sol";
import { BaseTest } from "@test/utils/BaseTest.sol";

contract ReleasePaymentTests is BaseTest {
    uint256 public amount;

    function setUp() public override {
        super.setUp();

        address[] memory payees = new address[](2);
        payees[0] = users[0];
        payees[1] = users[1];
        address[] memory tokens = new address[](2);
        tokens[0] = address(wrappedNative);
        tokens[1] = address(wrappedNative);
        uint256[] memory shares = new uint256[](2);
        shares[0] = 5000;
        shares[1] = 5000;

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);
    }

    function test_releasePaymentForEqualShares() external {
        amount = 1 ether;

        _sendPayment(address(wrappedNative), amount);

        paymentSplitter.release(address(wrappedNative), users[0], false);
        paymentSplitter.release(address(wrappedNative), users[1], false);

        IPaymentSplitter.PayeeDetails memory user1Details =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[0]);
        uint256 expectedAccumulatedPaymentPerShare = (amount * SCALING_FACTOR) / (2 * user1Details.shares);

        assertEq(wrappedNative.balanceOf(users[0]), amount / 2);
        assertEq(user1Details.paymentDebt, expectedAccumulatedPaymentPerShare * user1Details.shares);

        IPaymentSplitter.PayeeDetails memory user2Details =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[1]);

        assertEq(wrappedNative.balanceOf(users[1]), amount / 2);
        assertEq(user2Details.paymentDebt, expectedAccumulatedPaymentPerShare * user2Details.shares);
    }

    function test_releasePaymentForUnequalShares() external {
        address[] memory payees = new address[](1);
        payees[0] = users[0];
        address[] memory tokens = new address[](1);
        tokens[0] = address(wrappedNative);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);

        amount = 1 ether;

        _sendPayment(address(wrappedNative), amount);

        paymentSplitter.release(address(wrappedNative), users[0], false);
        paymentSplitter.release(address(wrappedNative), users[1], false);

        IPaymentSplitter.PayeeDetails memory user1Details =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[0]);
        uint256 expectedAccumulatedPaymentPerShare = (amount * SCALING_FACTOR) / ((3 * user1Details.shares) / 2);

        assertEq(wrappedNative.balanceOf(users[0]), (2 * amount) / 3);
        assertEq(user1Details.paymentDebt, expectedAccumulatedPaymentPerShare * user1Details.shares);

        IPaymentSplitter.PayeeDetails memory user2Details =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[1]);

        assertEq(wrappedNative.balanceOf(users[1]), amount / 3);
        assertEq(user2Details.paymentDebt, expectedAccumulatedPaymentPerShare * user2Details.shares);
    }

    function test_releasePaymentAfterAnotherPayeeAdded() external {
        address[] memory payees = new address[](1);
        payees[0] = users[2];
        address[] memory tokens = new address[](1);
        tokens[0] = address(wrappedNative);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 5000;

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);

        amount = 1 ether;

        _sendPayment(address(wrappedNative), amount);

        paymentSplitter.release(address(wrappedNative), users[0], false);
        paymentSplitter.release(address(wrappedNative), users[1], false);
        paymentSplitter.release(address(wrappedNative), users[2], false);

        IPaymentSplitter.PayeeDetails memory user1Details =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[0]);
        uint256 expectedAccumulatedPaymentPerShare = (amount * SCALING_FACTOR) / (3 * user1Details.shares);

        assertEq(wrappedNative.balanceOf(users[0]), amount / 3);
        assertEq(user1Details.paymentDebt, expectedAccumulatedPaymentPerShare * user1Details.shares);

        IPaymentSplitter.PayeeDetails memory user2Details =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[1]);

        assertEq(wrappedNative.balanceOf(users[1]), amount / 3);
        assertEq(user2Details.paymentDebt, expectedAccumulatedPaymentPerShare * user2Details.shares);

        IPaymentSplitter.PayeeDetails memory user3Details =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[2]);

        assertEq(wrappedNative.balanceOf(users[2]), amount / 3);
        assertEq(user3Details.paymentDebt, expectedAccumulatedPaymentPerShare * user3Details.shares);
    }

    function test_releasePaymentAfterAnotherPayeeAddedWithPreviousPaymentPending() external {
        amount = 1 ether;

        _sendPayment(address(wrappedNative), amount);

        address[] memory payees = new address[](1);
        payees[0] = users[2];
        address[] memory tokens = new address[](1);
        tokens[0] = address(wrappedNative);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 5000;

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);

        _sendPayment(address(wrappedNative), amount);

        paymentSplitter.release(address(wrappedNative), users[0], false);
        paymentSplitter.release(address(wrappedNative), users[1], false);
        paymentSplitter.release(address(wrappedNative), users[2], false);

        IPaymentSplitter.PayeeDetails memory user1Details =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[0]);
        uint256 expectedAccumulatedPaymentPerShare = ((amount * SCALING_FACTOR) / (2 * user1Details.shares))
            + ((amount * SCALING_FACTOR) / (3 * user1Details.shares));

        assertEq(wrappedNative.balanceOf(users[0]), (amount / 2) + (amount / 3));
        assertEq(user1Details.paymentDebt, expectedAccumulatedPaymentPerShare * user1Details.shares);

        IPaymentSplitter.PayeeDetails memory user2Details =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[1]);

        assertEq(wrappedNative.balanceOf(users[1]), (amount / 2) + (amount / 3));
        assertEq(user2Details.paymentDebt, expectedAccumulatedPaymentPerShare * user2Details.shares);

        IPaymentSplitter.PayeeDetails memory user3Details =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[2]);

        assertEq(wrappedNative.balanceOf(users[2]), amount / 3);
        assertEq(user3Details.paymentDebt, expectedAccumulatedPaymentPerShare * user3Details.shares);
    }

    function test_paymentReleasedWhenAPayeeIsRemoved() external {
        amount = 1 ether;

        _sendPayment(address(wrappedNative), amount);

        address[] memory payees = new address[](1);
        payees[0] = users[1];
        address[] memory tokens = new address[](1);
        tokens[0] = address(wrappedNative);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 0;

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);

        assertEq(wrappedNative.balanceOf(users[1]), amount / 2);
    }

    function test_releasePaymentInNativeToken() external {
        amount = 1 ether;

        vm.deal(owner, amount);
        (bool success,) = payable(address(paymentSplitter)).call{ value: amount }("");

        if (!success) revert();

        paymentSplitter.release(address(wrappedNative), users[0], true);
        paymentSplitter.release(address(wrappedNative), users[1], true);

        assertEq(users[0].balance, amount / 2);
        assertEq(users[1].balance, amount / 2);
    }

    function test_releasePaymentInNativeTokenWithFallback() external {
        address nativeTokenRejector = address(new NativeTokenRejector());

        address[] memory payees = new address[](1);
        payees[0] = nativeTokenRejector;
        address[] memory tokens = new address[](1);
        tokens[0] = address(wrappedNative);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 5000;

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);

        amount = 1 ether;

        vm.deal(owner, amount);
        (bool success,) = payable(address(paymentSplitter)).call{ value: amount }("");

        if (!success) revert();

        paymentSplitter.release(address(wrappedNative), users[0], false);
        paymentSplitter.release(address(wrappedNative), users[1], false);
        paymentSplitter.release(address(wrappedNative), nativeTokenRejector, true);

        assertEq(nativeTokenRejector.balance, 0);
        assertEq(wrappedNative.balanceOf(users[1]), amount / 3);
    }
}
