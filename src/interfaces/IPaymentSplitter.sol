// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPaymentSplitter {
    struct TokenConfig {
        uint256 totalShares;
        uint256 lastReleaseTimestamp;
        uint256 accumulatedPaymentPerShare;
        uint256 lastBalanceTracked;
    }

    struct PayeeDetails {
        uint256 shares;
        uint256 paymentDebt;
    }

    event TokenAdded(address indexed _token);
    event TokenRemoved(address indexed _token);
    event PaymentFreezeToggled(address indexed token);
    event PayeesAdded(address[] indexed payees, address[] indexed tokens, uint256[] indexed shares);

    error PaymentSplitter__TokenAlreadySupported(address token);
    error PaymentSplitter__CannotRemoveToken(address token);
    error PaymentSplitter__PayeeAlreadyAdded(address payee);
}
