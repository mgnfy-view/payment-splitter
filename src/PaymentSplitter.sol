// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

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

    uint256 internal constant SCALING_FACTOR = 1e18;
    address internal immutable i_thisAddress;

    EnumerableSet.AddressSet internal s_supportedTokens;
    mapping(address token => TokenConfig config) internal s_tokenConfig;
    mapping(address token => bool isFreezed) internal s_freezedPayment;
    mapping(address token => EnumerableSet.AddressSet payees) internal s_payees;
    mapping(address token => mapping(address payee => PayeeDetails details)) internal s_payeeDetails;

    constructor(address _owner, address _wrappedNative) Ownable(_owner) NativeWrapper(_wrappedNative) {
        i_thisAddress = address(this);
    }

    function addToken(address _token) external onlyOwner {
        SanityChecks.requireNotAddressZero(_token);
        if (s_supportedTokens.contains(_token)) {
            revert PaymentSplitter__TokenAlreadySupported(_token);
        }

        s_supportedTokens.add(_token);
        s_tokenConfig[_token] = TokenConfig({ totalShares: 0, lastBalanceTracked: 0, accumulatedPaymentPerShare: 0 });

        emit TokenAdded(_token);
    }

    function removeToken(address _token) external onlyOwner {
        _requireIsSupportedToken(_token);
        if (s_tokenConfig[_token].totalShares != 0) {
            revert PaymentSplitter__CannotRemoveToken(_token);
        }

        s_supportedTokens.remove(_token);
        delete s_tokenConfig[_token];

        emit TokenRemoved(_token);
    }

    function setPayees(address[] memory _payees, address[] memory _tokens, uint256[] memory _shares) external {
        uint256 length = _payees.length;

        SanityChecks.requireEqual(length, _tokens.length);
        SanityChecks.requireEqual(_tokens.length, _shares.length);

        for (uint256 i = 0; i < length; ++i) {
            if (s_payees[_tokens[i]].contains(_payees[i])) {
                release(_tokens[i], _payees[i], false);
                s_tokenConfig[_tokens[i]].totalShares -= s_payeeDetails[_tokens[i]][_payees[i]].shares;
                s_payeeDetails[_tokens[i]][_payees[i]].shares = _shares[i];
                s_tokenConfig[_tokens[i]].totalShares += _shares[i];

                if (_shares[i] == 0) {
                    s_payees[_tokens[i]].remove(_payees[i]);
                    delete s_payeeDetails[_tokens[i]][_payees[i]];
                }
            } else {
                uint256 paymentDebt = s_tokenConfig[_tokens[i]].accumulatedPaymentPerShare * _shares[i];
                s_payeeDetails[_tokens[i]][_payees[i]] = PayeeDetails({ shares: _shares[i], paymentDebt: paymentDebt });
                s_tokenConfig[_tokens[i]].totalShares += _shares[i];
            }
        }

        emit PayeesAdded(_payees, _tokens, _shares);
    }

    function togglePaymentFreeze(address _token) external onlyOwner {
        _requireIsSupportedToken(_token);

        s_freezedPayment[_token] = !s_freezedPayment[_token];

        emit PaymentFreezeToggled(_token, s_freezedPayment[_token]);
    }

    function release(address _token, address _payee, bool _unwrap) public {
        _requireIsSupportedToken(_token);
        _requireIsValidPayee(_token, _payee);
        _requirePaymentIsNotFreezed(_token);

        _updateTokenConfig(_token);

        TokenConfig memory tokenConfig = s_tokenConfig[_token];
        PayeeDetails memory payeeDetails = s_payeeDetails[_token][_payee];

        uint256 paymentOwed =
            ((tokenConfig.accumulatedPaymentPerShare * payeeDetails.shares) - payeeDetails.paymentDebt) / SCALING_FACTOR;
        s_payeeDetails[_token][_payee].paymentDebt = tokenConfig.accumulatedPaymentPerShare;

        _transferPayment(_token, paymentOwed, _payee, _unwrap);

        s_tokenConfig[_token].lastBalanceTracked = IERC20(_token).balanceOf(i_thisAddress);

        emit ReleasedPayment(_token, _payee);
    }

    function _requireIsSupportedToken(address _token) internal view {
        if (!s_supportedTokens.contains(_token)) {
            revert PaymentSplitter__TokenNotSupported(_token);
        }
    }

    function _requireIsValidPayee(address _token, address _payee) internal view {
        if (!s_payees[_token].contains(_payee)) revert PaymentSplitter__NotValidPayee(_token, _payee);
    }

    function _requirePaymentIsNotFreezed(address _token) internal view {
        if (s_freezedPayment[_token]) revert PaymentSplitter__PaymentFreezed(_token);
    }

    function _updateTokenConfig(address _token) internal {
        TokenConfig memory tokenConfig = s_tokenConfig[_token];

        uint256 balanceIncrease = IERC20(_token).balanceOf(i_thisAddress) - tokenConfig.lastBalanceTracked;

        s_tokenConfig[_token].accumulatedPaymentPerShare += (balanceIncrease * SCALING_FACTOR) / tokenConfig.totalShares;
    }

    function _transferPayment(address _token, uint256 _amount, address _payee, bool _unwrap) internal {
        if (_token == address(i_wrappedNative) && _unwrap) {
            i_wrappedNative.withdraw(_amount);
            (bool success,) = payable(_payee).call{ value: _amount }("");

            if (success) {
                return;
            }
        }

        IERC20(_token).safeTransfer(_payee, _amount);
    }
}
