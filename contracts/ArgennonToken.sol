// SPDX-License-Identifier: 


pragma solidity ^0.8.0;


import "./erc20/MintableERC20.sol";
import "./erc20/SharesToken.sol";
import "./erc20/LockableERC20.sol";

string constant NAME = "ada";
string constant SYMBOL = "sym";

uint8 constant DECIMALS = 6;
uint constant CAP = 500;
uint constant INITIAL_SUPPLY = 20;
uint constant DURATION = 200000;

uint constant SLOPE = (CAP - INITIAL_SUPPLY) / DURATION;


contract ArgennonToken is LockableERC20, MintableERC20, SharesToken {
    
    
    constructor(address payable admin, address owner) 
    Administered(admin)
    MintableERC20(owner, NAME, SYMBOL, CAP, INITIAL_SUPPLY, DURATION) {
        //founder = FOUNDER;
        //mint(FOUNDER, FOUNDER_SHARE);
        //approveMinting(FOUNDER, FOUNDER_INITIAL_MINT_APPROVAL);
    }
    
    
    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }
    
    
    function _mint(address account, uint256 amount) internal override(ERC20, MintableERC20) {
        MintableERC20._mint(account, amount);
    }
    
    
    function _transfer(address sender, address recipient, uint256 amount) internal override(ERC20, SharesToken) {
        SharesToken._transfer(sender, recipient, amount);
    }
    
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, LockableERC20) {
        LockableERC20._beforeTokenTransfer(from, to, amount);
    }
}
  