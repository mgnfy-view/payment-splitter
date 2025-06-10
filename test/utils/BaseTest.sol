// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IERC20 } from "@openzeppelin-contracts-5.3.0/token/ERC20/IERC20.sol";

import { Test, console } from "forge-std-1.9.7/src/Test.sol";

import { PaymentSplitter } from "@src/PaymentSplitter.sol";

import { Token } from "@test/mocks/Token.sol";
import { WrappedNative } from "@test/mocks/WrappedNative.sol";

contract BaseTest is Test {
    uint256 public constant SCALING_FACTOR = 1e18;

    address public owner;
    address[] public users;

    WrappedNative public wrappedNative;
    Token public usdc;

    PaymentSplitter public paymentSplitter;

    function setUp() public virtual {
        owner = makeAddr("owner");
        users.push(makeAddr("user1"));
        users.push(makeAddr("user2"));
        users.push(makeAddr("user3"));

        wrappedNative = new WrappedNative();
        usdc = new Token("Circle USD", "USDC");

        paymentSplitter = new PaymentSplitter(owner, address(wrappedNative));

        vm.prank(owner);
        paymentSplitter.addToken(address(wrappedNative));
    }

    function _sendPayment(address _token, uint256 _amount) internal {
        deal(_token, owner, _amount);

        vm.prank(owner);
        IERC20(_token).transfer(address(paymentSplitter), _amount);
    }
}
