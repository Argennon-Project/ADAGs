// SPDX-License-Identifier: AGPL-3.0-only


pragma solidity ^0.8.0;


import "./dags/GovernanceSystem.sol";
import "./ArgennonToken.sol";


contract ADAGs is GovernanceSystem {
    constructor(address payable _admin) 
    GovernanceSystem(
        _admin,
        LockableMintable(address(new ArgennonToken(_admin, address(this))))
    ) {}
}
