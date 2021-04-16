// SPDX-License-Identifier: 


pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./../utils/Owned.sol";


contract MintableERC20 is ERC20, Owned {
    uint immutable private startTime = block.timestamp;
    uint immutable private slope;
    uint immutable private initialSupply;
    uint immutable private duration;
    mapping(address => uint) public mintingAllowances;

    
    
    constructor(address _owner,
        string memory _name, string memory _symbol, 
        uint _slope, uint _initialSupply, uint _duration
    )
    Owned(_owner)
    ERC20(_name, _symbol) {
        slope = _slope;
        initialSupply = _initialSupply;
        duration = _duration;
    }
    
   
    
    function allowedSupply(uint timestamp) public view virtual returns (uint) {
        // we should be careful about overflows and we should not let the function fails due to overflow.
        // the usage of slope variable guarantees that calculations does not overflow.
        if (timestamp <= startTime)
            return initialSupply;
        if (timestamp > duration + startTime)
            timestamp = duration + startTime;
        return slope * (timestamp - startTime) + initialSupply;
    }
    
    
    function approveMinting(address minter, uint amount) onlyBy(owner) public {
        // to prevent unintentional double usage of allowances by minters, we update allowance only if it was zero before.
        require(mintingAllowances[minter] == 0, "minter already has a non-zero allowance.");
        // we don't need to check anything about amount.
        mintingAllowances[minter] = amount;
    }
  
    
    function mint(address recipient, uint amount) public {
        if (msg.sender != owner) {
            require(mintingAllowances[msg.sender] >= amount, "amount exceeds allowance.");
            mintingAllowances[msg.sender] -= amount;
        }
        _mint(recipient, amount);
    }
    
    
    // this function should not be virtual
    function _mint(address account, uint amount) internal virtual override {
        // first we need to mint, then we can check the condition. because we don't know how the totalSupply
        // would change.
        super._mint(account, amount);
        require(totalSupply() <= allowedSupply(block.timestamp), "totalSupply exceeds limit.");
    }
}