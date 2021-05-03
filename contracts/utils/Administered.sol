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
   
    /**
     * This method withraws any ERC20 tokens or Ethers that belongs to this contract and the contract is unable to
     * control them. Main usage of this method is for recovering trapped funds in the contract's address.
     * Only `admin` can call this method.
     * 
     * @param token is the address of the ERC20 token contract that you want to withdraw from the contract's
     * address. Use `address(0)` for this parameter to withdraw Ether.
     * @param amount is the raw amount to withdraw.
     */
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
