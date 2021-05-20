// SPDX-License-Identifier: AGPL-3.0-only


pragma solidity ^0.8.0;


import "./../utils/Administered.sol";


contract CrowdFunding is ERC20, Administered {
    using Rational for RationalNumber;
    
    
    CrowdFundingConfig public config;
    address immutable public beneficiary;
    uint immutable public redemptionEndTime;
    bool public raisedInitialFund = false;

   
    event Redeemed(address recipient, uint256 amountSent, uint256 amountReceived);
    event Sold(address recipient, uint256 amount);
    event Converted(address sender, uint256 amount);
    
    
    constructor(address payable _admin, address _beneficiary, CrowdFundingConfig memory _config)
    ERC20(_config.name, _config.symbol)
    Administered(_admin) {
        config = validate(_config);
        beneficiary = _beneficiary;
        redemptionEndTime = block.timestamp + _config.redemptionDuration;
        _mint(address(this), _config.totalSupply);
    }
    
    
    function canControl(IERC20 token) public view override virtual returns (bool) {
        return token == this || token == config.fiatTokenContract; 
    }
    
    /**
     * Calculates the amount of `config.fiatTokenContract` tokens that a user will receive if he redeems
     * `amount` amount of ICO tokens. This amount depends directly on the current available funds in the 
     * contract address, but it is guaranteed to be higher than certain thresholds as described in 
     * `buy` function.
     */
    function calculateRefund(uint amount) public view returns (uint) {
        address me = address(this);
        uint circulation = totalSupply() - balanceOf(me);
       
        // It's important that we always calculate the refund amount based on our actual FIAT balance.
        // we use floor() to make sure that the calculation error loss is incurred to the user and not the system.
        uint possibleRefund = RationalNumber(amount * config.fiatTokenContract.balanceOf(me), circulation).floor();
        
        // Because some tokens may be burnt it's possible that the redemption price for tokens goes higher than the
        // initial price. We will not let that happen and at max we will refund the paid fiat for any amount of
        // redeemed tokens.
        uint paidFiat = config.price.mul(amount).floor();
        return min(possibleRefund, paidFiat);
    }
    
    /**
     * With this method the sender can buy ICO tokens:`this.name`, which is convertible to `config.originalToken` 
     * in 1:1 ratio. Before calling this function the sender needs to approve the transferring of at least 
     * `amount * config.price.a / config.price.b` amount of the `config.fiatTokenContract` token. He needs
     * to have this amount of `config.fiatTokenContract` tokens in his account.
     * 
     * A user can redeem his purchased tokens by sending them to the address of this contract:`address(this)`.
     * The redemption price depends on the state of the ICO. If the ICO has not yet raised the initial amount
     * of funds the tokens will be redeemable at the price of purchase. If the ICO has raised the initial
     * amount of funds, then the redemption price will be `config.redemptionRatio.a / config.redemptionRatio.b` 
     * of the purchased price. This redemption price is guaranteed till the `redemptionEndTime`.
     * 
     * Also a user can send his purchased ICO tokens to the address of the original token:`config.originalToken`.
     * By doing so, the user's ICO tokens will be burnt and converted to the original token. original tokens are 
     * not redeemable.
     * 
     * @param amount of ICO token to purchase at price: `config.price.a / config.price.b`
     */
    function buy(uint256 amount) public {
        // We use ceil() to make sure the calculation error is only making our tokens more expensive and we are not
        // giving discount to the user. Otherwise, an attacker may be able to use this error to make money from the system.
        uint256 fiatAmount = config.price.mul(amount).ceil();
        
        // we assume that `fiatTokenContract` is a trusted ERC20 contract. Anyway, re-entrance will only cause the sender
        // to send more fiat tokens.
        bool success = config.fiatTokenContract.transferFrom(msg.sender, address(this), fiatAmount);
        require(success, "error in payment");

        this.transfer(msg.sender, amount);
        
        // canWithdraw only changes once. when it becomes true it must remain true. We first check to see if it's not
        // true then we check the condition. this will reduce gas consumption.
        if (!raisedInitialFund) {
            raisedInitialFund = (config.fiatTokenContract.balanceOf(address(this)) >= config.minFiatForActivation);
        }
        emit Sold(msg.sender, amount);
    }
    
    /**
     * This method withdraws the requested `amount` of funds to the beneficiary address:`beneficiary'.
     * This will essentially decrease the redemption price of ICO tokens. However, the amount of
     * withdrawal is limited to make sure the configured redemption policy will not be violated. 
     * Any one may call this method.
     */ 
    function withdraw(uint256 amount) public {
        require(raisedInitialFund, "withdrawals are not yet allowed");
        // anyone can request withdrawals.
       
        if (block.timestamp <= redemptionEndTime) {
            uint256 circulation = totalSupply() - balanceOf(address(this));
            uint256 fiatThreshold = config.price.mul(config.redemptionRatio.mul(circulation).floor()).floor();
            uint256 balance = config.fiatTokenContract.balanceOf(address(this));
            require(balance - amount >= fiatThreshold, "amount is too high");
        } 

        bool success = config.fiatTokenContract.transfer(beneficiary, amount);
        require(success, "error in transfer");
    }
    
  
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (recipient == address(config.originalToken)) {
            _burn(sender, amount);
            config.originalToken.mint(sender, amount);
            emit Converted(sender, amount);
        } else if (recipient == address(this)) {
            // user wants to redeem his tokens.
            // we need to calculate the fiat refund amount before we transfer user's tokens.
            uint256 fiatRefund = calculateRefund(amount);
            require(fiatRefund > 0, "refund value is zero");
            
            super._transfer(sender, recipient, amount);
            
            // reentrancy will only cause the sender to redeem more tokens.
            bool success = config.fiatTokenContract.transfer(sender, fiatRefund);
            require(success, "error in FIAT transfer");
            emit Redeemed(sender, amount, fiatRefund);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }
}


// we've arranged the variables in a way that they can be easily packed in 256 bit buckets.
struct CrowdFundingConfig {
    string name;
    string symbol;
    uint redemptionDuration;
    uint minFiatForActivation;
    uint totalSupply;
    RationalNumber redemptionRatio;
    RationalNumber price;
    IERC20 fiatTokenContract;
    MintableToken originalToken;
}


// Helper function for validating CrowdFunding configurations
function validate(CrowdFundingConfig memory conf) pure returns (CrowdFundingConfig memory) {
    require(
        conf.redemptionDuration >= 3 days && conf.redemptionDuration <= 1095 days,
        "redemption duration must be between 3 days and 3 years"
    );
    require(conf.price.a > 0, "price can't be zero");
    require(
         conf.minFiatForActivation < Rational.floor(Rational.mul(conf.price, conf.totalSupply / 2)),
         "minFiatForActivation is too high"
    );
    // require  0.1 < redemptionRatio < 1
    require(
        Rational.ceil(Rational.mul(conf.redemptionRatio, 10 * INVERTED_PRECISION)) < 10 * INVERTED_PRECISION,
        "invalid redemption ratio"
    );
    return conf;
}
