// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.8.0;


import "./AccessControlled.sol";
import "./Tools.sol";


contract Administered is AccessControlled {
    address payable public admin;
  

    event AdminChanged(address newAdmin);


    constructor(address payable _admin) {
        admin = _admin;
    }
    

    function setAdmin(address payable newAdmin) onlyBy(admin) public virtual {
        admin = newAdmin;
        emit AdminChanged(newAdmin);
    }


    /**
     * This method withdraws any ERC20 token or Ethers that belongs to this contract address and the contract is unable
     * to control them. Main usage of this method is for recovering trapped funds in the contract address. Withdrawal
     * will be rejected if `canControl` returns true for the input `token`.
     *
     * Only `admin` can call this method.
     * 
     * @param token is the address of the ERC20 contract that you want to withdraw from the contract's
     * address. Use `address(0)` to withdraw Ether.
     * @param amount is the raw amount to withdraw.
     */
    function recoverFunds(IERC20 token, uint256 amount) onlyBy(admin) public virtual {
        require(!canControl(token), "withdrawal not allowed");
        // we don't need to check transfer's return value.
        if (address(token) == address(0))
            admin.transfer(amount);
        else
            token.transfer(admin, amount);
    }


    /**
     * Returns ture if the contract is able to control its balance in the specified ERC20 'token'. If this function
     * returns true for a token, it means the contract is aware of its balance in `token` and that token can not
     * be withdrawn by `recoverFunds` function. `address(0)` indicates Ether.
     *
     * @param `` is the ERC20 contract address of the token you want to check. Use `address(0)` to check if the
     * contract is able to control its Ether balance.
     */
    function canControl(IERC20) public view virtual returns (bool) {
        return false;
    }
}
