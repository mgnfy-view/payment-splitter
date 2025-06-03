// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std-1.9.7/src/Test.sol";

import {PaymentSplitter} from "@src/PaymentSplitter.sol";

contract BaseTest is Test {
    PaymentSplitter public paymentSplitter;

    function setUp() public {
        paymentSplitter = new PaymentSplitter();
    }
}
