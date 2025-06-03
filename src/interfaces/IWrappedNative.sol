// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IWrappedMonad {
    function deposit() external;
    function withdraw(uint256 _wad) external;
}
