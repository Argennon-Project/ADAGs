// SPDX-License-Identifier: 


pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AccessControlled.sol";
import "./Tools.sol";


contract Administered is AccessControlled, PossessiveContract {
    address payable public admin;
  
    
    constructor(address payable _admin) {
        admin = _admin;
    }
    

    function setAdmin(address payable newAdmin) onlyBy(admin) public virtual {
        admin = newAdmin;
    }
   
    
    function withdrawToken(IERC20 token, uint256 amount) onlyBy(admin) public virtual {
        require(!canControl(token), "Withdrawal not allowed.");
        // we don't need to check transfer's return value.
        if (address(token) == address(0))
            admin.transfer(amount);
        else
            token.transfer(admin, amount);
    }
    
 
    function canControl(IERC20) public view override virtual returns (bool) {
        return false;
    }
}