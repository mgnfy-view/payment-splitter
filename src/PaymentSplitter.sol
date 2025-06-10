// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IERC20 } from "@openzeppelin-contracts-5.3.0/token/ERC20/IERC20.sol";

import { Ownable, Ownable2Step } from "@openzeppelin-contracts-5.3.0/access/Ownable2Step.sol";
import { SafeERC20 } from "@openzeppelin-contracts-5.3.0/token/ERC20/utils/SafeERC20.sol";
import { EnumerableSet } from "@openzeppelin-contracts-5.3.0/utils/structs/EnumerableSet.sol";

import { IPaymentSplitter } from "@src/interfaces/IPaymentSplitter.sol";

import { NativeWrapper } from "@src/NativeWrapper.sol";
import { SanityChecks } from "@src/utils/SanityChecks.sol";

/// @title PaymentSplitter.
/// @author mgnfy-view.
/// @notice A better, more comprehensive version of Openzeppelin's payment splitter, providing
/// more control over payee management.
contract PaymentSplitter is Ownable2Step, NativeWrapper, IPaymentSplitter {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    /// @dev Scaling factor to be used for accumulated payment per share.
    uint256 internal constant SCALING_FACTOR = 1e18;
    /// @dev Caching this contract's address.
    address internal immutable i_thisAddress;

    /// @dev A set of tokens supported for payment.
    EnumerableSet.AddressSet internal s_supportedTokens;
    /// @dev Config associated with each supported token.
    mapping(address token => TokenConfig config) internal s_tokenConfig;
    /// @dev Tells if the payment for a given token is freezed or not. If yes,
    /// payees cannot collect their payment until unfreezed.
    mapping(address token => bool isFreezed) internal s_freezedPayment;
    /// @dev List of payee addresses per supported token.
    mapping(address token => EnumerableSet.AddressSet payees) internal s_payees;
    /// @dev Details of each payee for a given token.
    mapping(address token => mapping(address payee => PayeeDetails details)) internal s_payeeDetails;

    /// @notice Initializes the contract.
    /// @param _owner The initial owner address.
    /// @param _wrappedNative Address of the wrapped native token.
    constructor(address _owner, address _wrappedNative) Ownable(_owner) NativeWrapper(_wrappedNative) {
        i_thisAddress = address(this);
    }

    /// @notice Support a token for payment. Owner only function.
    /// @param _token The token address.
    function addToken(address _token) external onlyOwner {
        SanityChecks.requireNotAddressZero(_token);
        if (s_supportedTokens.contains(_token)) {
            revert PaymentSplitter__TokenAlreadySupported(_token);
        }

        s_supportedTokens.add(_token);
        s_tokenConfig[_token] = TokenConfig({ totalShares: 0, lastBalanceTracked: 0, accumulatedPaymentPerShare: 0 });

        emit TokenAdded(_token);
    }

    /// @notice Removes a token from the supported tokens list. This is only possible
    /// if all the payees have been removed for that token.
    /// @param _token The token address.
    function removeToken(address _token) external onlyOwner {
        _requireIsSupportedToken(_token);
        if (s_tokenConfig[_token].totalShares != 0) {
            revert PaymentSplitter__CannotRemoveToken(_token);
        }

        s_supportedTokens.remove(_token);
        delete s_tokenConfig[_token];

        emit TokenRemoved(_token);
    }

    /// @notice Allows the owner to set new payees per token, modify the shares of existing
    /// payees, or remove existing payees.
    /// @param _payees A list of payee addresses.
    /// @param _tokens A list of token addresses.
    /// @param _shares A list of shares to assign per payee.
    function setPayees(address[] memory _payees, address[] memory _tokens, uint256[] memory _shares) external {
        uint256 length = _payees.length;

        SanityChecks.requireEqual(length, _tokens.length);
        SanityChecks.requireEqual(_tokens.length, _shares.length);

        for (uint256 i = 0; i < length; ++i) {
            _requireIsSupportedToken(_tokens[i]);

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
                _updateTokenConfig(_tokens[i]);

                s_payees[_tokens[i]].add(_payees[i]);
                uint256 paymentDebt = s_tokenConfig[_tokens[i]].accumulatedPaymentPerShare * _shares[i];
                s_payeeDetails[_tokens[i]][_payees[i]] = PayeeDetails({ shares: _shares[i], paymentDebt: paymentDebt });
                s_tokenConfig[_tokens[i]].totalShares += _shares[i];
            }
        }

        emit PayeesAdded(_payees, _tokens, _shares);
    }

    /// @notice Toggles payment freezing/unfreezing.
    /// @param _token The token address.
    function togglePaymentFreeze(address _token) external onlyOwner {
        _requireIsSupportedToken(_token);

        s_freezedPayment[_token] = !s_freezedPayment[_token];

        emit PaymentFreezeToggled(_token, s_freezedPayment[_token]);
    }

    /// @notice Releases payment for a token as per the share of a given payee.
    /// @param _token The payment token address.
    /// @param _payee The address of the payee.
    /// @param _unwrap If the token is wrapped native token (for example, WETH), whether to
    /// unwrap it and send it back as raw gas token.
    function release(address _token, address _payee, bool _unwrap) public {
        _requireIsSupportedToken(_token);
        _requireIsValidPayee(_token, _payee);
        _requirePaymentIsNotFreezed(_token);

        _updateTokenConfig(_token);

        uint256 paymentOwed = getPendingPayment(_token, _payee);
        s_payeeDetails[_token][_payee].paymentDebt =
            s_tokenConfig[_token].accumulatedPaymentPerShare * s_payeeDetails[_token][_payee].shares;

        _transferPayment(_token, paymentOwed, _payee, _unwrap);

        s_tokenConfig[_token].lastBalanceTracked = IERC20(_token).balanceOf(i_thisAddress);

        emit ReleasedPayment(_token, _payee);
    }

    /// @notice Reverts if the given token is not supported token.
    /// @param _token The token address.
    function _requireIsSupportedToken(address _token) internal view {
        if (!s_supportedTokens.contains(_token)) {
            revert PaymentSplitter__TokenNotSupported(_token);
        }
    }

    /// @notice Reverts if the given payee is not in the payee list for the given
    /// token.
    /// @param _token The token address.
    /// @param _payee The address of the payee.
    function _requireIsValidPayee(address _token, address _payee) internal view {
        if (!s_payees[_token].contains(_payee)) revert PaymentSplitter__NotValidPayee(_token, _payee);
    }

    /// @notice Reverts if payment for the given token is freezed.
    /// @param _token The token address.
    function _requirePaymentIsNotFreezed(address _token) internal view {
        if (s_freezedPayment[_token]) revert PaymentSplitter__PaymentFreezed(_token);
    }

    /// @notice Updates the config for a given token. Updates the payment per share
    /// if any payment is received after the last update.
    /// @param _token The token address.
    function _updateTokenConfig(address _token) internal {
        TokenConfig memory tokenConfig = s_tokenConfig[_token];

        uint256 balance = IERC20(_token).balanceOf(i_thisAddress);
        uint256 balanceIncrease = balance - tokenConfig.lastBalanceTracked;

        if (balanceIncrease > 0) {
            s_tokenConfig[_token].accumulatedPaymentPerShare +=
                (balanceIncrease * SCALING_FACTOR) / tokenConfig.totalShares;
            s_tokenConfig[_token].lastBalanceTracked = balance;
        }
    }

    /// @notice Transfers payment token to the payee. If the token is wrapped native
    /// token and unwrapping is requested, it unwraps the wrapped token to gas token and then sends it.
    /// @param _token The token address.
    /// @param _amount The amount to release.
    /// @param _payee The payee address.
    /// @param _unwrap Whether to unwrap the wrapped native token or not. Ignored if the payment token is
    /// not wrapped native token.
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

    /// @notice Gets a list of supported payment tokens.
    /// @return An array of supported payment tokens.
    function getSupportedTokens() external view returns (address[] memory) {
        return s_supportedTokens.values();
    }

    /// @notice Gets the supported payment token at given index.
    /// @return The payment token address.
    function getSupportedTokenAt(uint256 _index) external view returns (address) {
        return s_supportedTokens.at(_index);
    }

    /// @notice Gets the config for a given payment token.
    /// @param _token The token address.
    /// @return The token config struct.
    function getTokenConfig(address _token) external view returns (TokenConfig memory) {
        return s_tokenConfig[_token];
    }

    /// @notice Checks if payment is freezed or not for the given token.
    /// @param _token The token address.
    /// @return A bool indicating whether payment is freezed or not for the given token.
    function isPaymentFreezed(address _token) external view returns (bool) {
        return s_freezedPayment[_token];
    }

    /// @notice Gets the payees for a given payment token.
    /// @param _token The token address.
    /// @return A list of payees.
    function getPayees(address _token) external view returns (address[] memory) {
        return s_payees[_token].values();
    }

    /// @notice Gets the payees for a given payment token at the given index.
    /// @param _token The token address.
    /// @param _index The index number.
    /// @return The payee address.
    function getPayeeAt(address _token, uint256 _index) external view returns (address) {
        return s_payees[_token].at(_index);
    }

    /// @notice Gets the details for a given token and a given payee.
    /// @param _token The token address.
    /// @param _payee The payee address.
    /// @return The payee details struct.
    function getPayeeDetails(address _token, address _payee) external view returns (PayeeDetails memory) {
        return s_payeeDetails[_token][_payee];
    }

    /// @notice Gets the outstanding payment for a given payee for the given token.
    /// @param _token The token address.
    /// @param _payee The payee address.
    /// @return The outstanding payment for a given payee for the given token.
    function getPendingPayment(address _token, address _payee) public view returns (uint256) {
        TokenConfig memory tokenConfig = s_tokenConfig[_token];
        PayeeDetails memory payeeDetails = s_payeeDetails[_token][_payee];

        return
            ((tokenConfig.accumulatedPaymentPerShare * payeeDetails.shares) - payeeDetails.paymentDebt) / SCALING_FACTOR;
    }
}
