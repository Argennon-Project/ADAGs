// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.8.0;


import "./../utils/Administered.sol";


interface StakeRegistry {
    function stakeOf(address account) external view returns (uint);
    function totalStake() external view returns (uint);
    function isExcludedFromProfits(address account) external view returns (bool);
}


/**
 * @title A token representing a share which is eligible to receive profits
 * @author aybehrouz
 * This token represents a share in some entity which entitles the owners to receive profits. Multiple ERC20
 * tokens could be defined as profit sources by `registerProfitSource` method. When any amount of these
 * registered tokens is sent to the address of this ERC20 contract, it will be distributed between holders of
 * this token. The amount of received profit will be proportional to the balance of a user relative to
 * the total supply of the token.
 */
abstract contract DistributorERC20 is StakeRegistry, ERC20, Administered {
    using ProfitTracker for ProfitSource; 
    
    
    ProfitSource[] public trackers;
    mapping(address => bool) private isExcluded;


    event ProfitSent(address recipient, uint amount, IERC20 token);


    /**
     * Registers a new profit source which must be an ERC20 contract. After registration, the balance of this contract
     * address in the registered ERC20 token will be considered the profit of shareholders, and it will be distributed
     * between holders of this token.
     *
     * Only `admin` can call this method.
     *
     * @return sourceIndex which is the index of the registered profit source which acts as an identifier of the source,
     * and is used as `sourceIndex` parameter of several other methods of this contract.
     */
    function registerProfitSource(IERC20 tokenContract) onlyBy(admin) public returns(uint sourceIndex) {
        // admin must NOT add a token that already exists in this list.
        require(!canControl(tokenContract), "already registered");
        ProfitSource storage newSource = trackers.push();
        newSource.fiatToken = tokenContract;
        newSource.stakeRegistry = this;
        return trackers.length - 1;
    }


    /**
     * This function is intended for registering addresses of smart contracts that are unable to withdraw profits.
     * Address of liquidity pools or exchanges should be registered by this function to make sure their received profits
     * are not lost.
     *
     * When an account is excluded from profits, it can not be re-included later. Only `admin` can call this method.
     */
    function excludeFromProfits(address account) onlyBy(admin) public {
        isExcluded[account] = true;
    }


    /**
     * Gets the amount of profit that `account` has acquired in the ERC20 token specified
     * by `sourceIndex`.
     * 
     * @param sourceIndex is the index of the ERC20 token in the `trackers` list.
     * @return the total amount of gained profit.
     */
    function profit(address account, uint16 sourceIndex) public view returns (uint) {
        return trackers[sourceIndex].profitBalance(account);
    }


    /**
     * Withdraws the requested `amount` of the sender's profit in the token specified by `sourceIndex`
     * 
     * @param sourceIndex is the index of the ERC20 token in the `trackers` list.
     */
    function withdrawProfit(uint256 amount, uint16 sourceIndex) public {
        trackers[sourceIndex].withdrawProfit(msg.sender, amount);
        emit ProfitSent(msg.sender, amount, trackers[sourceIndex].fiatToken);
    }


    function canControl(IERC20 token) public view override virtual returns (bool) {
        for (uint i = 0; i < trackers.length; i++) {
            if (trackers[i].fiatToken == token)
                return true;
        }
        return false;
    }


    function stakeOf(address account) public view override virtual returns (uint) {
        return balanceOf(account);
    }


    function totalStake() public view override virtual returns (uint) {
        return totalSupply();
    }


    function isExcludedFromProfits(address account) public view override virtual returns (bool) {
        return account == address(0) || isExcluded[account];
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        for (uint i = 0; i < trackers.length; i++)
            trackers[i].transferStake(from, to, amount);
    }
}


struct ProfitSource {
    // profit[address] = balance * perTokenProfit + profitDeltas[address] / 2 ^ DELTAS_SHIFT 
    mapping(address => int) profitDeltas;
    IERC20 fiatToken;
    StakeRegistry stakeRegistry;
    uint withdrawalSum;
}


uint8 constant DELTAS_SHIFT = 36;
uint constant PROFIT_DISTRIBUTION_THRESHOLD = 1e9;


library ProfitTracker {
    using Rational for RationalNumber;
    
    // If newly minted stakes (tokens) should not get any shares from previously gained profits, when minting new tokens
    // this function should be called before updating the total stake, and the sender address should be an address
    // which is excluded from profits.
    function transferStake(ProfitSource storage self, address sender, address recipient, uint amount) internal {
        RationalNumber memory profit = _tokensGainedProfitShifted(self, amount);
        if (profit.a == 0)
            return;
        // It's very important that we do the rounding of numbers in a way that users do not get any extra profits.
        // Otherwise an attacker would be able to take advantage of calculation errors and drain all the profits of
        // the system by transferring a small amount of share repeatedly between multiple accounts.
        //
        // We've done the roundings in a way that in such a scenario the attacker will only burn his own profits.
        // However, still an attacker would able to burn another user's profits by repeatedly sending small amounts
        // of stake tokens to him.
        //
        // To mitigate this problem, we try to keep the calculation error as low as possible by preventing low amount
        // transfers. RationalNumber library stops a transfer when it detects that the calculation error is too high.
        //
        // When an account which is excluded from profits, tries to transfer his stake, we essentially withdraw his
        // profits and then deposit it back to the profit pool. This simple method is very useful, specially when
        // new tokens is minted, and we want to make sure the newly minted tokens will not get any shares from
        // previous profits.
        if (self.stakeRegistry.isExcludedFromProfits(sender)) {
            self.withdrawalSum += (profit.floor() >> DELTAS_SHIFT);
        } else {
            self.profitDeltas[sender] += int(profit.floor());
        }
        self.profitDeltas[recipient] -= int(profit.ceil());
    }


    function profitBalance(ProfitSource storage self, address recipient) internal view returns (uint) {
        uint userBalance = self.stakeRegistry.stakeOf(recipient);
        int rawProfit = int(_tokensGainedProfitShifted(self, userBalance).floor()) + self.profitDeltas[recipient];
        if (rawProfit < 0)
            rawProfit = 0;
        // now the conversion from int to uint is completely safe.
        return uint(rawProfit) >> DELTAS_SHIFT;
    }
    
    
    function withdrawProfit(ProfitSource storage self, address recipient, uint amount) internal {
        require(!self.stakeRegistry.isExcludedFromProfits(recipient), "account is excluded");
        require(amount <= profitBalance(self, recipient), "profit balance is not enough");
        self.profitDeltas[recipient] -= int(amount << DELTAS_SHIFT);
        self.withdrawalSum += amount;
        
        // we assume fiatToken is a trusted contract, however reentrancy will not cause the `msg.sender` to
        // withdraw more than `profitBalance(msg.sender)`.
        bool success = self.fiatToken.transfer(recipient, amount);
        require(success);
    }
    
    
    function _tokensGainedProfitShifted(ProfitSource storage self, uint tokenAmount)
    private view returns (RationalNumber memory) {
        require(tokenAmount < self.stakeRegistry.totalStake(), "amount is too high");
        
        uint totalGained = self.withdrawalSum + self.fiatToken.balanceOf(address(this));
        if (totalGained < PROFIT_DISTRIBUTION_THRESHOLD)
            return RationalNumber(0, 1);
       
        // first we need to convert the unit of our total gained profit into deltas unit.
        totalGained = totalGained << DELTAS_SHIFT;
        
        return RationalNumber(tokenAmount * totalGained, self.stakeRegistry.totalStake());
    }
}