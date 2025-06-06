// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface INativeWrapper {
    function getWrappedNativeToken() external view returns (address);
}
