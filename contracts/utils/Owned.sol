// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.8.0;


import "./AccessControlled.sol";


contract Owned is AccessControlled {
    address public owner;


    event OwnerChanged(address newOwner);


    constructor(address _owner) {
        owner = _owner;
    }
    
     
    function setOwner(address newOwner) onlyBy(owner) public virtual {
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }
    
}
