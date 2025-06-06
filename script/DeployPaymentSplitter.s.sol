// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script } from "forge-std-1.9.7/src/Script.sol";

import { PaymentSplitter } from "@src/PaymentSplitter.sol";

contract DeployPaymentSplitter is Script {
    address public wrappedNativeToken;
    address public owner;
    address[] public tokens;
    address[] public payees;
    uint256[] public shares;

    PaymentSplitter public paymentSplitter;

    function setUp() public {
        wrappedNativeToken = address(0x123);
        owner = address(0x456);

        // dummy values, change on run
        tokens.push(address(0x321));
        tokens.push(address(0x321));
        payees.push(address(0x123));
        payees.push(address(0x456));
        shares.push(5000);
        shares.push(5000);
    }

    function run() public returns (PaymentSplitter) {
        vm.startBroadcast();
        paymentSplitter = new PaymentSplitter(owner, wrappedNativeToken);
        paymentSplitter.setPayees(payees, tokens, shares);
        vm.stopBroadcast();

        return paymentSplitter;
    }
}
