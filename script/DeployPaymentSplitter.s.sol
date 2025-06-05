// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script } from "forge-std-1.9.7/src/Script.sol";

import { PaymentSplitter } from "@src/PaymentSplitter.sol";

contract DeployPaymentSplitter is Script {
    address public wrappedNativeToken;
    address public owner;

    PaymentSplitter public paymentSplitter;

    function setUp() public {
        wrappedNativeToken = address(0x123);
        owner = address(0x456);
    }

    function run() public returns (PaymentSplitter) {
        vm.startBroadcast();
        paymentSplitter = new PaymentSplitter(owner, wrappedNativeToken);
        vm.stopBroadcast();

        return paymentSplitter;
    }
}
