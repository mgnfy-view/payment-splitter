// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std-1.9.7/src/Script.sol";

import {PaymentSplitter} from "@src/PaymentSplitter.sol";

contract DeployPaymentSplitter is Script {
    PaymentSplitter public paymentSplitter;

    function run() public returns (PaymentSplitter) {
        vm.startBroadcast();
        paymentSplitter = new PaymentSplitter();
        vm.stopBroadcast();

        return paymentSplitter;
    }
}
