// SPDX-License-Identifier: AGPL-3.0-only


pragma solidity ^0.8.0;


import "./../utils/Administered.sol";


interface StakeToken is IERC20 {
    function isExcludedFromProfits(address account) external view returns (bool);
}


uint8 constant MAX_SOURCE_COUNT = 32;


/**
 * @title An ERC20 token representing a share which is eligible to receive profits
 * @author aybehrouz
 * This token represents a share in some entity which entitles the owners to receive profits. Multiple ERC20
 * tokens could be defined as profit sources by `registerProfitSource` method. When any amount of these
 * registered tokens is sent to the address of this ERC20 contract, it will be distributed between holders of
 * this token. The amount of received profit will be proportional to the balance of a user relative to
 * the total supply of the token.
 */
abstract contract DistributorERC20 is StakeToken, ERC20, Administered {
    using ProfitTracker for ProfitSource; 
    
    
    ProfitSource[] public trackers;
    mapping(address => bool) private isExcluded;
    bool public finalProfitSources = false;


    event ProfitSent(address recipient, uint amount, IERC20 token);
    event ProfitSourceRegistered(IERC20 token, uint sourceIndex);


    /**
     * Registers a new profit source which must be an ERC20 token. After registration, the balance of the contract
     * in the registered ERC20 token will be considered as the profit of shareholders, and it will be
     * distributed between share holders.
     *
     * Only `admin` can call this method. If the profit sources are finalized this method will fail.
     *
     * @return sourceIndex which is the index of the registered profit source which acts as an identifier of the source,
     * and is used as `sourceIndex` parameter of several other methods of this contract.
     */
    function registerProfitSource(IERC20 tokenContract) onlyBy(admin) public returns(uint sourceIndex) {
        require(!finalProfitSources, "profit sources are final");
        // admin must NOT add a token that already exists in this list.
        require(!canControl(tokenContract), "already registered");
        // we make sure the source has balanceOf function.
        tokenContract.balanceOf(address(this));
        ProfitSource storage newSource = trackers.push();
        newSource.fiatToken = tokenContract;
        newSource.stakeToken = this;
        require(trackers.length <= MAX_SOURCE_COUNT, "max source count reached");
        emit ProfitSourceRegistered(tokenContract, trackers.length - 1);
        return trackers.length - 1;
    }


    /**
     * Finalizes the ERC20 profit sources of the contract. After calling this method no new profit sources can be
     * registered, and `registerProfitSource` will always fail.
     */
    function finalizeProfitSources() onlyBy(admin) public {
        finalProfitSources = true;
    }


    /**
     * This function is intended for registering addresses of smart contracts that are unable to withdraw profits.
     * Address of liquidity pools or exchanges should be registered by this function to make sure their received profits
     * are not lost. An excluded account is still able to withdraw its profits.
     *
     * When an account is excluded from profits, it can not be removed from the exclusion list later. Only `admin`
     * can call this method. Since excluded accounts are still able to withdraw their profits, this function does not
     * give too much power to an admin.
     */
    function excludeFromProfits(address account) onlyBy(admin) public {
        isExcluded[account] = true;
    }


    /**
     * Gets the available balance of profits that `account` has in the ERC20 token specified by `sourceIndex`. This
     * amount could be withdrawn by using `withdrawProfit` method.
     * 
     * @param sourceIndex is the index of the ERC20 token in the `trackers` list.
     * @return the total amount of gained profit.
     */
    function balanceOfProfit(address account, uint8 sourceIndex) public view returns (uint) {
        return trackers[sourceIndex].profitBalance(account);
    }


    /**
     * Withdraws the requested `amount` of the sender's profit in the ERC20 token specified by `sourceIndex`.
     * 
     * @param sourceIndex is the index of the ERC20 token in the `trackers` list.
     */
    function withdrawProfit(uint256 amount, uint8 sourceIndex) public {
        trackers[sourceIndex].withdrawProfit(msg.sender, amount);
        emit ProfitSent(msg.sender, amount, trackers[sourceIndex].fiatToken);
    }

    /**
     * @inheritdoc Administered
     */
    function canControl(IERC20 token) public view override virtual returns (bool) {
        for (uint i = 0; i < trackers.length; i++) {
            if (trackers[i].fiatToken == token)
                return true;
        }
        return false;
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
    StakeToken stakeToken;
    uint withdrawalSum;
}


uint8 constant DELTAS_SHIFT = 36;
uint constant PROFIT_DISTRIBUTION_THRESHOLD = 1e9;
uint constant MAX_TOTAL_PROFIT = 2 ** 160 - 1;


library ProfitTracker {
    using Rational for RationalNumber;
    
    // If newly minted stakes (tokens) should not get any shares from previously gained profits, this function should
    // be called before updating the total stake when minting new tokens, and the sender address should be an address
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
        // the cast to int is safe as long as self.stakeToken.totalSupply() > 2
        self.profitDeltas[sender] += int(profit.floor());
        self.profitDeltas[recipient] -= int(profit.ceil());

        // When an account which is excluded from profits, tries to transfer his stake, we essentially withdraw
        // the positive profit of that transferred stake (if any) and then deposit it back to the profit pool.
        // This simple method is very useful, specially when new tokens is minted, and we want to make sure the
        // newly minted tokens will not get any shares from the previous profits.
        if (self.stakeToken.isExcludedFromProfits(sender) && self.profitDeltas[sender] > 0) {
            // the cast is safe
            self.withdrawalSum += uint(self.profitDeltas[sender]) >> DELTAS_SHIFT;
            self.profitDeltas[sender] = 0;
        }
    }


    function profitBalance(ProfitSource storage self, address recipient) internal view returns (uint) {
        uint userBalance = self.stakeToken.balanceOf(recipient);
        // the cast to int is safe as long as self.stakeToken.totalSupply() > 2
        int rawProfit = int(_tokensGainedProfitShifted(self, userBalance).floor()) + self.profitDeltas[recipient];
        if (rawProfit < 0)
            rawProfit = 0;
        // now that rawProfit >= 0 the conversion from int to uint is safe.
        return uint(rawProfit) >> DELTAS_SHIFT;
    }
    
    
    function withdrawProfit(ProfitSource storage self, address recipient, uint amount) internal {
        require(amount <= profitBalance(self, recipient), "profit balance is not enough");
        // this cast is tricky but it's safe because the amount is lower than profit balance.
        self.profitDeltas[recipient] -= int(amount) << DELTAS_SHIFT;
        self.withdrawalSum += amount;
        
        // we assume fiatToken is a trusted contract, however reentrancy will not cause the `msg.sender` to
        // withdraw more than `profitBalance(msg.sender)`.
        bool success = self.fiatToken.transfer(recipient, amount);
        require(success, "error in token transfer");
    }

    // we should not let this function fail due to an overflow.
    function _tokensGainedProfitShifted(ProfitSource storage self, uint tokenAmount)
    private view returns (RationalNumber memory) {
        // We have not changed the state of our contract yet, so reentrancy in this external call is safe and would be
        // like a normal call to another function of the contract.
        // We should not let this function fail due to an error in the external call as much as possible. However
        // high gas consumption in the external call would be still an issue and could make our token unusable.
        uint totalGained;
        try self.fiatToken.balanceOf(address(this)) returns (uint fiatBalance) {
            // we need to prevent overflows
            if (fiatBalance >= MAX_TOTAL_PROFIT / 2) {
                totalGained = MAX_TOTAL_PROFIT / 2;
            }
            else {
                totalGained = fiatBalance;
            }
        } catch {
            totalGained = 0;
        }
        // prevent overflows
        if (self.withdrawalSum >= MAX_TOTAL_PROFIT / 2) {
            totalGained += MAX_TOTAL_PROFIT / 2;
        }
        else {
            totalGained += self.withdrawalSum;
        }
        if (totalGained < PROFIT_DISTRIBUTION_THRESHOLD)
            return RationalNumber(0, 1);

        // first we need to convert the unit of our total gained profit into deltas unit.
        totalGained = totalGained << DELTAS_SHIFT;
        // an overflow here will prevent the token transfer.
        return RationalNumber(tokenAmount * totalGained, self.stakeToken.totalSupply());
    }
}
