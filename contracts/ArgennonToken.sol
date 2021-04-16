// SPDX-License-Identifier: 


pragma solidity ^0.8.0;


import "./erc20/MintableERC20.sol";
import "./erc20/SharesToken.sol";
import "./erc20/LockableERC20.sol";


string constant NAME = "Argennon Token";
string constant SYMBOL = "ARG";
uint8 constant DECIMALS = 6;
uint constant CAP = 500;
uint constant INITIAL_SUPPLY = 20;
uint constant DURATION = 200000;
uint constant SLOPE = (CAP - INITIAL_SUPPLY) / DURATION;


address constant FOUNDER = address(0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C);
uint constant FOUNDER_SHARE = 10;
uint constant FOUNDER_INITIAL_MINT_APPROVAL = 1;



contract ArgennonToken is LockableERC20, MintableERC20, SharesToken {
    address immutable public aybehrouz = FOUNDER;
    
    
    constructor(address payable _admin, address _owner) 
    Administered(_admin)
    MintableERC20(_owner, NAME, SYMBOL, SLOPE, INITIAL_SUPPLY, DURATION) {
        // we have to use low level functions because the msg.sender != owner and higher level functions will fail.
        // this will reduce our gas usage too.
        ERC20._mint(FOUNDER, FOUNDER_SHARE);
        mintingAllowances[FOUNDER] = FOUNDER_INITIAL_MINT_APPROVAL;
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
  