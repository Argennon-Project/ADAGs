// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract TestToken is ERC20 {
    uint8 private d;
    
      
    function decimals() public view override returns (uint8) {
        return d;
    }
  
    
    constructor(uint256 initialSupply, uint8 _decimals) ERC20("Test", "TST") {
        d = _decimals;
        _mint(msg.sender, initialSupply);
    }
}
