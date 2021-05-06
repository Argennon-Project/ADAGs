// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.8.0;


import "./../utils/Owned.sol";


contract MintableERC20 is ERC20, Owned {
    uint immutable private slope;
    uint immutable private duration;
    uint immutable private startTime;
    uint immutable private initialSupply;
    mapping(address => uint) public mintingAllowances;


    /**
     * The maximum allowed total supply of the created token will be controlled by a linear function of time. This
     * function is equal to `_initialSupply` before `_startTime`. After `_startTime`, the maximum allowed total supply
     * will increase linearly from `_initialSupply` to reach `_maxSupply` after `_duration` of time.
     *
     * @param _owner is the owner of the token who is allowed to mint and give minting allowances
     */
    constructor(address _owner,
        string memory _name, string memory _symbol, 
        uint _initialSupply, uint _maxSupply, uint _startTime, uint _duration
    )
    Owned(_owner)
    ERC20(_name, _symbol) {
        uint _slope = (_maxSupply - _initialSupply) / _duration;
        require(_slope > 0 || _initialSupply == _maxSupply, "bad inputs");

        startTime = _startTime;
        initialSupply = _initialSupply;
        duration = _duration;
        slope = _slope;
    }
    
    
    event MintingAllowanceIncreased(address minter, uint amount);


    /**
     * Returns the maximum allowed total supply of the token for the specified time. The maximum supply is an
     * increasing function of time. Exceeding allowed supply limit is impossible.
     *
     * @param timestamp is the time stamp in seconds as is in block.timestamp.
     */
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
     * Adds `amount` to the minting allowance of the `minter`, and grants the allowance of minting `amount` more tokens
     * to the `minter` in addition to his previous allowance.
     * 
     * @param minter is the address who is allowed to mint tokens.
     * @param amount is the amount that the allowance will increase. This value will be added to the previous allowance.
     */
    function increaseMintingAllowance(address minter, uint amount) onlyBy(owner) public {
        // we don't need to check anything about amount. Solidity should detect overflows.
        mintingAllowances[minter] += amount;
        emit MintingAllowanceIncreased(minter, amount);
    }

  
    /**
     * Mints `amount` new tokens and sends it to `recipient`. Only `owner` can call this method or an address which
     * has enough minting allowance. Minting of the new tokens can not increase the total supply beyond the allowed
     * max supply.
     * 
     * @param recipient the address who will receive the new tokens.
     * @param amount the raw amount to be minted.
     */
    function mint(address recipient, uint amount) public {
        if (msg.sender != owner) {
            require(mintingAllowances[msg.sender] >= amount, "amount exceeds allowance");
            mintingAllowances[msg.sender] -= amount;
        }
        _mint(recipient, amount);
    }
    
    
    function _mint(address account, uint amount) internal virtual override {
        // first we need to mint, then we can check the condition. because we don't know how the totalSupply
        // would change.
        super._mint(account, amount);
        require(totalSupply() <= allowedSupply(block.timestamp), "totalSupply exceeds limit");
    }
}
