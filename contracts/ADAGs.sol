// SPDX-License-Identifier: 


pragma solidity ^0.8.0;


import "./dags/GovernanceSystem.sol";
import "./ArgennonToken.sol";


address constant FOUNDER = address(0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C);
uint constant FOUNDER_SHARE = 10;
uint constant FOUNDER_INITIAL_MINT_APPROVAL = 1;


contract ADAGs is GovernanceSystem {
    address immutable public founder = FOUNDER;
    
    constructor(address payable _admin) 
    GovernanceSystem(
        _admin,
        LockableMintable(address(new ArgennonToken(_admin, address(this))))
    ) {
        governanceToken.mint(FOUNDER, FOUNDER_SHARE);
        governanceToken.approveMinting(FOUNDER, FOUNDER_INITIAL_MINT_APPROVAL);
    }
    
}