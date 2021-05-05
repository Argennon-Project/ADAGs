// SPDX-License-Identifier: 


pragma solidity ^0.8.0;


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
    
    
    event ApprovedMinting(address minter, uint amount);
    
    
    function allowedSupply(uint timestamp) public view virtual returns (uint) {
        // we should be careful about overflows and we should not let the function fails due to overflow.
        // the usage of slope variable guarantees that calculations does not overflow.
        if (timestamp <= startTime)
            return initialSupply;
        if (timestamp > duration + startTime)
            timestamp = duration + startTime;
        return slope * (timestamp - startTime) + initialSupply;
    }


    /**
     * Grants the allowance of minting `amount` new tokens to the `minter`. To prevent certain type of attacks, it is
     * required that the current minting allowance of 'minter' be zero. So for updating the allowance amount you first
     * need to set it to zero. 
     * 
     * @param minter is the address who is allowed to mint tokens.
     * @param amount is the maximum allowed amount of minting.
     */
    function approveMinting(address minter, uint amount) onlyBy(owner) public {
        // to prevent unintentional double usage of allowances by minters, we update allowance only if it was zero before.
        require(mintingAllowances[minter] == 0, "minter already has a non-zero allowance.");
        // we don't need to check anything about amount.
        mintingAllowances[minter] = amount;
        emit ApprovedMinting(minter, amount);
    }

  
    /**
     * Mints `amount` new tokens and sends it to `recipient`. Only `owner` can call this method or an address who has enough
     * minting allowance.
     * 
     * @param recipient the address who will receive the new tokens.
     * @param amount the raw amount to be minted.
     */
    function mint(address recipient, uint amount) public {
        if (msg.sender != owner) {
            require(mintingAllowances[msg.sender] >= amount, "amount exceeds allowance.");
            mintingAllowances[msg.sender] -= amount;
        }
        _mint(recipient, amount);
    }
    
    
    function _mint(address account, uint amount) internal virtual override {
        // first we need to mint, then we can check the condition. because we don't know how the totalSupply
        // would change.
        super._mint(account, amount);
        require(totalSupply() <= allowedSupply(block.timestamp), "totalSupply exceeds limit.");
    }
}
