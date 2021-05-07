// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.8.0;


import "./erc20/MintableERC20.sol";
import "./erc20/DistributorERC20.sol";
import "./erc20/LockableERC20.sol";


string constant NAME = "Argennon Token";
string constant SYMBOL = "ARG";
uint8 constant DECIMALS = 6;
uint constant CAP = 50e15;
uint constant INITIAL_SUPPLY = 15e15;
uint constant DURATION = 2555 days;


address constant FOUNDER = address(0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C);
uint constant FOUNDERS_SHARE = 10e15;
uint constant FOUNDERS_INITIAL_MINT_APPROVAL = 1e15;



contract ArgennonToken is LockableERC20, MintableERC20, DistributorERC20 {
   
    
    constructor(address payable _admin, address _owner) 
    Administered(_admin)
    MintableERC20(_owner, NAME, SYMBOL, INITIAL_SUPPLY, CAP, block.timestamp, DURATION) {
        // we have to use low level functions because the msg.sender != owner and higher level functions will fail.
        // this will reduce our gas usage too.
        ERC20._mint(FOUNDER, FOUNDERS_SHARE);
        mintingAllowances[FOUNDER] = FOUNDERS_INITIAL_MINT_APPROVAL;
    }
    
    
    function founder() public pure returns(string memory) {
        return "aybehrouz";
    }
    
    
    function founderAccount() public pure returns(address) {
        return FOUNDER;
    }
    
    
    function decimals() public pure override returns(uint8) {
        return DECIMALS;
    }
    
    
    function _mint(address account, uint256 amount) internal override(ERC20, MintableERC20) {
        MintableERC20._mint(account, amount);
    }
    

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal
    override(ERC20, LockableERC20, DistributorERC20) {
        LockableERC20._beforeTokenTransfer(from, to, amount);
        DistributorERC20._beforeTokenTransfer(from, to, amount);
    }
}
  