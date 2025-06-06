// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IPaymentSplitter.
/// @author mgnfy-view.
/// @notice Interface for the payment splitter.
interface IPaymentSplitter {
    /// @notice Configuration for a given token.
    /// @param totalShares The total shares minted for this token.
    /// @param lastBalanceTracked The last snapshot of the contract's token balance.
    /// @param accumulatedPaymentPerShare The payment accumulated per share scaled by
    /// the scaling factor 1e18.
    struct TokenConfig {
        uint256 totalShares;
        uint256 lastBalanceTracked;
        uint256 accumulatedPaymentPerShare;
    }

    /// @notice Details of a payee.
    /// @param shares The shares the payee is entitled to.
    /// @param paymentDebt The payment that the user cannot claim.
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

    function addToken(address _token) external;
    function removeToken(address _token) external;
    function setPayees(address[] memory _payees, address[] memory _tokens, uint256[] memory _shares) external;
    function togglePaymentFreeze(address _token) external;
    function release(address _token, address _payee, bool _unwrap) external;
    function getSupportedTokens() external view returns (address[] memory);
    function getSupportedTokenAt(uint256 _index) external view returns (address);
    function getTokenConfig(address _token) external view returns (TokenConfig memory);
    function isPaymentFreezed(address _token) external view returns (bool);
    function getPayees(address _token) external view returns (address[] memory);
    function payeeAt(address _token, uint256 _index) external view returns (address);
    function getPayeeDetails(address _token, address _payee) external view returns (PayeeDetails memory);
}
