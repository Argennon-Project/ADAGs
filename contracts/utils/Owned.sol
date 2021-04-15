// SPDX-License-Identifier: 


pragma solidity ^0.8.0;


import "./AccessControlled.sol";


contract Owned is AccessControlled {
    address public owner;
    
     
    function setOwner(address newOwner) onlyBy(owner) public virtual {
        owner = newOwner;
    }
    
}