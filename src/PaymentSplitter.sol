// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin-contracts-5.3.0/token/ERC20/IERC20.sol";

import { Ownable, Ownable2Step } from "@openzeppelin-contracts-5.3.0/access/Ownable2Step.sol";
import { SafeERC20 } from "@openzeppelin-contracts-5.3.0/token/ERC20/utils/SafeERC20.sol";
import { EnumerableSet } from "@openzeppelin-contracts-5.3.0/utils/structs/EnumerableSet.sol";

import { IPaymentSplitter } from "@src/interfaces/IPaymentSplitter.sol";

import { NativeWrapper } from "@src/NativeWrapper.sol";
import { SanityChecks } from "@src/utils/SanityChecks.sol";

contract PaymentSplitter is Ownable2Step, NativeWrapper, IPaymentSplitter {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    address internal immutable i_thisAddress;

    EnumerableSet.AddressSet internal s_supportedTokens;
    mapping(address token => TokenConfig config) internal s_tokenConfig;
    mapping(address token => bool isFreezed) internal s_freezedPayment;
    EnumerableSet.AddressSet internal s_payees;
    mapping(address payee => mapping(address token => PayeeDetails details)) internal s_payeeDetails;

    constructor(address _owner, address _wrappedNative) Ownable(_owner) NativeWrapper(_wrappedNative) {
        i_thisAddress = address(this);
    }

    function addToken(address _token) external onlyOwner {
        SanityChecks.requireNotAddressZero(_token);
        if (s_supportedTokens.contains(_token)) {
            revert PaymentSplitter__TokenAlreadySupported(_token);
        }

        s_supportedTokens.add(_token);
        s_tokenConfig[_token] = TokenConfig({
            totalShares: 0,
            lastReleaseTimestamp: block.timestamp,
            accumulatedPaymentPerShare: 0,
            lastBalanceTracked: 0
        });

        emit TokenAdded(_token);
    }

    function removeToken(address _token) external onlyOwner {
        SanityChecks.requireNotAddressZero(_token);
        if (s_supportedTokens.contains(_token)) {
            revert PaymentSplitter__TokenAlreadySupported(_token);
        }
        if (s_tokenConfig[_token].totalShares != 0) {
            revert PaymentSplitter__CannotRemoveToken(_token);
        }

        s_supportedTokens.remove(_token);
        delete s_tokenConfig[_token];

        emit TokenRemoved(_token);
    }

    function addPayees(address[] memory _payees, address[] memory _tokens, uint256[] memory _shares) external {
        uint256 length = _payees.length;

        SanityChecks.requireEqual(length, _tokens.length);
        SanityChecks.requireEqual(_tokens.length, _shares.length);

        for (uint256 i = 0; i < length; ++i) {
            if (s_payees.contains(_payees[i])) revert PaymentSplitter__PayeeAlreadyAdded(_payees[i]);

            uint256 paymentDebt = s_tokenConfig[_tokens[i]].accumulatedPaymentPerShare * _shares[i];
            s_payeeDetails[_payees[i]][_tokens[i]] = PayeeDetails({ shares: _shares[i], paymentDebt: paymentDebt });
        }

        emit PayeesAdded(_payees, _tokens, _shares);
    }

    function togglePaymentFreeze(address _token) external onlyOwner {
        SanityChecks.requireNotAddressZero(_token);

        s_freezedPayment[_token] = !s_freezedPayment[_token];

        emit PaymentFreezeToggled(_token);
    }
}
