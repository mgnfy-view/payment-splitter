// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IPaymentSplitter {
    struct TokenConfig {
        uint256 totalShares;
        uint256 lastBalanceTracked;
        uint256 accumulatedPaymentPerShare;
    }

    struct PayeeDetails {
        uint256 shares;
        uint256 paymentDebt;
    }

    event TokenAdded(address indexed _token);
    event TokenRemoved(address indexed _token);
    event PayeesAdded(address[] indexed payees, address[] indexed tokens, uint256[] indexed shares);
    event PaymentFreezeToggled(address indexed token, bool indexed _currentState);
    event ReleasedPayment(address indexed token, address indexed payee);

    error PaymentSplitter__TokenAlreadySupported(address token);
    error PaymentSplitter__CannotRemoveToken(address token);
    error PaymentSplitter__TokenNotSupported(address token);
    error PaymentSplitter__NotValidPayee(address token, address payee);
    error PaymentSplitter__PaymentFreezed(address token);
}
