// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { console } from "forge-std-1.9.7/src/console.sol";

import { IPaymentSplitter } from "@src/interfaces/IPaymentSplitter.sol";

import { BaseTest } from "@test/utils/BaseTest.sol";

contract TokenWhitelistTests is BaseTest {
    function test_whitelistToken() external {
        vm.prank(owner);
        paymentSplitter.addToken(address(usdc));

        assertEq(paymentSplitter.getSupportedTokens().length, 2);
        assertEq(paymentSplitter.getSupportedTokenAt(1), address(usdc));

        IPaymentSplitter.TokenConfig memory tokenConfig = paymentSplitter.getTokenConfig(address(usdc));

        assertEq(tokenConfig.totalShares, 0);
        assertEq(tokenConfig.lastBalanceTracked, 0);
        assertEq(tokenConfig.accumulatedPaymentPerShare, 0);
    }

    function test_cannotWhitelistSameTokenAgain() external {
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IPaymentSplitter.PaymentSplitter__TokenAlreadySupported.selector, address(wrappedNative)
            )
        );
        paymentSplitter.addToken(address(wrappedNative));
    }

    function test_canRemoveWhitelistedToken() external {
        vm.prank(owner);
        paymentSplitter.removeToken(address(wrappedNative));

        assertEq(paymentSplitter.getSupportedTokens().length, 0);

        IPaymentSplitter.TokenConfig memory tokenConfig = paymentSplitter.getTokenConfig(address(wrappedNative));

        assertEq(tokenConfig.totalShares, 0);
        assertEq(tokenConfig.lastBalanceTracked, 0);
        assertEq(tokenConfig.accumulatedPaymentPerShare, 0);
    }

    function test_cannotRemoveWhitelistedTokenIfPayeesExist() external {
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

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(IPaymentSplitter.PaymentSplitter__CannotRemoveToken.selector, address(wrappedNative))
        );
        paymentSplitter.removeToken(address(wrappedNative));
    }
}
