// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test, console } from "forge-std-1.9.7/src/Test.sol";

import { PaymentSplitter } from "@src/PaymentSplitter.sol";

import { Token } from "@test/mocks/Token.sol";
import { WrappedNative } from "@test/mocks/WrappedNative.sol";

contract BaseTest is Test {
    address public owner;
    address[] public users;

    WrappedNative public wrappedNative;
    Token public usdc;

    PaymentSplitter public paymentSplitter;

    function setUp() public {
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
}
