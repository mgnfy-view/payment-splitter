// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IWrappedNative } from "@src/interfaces/IWrappedNative.sol";

abstract contract NativeWrapper {
    IWrappedNative internal immutable i_wrappedNative;

    constructor(address _wrappedNative) {
        i_wrappedNative = IWrappedNative(_wrappedNative);
    }

    receive() external payable {
        i_wrappedNative.deposit{ value: msg.value }();
    }
}
