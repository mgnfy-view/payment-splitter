// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { console } from "forge-std-1.9.7/src/console.sol";

import { IPaymentSplitter } from "@src/interfaces/IPaymentSplitter.sol";

import { BaseTest } from "@test/utils/BaseTest.sol";

contract SetPayeesTests is BaseTest {
    function test_setNewPayees() external {
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

        IPaymentSplitter.TokenConfig memory tokenConfig = paymentSplitter.getTokenConfig(address(wrappedNative));

        assertEq(tokenConfig.totalShares, shares[0] + shares[1]);
        assertEq(tokenConfig.lastBalanceTracked, 0);
        assertEq(tokenConfig.accumulatedPaymentPerShare, 0);

        assertEq(paymentSplitter.getPayees(address(wrappedNative)).length, 2);
        assertEq(paymentSplitter.getPayeeAt(address(wrappedNative), 0), users[0]);
        assertEq(paymentSplitter.getPayeeAt(address(wrappedNative), 1), users[1]);

        IPaymentSplitter.PayeeDetails memory user1Details =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[0]);

        assertEq(user1Details.shares, shares[0]);
        assertEq(user1Details.paymentDebt, 0);

        IPaymentSplitter.PayeeDetails memory user2Details =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[1]);

        assertEq(user2Details.shares, shares[1]);
        assertEq(user2Details.paymentDebt, 0);
    }

    function test_setNewPayeeLaterWithoutPaymentDebt() external {
        address[] memory payees = new address[](1);
        payees[0] = users[0];
        address[] memory tokens = new address[](1);
        tokens[0] = address(wrappedNative);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 5000;

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);

        payees[0] = users[1];

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);

        IPaymentSplitter.TokenConfig memory tokenConfig = paymentSplitter.getTokenConfig(address(wrappedNative));

        assertEq(tokenConfig.totalShares, 2 * shares[0]);
        assertEq(tokenConfig.lastBalanceTracked, 0);
        assertEq(tokenConfig.accumulatedPaymentPerShare, 0);

        assertEq(paymentSplitter.getPayees(address(wrappedNative)).length, 2);
        assertEq(paymentSplitter.getPayeeAt(address(wrappedNative), 0), users[0]);
        assertEq(paymentSplitter.getPayeeAt(address(wrappedNative), 1), users[1]);

        IPaymentSplitter.PayeeDetails memory user2Details =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[1]);

        assertEq(user2Details.shares, shares[0]);
        assertEq(user2Details.paymentDebt, 0);

        uint256 user1PendingPayment = paymentSplitter.getPendingPayment(address(wrappedNative), users[0]);
        uint256 user2PendingPayment = paymentSplitter.getPendingPayment(address(wrappedNative), users[1]);

        assertEq(user1PendingPayment, 0);
        assertEq(user2PendingPayment, 0);
    }

    function test_setNewPayeeLaterWithPaymentDebt() external {
        address[] memory payees = new address[](1);
        payees[0] = users[0];
        address[] memory tokens = new address[](1);
        tokens[0] = address(wrappedNative);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 5000;

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);

        uint256 amount = 1 ether;

        _sendPayment(address(wrappedNative), amount);

        payees[0] = users[1];

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);

        IPaymentSplitter.TokenConfig memory tokenConfig = paymentSplitter.getTokenConfig(address(wrappedNative));
        uint256 expectedAccumulatedPaymentPerShare = (amount * SCALING_FACTOR) / shares[0];

        assertEq(tokenConfig.totalShares, 2 * shares[0]);
        assertEq(tokenConfig.lastBalanceTracked, amount);
        assertEq(tokenConfig.accumulatedPaymentPerShare, expectedAccumulatedPaymentPerShare);

        assertEq(paymentSplitter.getPayees(address(wrappedNative)).length, 2);
        assertEq(paymentSplitter.getPayeeAt(address(wrappedNative), 0), users[0]);
        assertEq(paymentSplitter.getPayeeAt(address(wrappedNative), 1), users[1]);

        IPaymentSplitter.PayeeDetails memory user2Details =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[1]);

        assertEq(user2Details.shares, shares[0]);
        assertEq(user2Details.paymentDebt, expectedAccumulatedPaymentPerShare * shares[0]);

        uint256 user1PendingPayment = paymentSplitter.getPendingPayment(address(wrappedNative), users[0]);
        uint256 user2PendingPayment = paymentSplitter.getPendingPayment(address(wrappedNative), users[1]);

        assertEq(user1PendingPayment, amount);
        assertEq(user2PendingPayment, 0);
    }

    function test_removePayeeWithoutPendingPayment() external {
        uint256 initialShares = 5000;
        address[] memory payees = new address[](2);
        payees[0] = users[0];
        payees[1] = users[1];
        address[] memory tokens = new address[](2);
        tokens[0] = address(wrappedNative);
        tokens[1] = address(wrappedNative);
        uint256[] memory shares = new uint256[](2);
        shares[0] = initialShares;
        shares[1] = initialShares;

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);

        payees = new address[](1);
        payees[0] = users[0];
        tokens = new address[](1);
        tokens[0] = address(wrappedNative);
        shares = new uint256[](1);
        shares[0] = 0;

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);

        IPaymentSplitter.TokenConfig memory tokenConfig = paymentSplitter.getTokenConfig(address(wrappedNative));

        assertEq(tokenConfig.totalShares, initialShares);
        assertEq(tokenConfig.lastBalanceTracked, 0);
        assertEq(tokenConfig.accumulatedPaymentPerShare, 0);

        assertEq(paymentSplitter.getPayees(address(wrappedNative)).length, 1);
        assertEq(paymentSplitter.getPayeeAt(address(wrappedNative), 0), users[1]);

        IPaymentSplitter.PayeeDetails memory user1Details =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[0]);

        assertEq(user1Details.shares, 0);
        assertEq(user1Details.paymentDebt, 0);

        uint256 user1PendingPayment = paymentSplitter.getPendingPayment(address(wrappedNative), users[0]);

        assertEq(user1PendingPayment, 0);
    }

    function test_removePayeeWithPendingPayment() external {
        uint256 initialShares = 5000;
        address[] memory payees = new address[](2);
        payees[0] = users[0];
        payees[1] = users[1];
        address[] memory tokens = new address[](2);
        tokens[0] = address(wrappedNative);
        tokens[1] = address(wrappedNative);
        uint256[] memory shares = new uint256[](2);
        shares[0] = initialShares;
        shares[1] = initialShares;

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);

        uint256 amount = 1 ether;

        _sendPayment(address(wrappedNative), amount);

        payees = new address[](1);
        payees[0] = users[0];
        tokens = new address[](1);
        tokens[0] = address(wrappedNative);
        shares = new uint256[](1);
        shares[0] = 0;

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);

        IPaymentSplitter.TokenConfig memory tokenConfig = paymentSplitter.getTokenConfig(address(wrappedNative));
        uint256 expectedAccumulatedPaymentPerShare = (amount * SCALING_FACTOR) / (initialShares * 2);

        assertEq(tokenConfig.totalShares, initialShares);
        assertEq(tokenConfig.lastBalanceTracked, amount / 2);
        assertEq(tokenConfig.accumulatedPaymentPerShare, expectedAccumulatedPaymentPerShare);

        assertEq(paymentSplitter.getPayees(address(wrappedNative)).length, 1);
        assertEq(paymentSplitter.getPayeeAt(address(wrappedNative), 0), users[1]);

        IPaymentSplitter.PayeeDetails memory user1Details =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[0]);

        assertEq(user1Details.shares, 0);
        assertEq(user1Details.paymentDebt, 0);

        uint256 user1PendingPayment = paymentSplitter.getPendingPayment(address(wrappedNative), users[0]);

        assertEq(user1PendingPayment, 0);
    }

    function test_modifyPayeeSharesWithoutPendingPayment() external {
        uint256 initialShares = 5000;
        address[] memory payees = new address[](2);
        payees[0] = users[0];
        payees[1] = users[1];
        address[] memory tokens = new address[](2);
        tokens[0] = address(wrappedNative);
        tokens[1] = address(wrappedNative);
        uint256[] memory shares = new uint256[](2);
        shares[0] = initialShares;
        shares[1] = initialShares;

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);

        payees = new address[](1);
        payees[0] = users[0];
        tokens = new address[](1);
        tokens[0] = address(wrappedNative);
        shares = new uint256[](1);
        shares[0] = 2 * initialShares;

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);

        IPaymentSplitter.TokenConfig memory tokenConfig = paymentSplitter.getTokenConfig(address(wrappedNative));

        assertEq(tokenConfig.totalShares, 3 * initialShares);
        assertEq(tokenConfig.lastBalanceTracked, 0);
        assertEq(tokenConfig.accumulatedPaymentPerShare, 0);

        IPaymentSplitter.PayeeDetails memory user1Details =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[0]);

        assertEq(user1Details.shares, 2 * initialShares);
        assertEq(user1Details.paymentDebt, 0);

        uint256 user1PendingPayment = paymentSplitter.getPendingPayment(address(wrappedNative), users[0]);

        assertEq(user1PendingPayment, 0);
    }

    function test_modifyPayeeSharesWithPendingPayment() external {
        uint256 initialShares = 5000;
        address[] memory payees = new address[](2);
        payees[0] = users[0];
        payees[1] = users[1];
        address[] memory tokens = new address[](2);
        tokens[0] = address(wrappedNative);
        tokens[1] = address(wrappedNative);
        uint256[] memory shares = new uint256[](2);
        shares[0] = initialShares;
        shares[1] = initialShares;

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);

        uint256 amount = 1 ether;

        _sendPayment(address(wrappedNative), amount);

        payees = new address[](1);
        payees[0] = users[0];
        tokens = new address[](1);
        tokens[0] = address(wrappedNative);
        shares = new uint256[](1);
        shares[0] = 0;

        vm.prank(owner);
        paymentSplitter.setPayees(payees, tokens, shares);

        IPaymentSplitter.TokenConfig memory tokenConfig = paymentSplitter.getTokenConfig(address(wrappedNative));
        uint256 expectedAccumulatedPaymentPerShare = (amount * SCALING_FACTOR) / (initialShares * 2);

        assertEq(tokenConfig.totalShares, initialShares);
        assertEq(tokenConfig.lastBalanceTracked, amount / 2);
        assertEq(tokenConfig.accumulatedPaymentPerShare, expectedAccumulatedPaymentPerShare);

        IPaymentSplitter.PayeeDetails memory user1Details =
            paymentSplitter.getPayeeDetails(address(wrappedNative), users[0]);

        assertEq(user1Details.shares, 0);
        assertEq(user1Details.paymentDebt, 0);

        uint256 user1PendingPayment = paymentSplitter.getPendingPayment(address(wrappedNative), users[0]);

        assertEq(user1PendingPayment, 0);
    }
}
