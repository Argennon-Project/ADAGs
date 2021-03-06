// SPDX-License-Identifier: AGPL-3.0-only


pragma solidity ^0.8.0;


import "./Tools.sol";


abstract contract AccessControlled {
     modifier onlyBy(address user) { require(msg.sender == user, "sender not authorized"); _; }
     modifier onlyBefore(uint timestamp) { require(block.timestamp <= timestamp, "too late"); _; }
     modifier onlyAfter(uint timestamp) { require(block.timestamp > timestamp, "too early"); _; }
}
