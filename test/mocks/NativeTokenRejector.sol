// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract NativeTokenRejector {
    receive() external payable {
        revert();
    }
}
