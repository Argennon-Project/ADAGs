// SPDX-License-Identifier: 


pragma solidity ^0.8.0;


import "./Tools.sol";


abstract contract AccessControlled {
     modifier onlyBy(address user) { require(msg.sender == user, "Sender not authorized."); _; }
     modifier onlyBefore(uint timestamp) { require(block.timestamp <= timestamp, "Too late..."); _; }
     modifier onlyAfter(uint timestamp) { require(block.timestamp > timestamp, "Too early..."); _; }
}
