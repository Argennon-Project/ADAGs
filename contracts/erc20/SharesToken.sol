// SPDX-License-Identifier: 


pragma solidity ^0.8.0;


import "./../utils/Administered.sol";

/**
 * @title A token representing a share which is eligible to receive profits
 * @author aybehrouz
 * This token represents a share in some entity which entitles the owners to receive profits. Multiple ERC20
 * tokens could be defined as profit sources by `registerProfitSource` method. When Any amount of these
 * registered tokens is sent to the address of this ERC20 contract, it will be distributed between holders of
 * this token. The amount of received profit will be proportional to the balance of a user relative to
 * the total supply of the token.
 */
abstract contract SharesToken is ERC20, Administered {
    using ProfitTracker for ProfitSource; 
    
    
    ProfitSource[] public trackers;


    event ProfitSent(address recipient, uint amount, IERC20 token);
    
    
    function registerProfitSource(IERC20 tokenContract) onlyBy(admin) public returns(uint sourceIndex) {
        // admin must NOT add a token that already exists in this list.
        require(!canControl(tokenContract), "Already registered.");
        ProfitSource storage newSource = trackers.push();
        newSource.fiatToken = tokenContract;
        newSource.sharesToken = this;
        return trackers.length - 1;
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
    
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        super._transfer(sender, recipient, amount);
        for (uint i = 0; i < trackers.length; i++)
            trackers[i].transferShare(sender, recipient, amount);
    }
    
    
    function canControl(IERC20 token) public view override virtual returns (bool) {
        for (uint i = 0; i < trackers.length; i++) {
            if (trackers[i].fiatToken == token)
                return true;
        }
        return false;
    }
}


struct ProfitSource {
    // profit[address] = balance * perTokenProfit + profitDeltas[address] / 2 ^ DELTAS_SHIFT 
    mapping(address => int) profitDeltas;
    IERC20 fiatToken;
    IERC20 sharesToken;
    uint withdrawalSum;
}


uint8 constant DELTAS_SHIFT = 36;
uint constant PROFIT_DISTRIBUTION_THRESHOLD = 1e9;


library ProfitTracker {
    using Rational for RationalNumber;
    
     
    function transferShare(ProfitSource storage self, address sender, address recipient, uint amount) internal {
        RationalNumber memory profit = _tokensGainedProfitShifted(self, amount);
        if (profit.a == 0)
            return;
        // It's very important that we do the rounding of numbers in a way that users do not get any extra profits.
        // Otherwise an attacker would be able to drain all the profits of the system by transferring a small amount
        // of share repeatedly between his accounts and taking advantage of calculation errors.
        // We did the rounding in a way that in this scenario the attacker will only burn his own profits.
        // Still an attacker is able to burn another user's profits by repeatedly sending small amounts of share to him.
        // To mitigate this problem we try to keep the error of calculations low by stopping low transfers.
        // RationalNumber library stops a transfer when it detects that the error in calculation is too high.
        self.profitDeltas[sender] += int(profit.floor());
        self.profitDeltas[recipient] -= int(profit.ceil());
    }
    
    
    function profitBalance(ProfitSource storage self, address recipient) internal view returns (uint) {
        uint userBalance = self.sharesToken.balanceOf(recipient);
        int rawProfit = int(_tokensGainedProfitShifted(self, userBalance).floor()) + self.profitDeltas[recipient];
        if (rawProfit < 0)
            rawProfit = 0;
        // now the conversion from int to uint is completely safe.
        return uint(rawProfit) >> DELTAS_SHIFT;
    }
    
    
    function withdrawProfit(ProfitSource storage self, address recipient, uint amount) internal {
        require(amount <= profitBalance(self, recipient), "Profit balance is not enough.");
        self.profitDeltas[recipient] -= int(amount << DELTAS_SHIFT);
        self.withdrawalSum += amount;
        
        // we assume fiatToken is a trusted contract, however reentrancy will not cause the `msg.sender` to
        // withdraw more than `profitBalance(msg.sender)`.
        bool success = self.fiatToken.transfer(recipient, amount);
        require(success);
    }
    
    
    function _tokensGainedProfitShifted(ProfitSource storage self, uint tokenAmount)
    private view returns (RationalNumber memory) {
        require(tokenAmount < self.sharesToken.totalSupply(), "amount is too high.");
        
        uint totalGained = self.withdrawalSum + self.fiatToken.balanceOf(address(this));
        if (totalGained < PROFIT_DISTRIBUTION_THRESHOLD)
            return RationalNumber(0, 1);
       
        // first we need to convert the unit of our total gained profit into deltas unit.
        totalGained = totalGained << DELTAS_SHIFT;
        
        return RationalNumber(tokenAmount * totalGained, self.sharesToken.totalSupply());
    }
}