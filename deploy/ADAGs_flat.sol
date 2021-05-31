// SPDX-License-Identifier: AGPL-3.0-only


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}



pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}




pragma solidity ^0.8.0;









interface PossessiveContract {
    function canControl(IERC20 token) external view returns(bool);
    function setAdmin(address payable newAdmin) external;
    function admin() external view returns(address payable);
}


interface LockableToken is IERC20Metadata {
    struct LockInfo {
        uint128 amount;
        uint128 releaseTime;
    }
    function locked(address account) external returns(LockInfo memory);
}


interface MintableToken is IERC20Metadata {
    function mint(address recipient, uint amount) external;
    function increaseMintingAllowance(address minter, uint amount) external;
    function setOwner(address newOwner) external;
}


interface LockableMintable is MintableToken, LockableToken, PossessiveContract {}


uint constant INVERTED_PRECISION = 1e8;


struct RationalNumber {
    uint a;
    uint b;
}


library Rational {
    function mul(RationalNumber memory self, uint m) internal pure returns(RationalNumber memory) {
        return RationalNumber(self.a * m, self.b);
    }
    
    
    function floor(RationalNumber memory self) internal pure returns(uint) {
        return _round(self, true);
    }
    
    
    function ceil(RationalNumber memory self) internal pure returns(uint) {
        return _round(self, false);
    }
    
    
    function _round(RationalNumber memory self, bool down) private pure returns(uint) {
        uint q = self.a / self.b;
        uint r = self.a - self.b * q;
        if (r == 0)
            return q;
            
        if (down) {
            require(self.a / r > INVERTED_PRECISION, "not enough precision");
            return q;
        }
        require(self.a / (self.b - r) > INVERTED_PRECISION, "not enough precision");
        return q + 1;
    }
}


function min(uint a, uint b) pure returns (uint) {
    return a <= b ? a : b; 
}




pragma solidity ^0.8.0;



abstract contract AccessControlled {
     modifier onlyBy(address user) { require(msg.sender == user, "sender not authorized"); _; }
     modifier onlyBefore(uint timestamp) { require(block.timestamp <= timestamp, "too late"); _; }
     modifier onlyAfter(uint timestamp) { require(block.timestamp > timestamp, "too early"); _; }
}




pragma solidity ^0.8.0;




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
     * @param token is the address of the ERC20 token contract that you want to withdraw from the contract's
     * address. Use `address(0)` to withdraw Ether.
     * @param amount is the raw amount to withdraw.
     */
    function recoverFunds(IERC20 token, uint256 amount) onlyBy(admin) public virtual {
        require(!canControl(token), "withdrawal not allowed");
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




pragma solidity ^0.8.0;



contract Ballot is Administered {
    mapping(address => uint) public votes;
    uint public totalWeight;
    uint immutable public endTime;
    uint immutable public lockTime;
    address immutable public parent = msg.sender;
    LockableToken immutable public votingToken;


    event Voted(address account, uint weight, uint total);
    event Destroyed(Ballot ballot);
    
    
    constructor(address payable _admin, LockableToken _votingToken, uint _endTime, uint _lockTime)
    Administered(_admin) {
        votingToken = _votingToken;
        lockTime = _lockTime;
        endTime = _endTime;
        require(block.timestamp < _endTime && _endTime < _lockTime, "ballot dates are invalid");
    }
    
    
    function changeVoteTo(uint weight) onlyBefore(endTime) public  {
        require(votingToken.locked(msg.sender).amount >= weight, "locked amount not enough");
        require(votingToken.locked(msg.sender).releaseTime >= lockTime, "lock period is too short");
        totalWeight -= votes[msg.sender];
        totalWeight += weight;
        votes[msg.sender] = weight;
        emit Voted(msg.sender, weight, totalWeight);
    }
    
    
    function destroy() public onlyBy(parent) {
        emit Destroyed(this);
        selfdestruct(admin);
    }
}




pragma solidity ^0.8.0;



struct TokenSaleConfig {
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


function validate(TokenSaleConfig memory conf) pure returns (TokenSaleConfig memory) {
    require(
        conf.redemptionDuration <= 1095 days,
        "redemption duration must be less than 3 years"
    );
    require(conf.price.a > 0, "price can't be zero");
    require(
        conf.minFiatForActivation < Rational.floor(Rational.mul(conf.price, conf.totalSupply / 2)),
        "minFiatForActivation is too high"
    );
    require(
        conf.redemptionRatio.b != 0 &&
        conf.redemptionRatio.b >= conf.redemptionRatio.a &&
        conf.redemptionRatio.b <= 10 * conf.redemptionRatio.a,
        "invalid redemption ratio"
    );
    return conf;
}


contract TokenSale is ERC20, Administered {
    using Rational for RationalNumber;
    
    
    TokenSaleConfig public config;
    address immutable public beneficiary;
    uint immutable public redemptionEndTime;
    bool public activationThresholdReached = false;

   
    event Redeemed(address recipient, uint256 amountSent, uint256 amountReceived);
    event Sold(address recipient, uint256 amount);
    event Converted(address sender, uint256 amount);
    
    
    constructor(address payable _admin, address _beneficiary, TokenSaleConfig memory _config)
    ERC20(_config.name, _config.symbol)
    Administered(_admin) {
        config = validate(_config);
        beneficiary = _beneficiary;
        redemptionEndTime = block.timestamp + _config.redemptionDuration;
        _mint(address(this), _config.totalSupply);
    }


    function decimals() public view override returns (uint8) {
        return config.originalToken.decimals();
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
       
        uint possibleRefund = RationalNumber(amount * config.fiatTokenContract.balanceOf(me), circulation).floor();
        
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
        uint256 fiatAmount = config.price.mul(amount).ceil();
        
        bool success = config.fiatTokenContract.transferFrom(msg.sender, address(this), fiatAmount);
        require(success, "error in payment");

        this.transfer(msg.sender, amount);
        
        if (!activationThresholdReached) {
            activationThresholdReached = (config.fiatTokenContract.balanceOf(address(this)) >= config.minFiatForActivation);
        }
        emit Sold(msg.sender, amount);
    }
    
    /**
     * This method withdraws the requested `amount` of funds to the beneficiary address:`beneficiary'.
     * This will essentially decrease the redemption price of ICO tokens. However, the amount of
     * withdrawal is limited, In order to make sure the configured redemption policy will not be violated.
     *
     * Any one may call this method.
     */
    function withdraw(uint amount) public {
        if (block.timestamp <= redemptionEndTime) {
            uint circulation = totalSupply() - balanceOf(address(this));

            uint fiatThreshold;
            if (activationThresholdReached)
                fiatThreshold = config.price.mul(config.redemptionRatio.mul(circulation).floor()).floor();
            else
                fiatThreshold = config.price.mul(circulation).floor();

            uint balance = config.fiatTokenContract.balanceOf(address(this));
            require(balance >= fiatThreshold + amount, "amount is too high");
        }
        config.fiatTokenContract.transfer(beneficiary, amount);
    }
    
  
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (recipient == address(config.originalToken)) {
            _burn(sender, amount);
            config.originalToken.mint(sender, amount);
            emit Converted(sender, amount);
        } else if (recipient == address(this)) {
            uint256 fiatRefund = calculateRefund(amount);

            super._transfer(sender, recipient, amount);
            
            bool success = config.fiatTokenContract.transfer(sender, fiatRefund);
            require(success, "error in FIAT transfer");
            emit Redeemed(sender, amount, fiatRefund);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }
}




pragma solidity ^0.8.0;





uint constant MIN_LOCK_DURATION = 120 days;
uint constant MAX_LOCK_DURATION = 540 days;
uint constant MIN_MAJORITY_PERCENT = 55;
uint constant MAX_MAJORITY_PERCENT = 80;
uint constant MAX_PROPOSAL_FEE = 5e17;


struct VotingConfig {
    uint64 proposalFee;
    uint56 lockDuration;
    uint8 majorityPercent;
}


function validate(VotingConfig memory config) pure returns (VotingConfig memory) {
    require(
        config.majorityPercent >= MIN_MAJORITY_PERCENT &&
        config.majorityPercent <= MAX_MAJORITY_PERCENT,
        "invalid majority percent"
    );
    require(
        config.lockDuration >= MIN_LOCK_DURATION &&
        config.lockDuration <= MAX_LOCK_DURATION,
        "invalid lock duration"
    );
    require(config.proposalFee <= MAX_PROPOSAL_FEE, "proposal fee is too high");
    return config;
}


contract GovernanceSystem is AccessControlled {
    struct GovernanceAction {
        bool active;
        function(bytes storage, bool) internal action;
        bytes data;
    }


    address payable public admin;
    VotingConfig public votingConfig;
    LockableMintable public governanceToken;
    TokenSale[] public tokenSales;
    mapping(Ballot => GovernanceAction) internal proposals;


    event DecodedCreateTokenSale(TokenSaleConfig tsConfig, address beneficiary);
    event DecodedApproveMinter(address minter, uint amount);
    event DecodedMint(address recipient, uint amount);
    event DecodedGovernanceChange(address newGovernanceSystem);
    event DecodedGrant(address payable recipient, uint amount, IERC20 token);
    event DecodedChangeOfSettings(address payable newAdmin, VotingConfig newVotingConfig);
    event DecodedAdminReset(Administered target, address payable admin);

    event TokenSaleCreated(TokenSale newTs);
    event GovernanceSystemChanged(address newGovernanceSystem);
    event GrantGiven(address payable recipient, uint amount, IERC20 token);
    event SettingsChanged(address payable newAdmin, VotingConfig newVotingConfig);
    event AdminReset(Administered target, address payable admin);

    event PaymentReceived(address sender, uint amount);
    event BallotCreated(Ballot newBallot, uint endTime);


    modifier authenticate(Ballot b) {require(proposals[b].active, "ballot not found"); _;}


    constructor(
        address payable _admin,
        LockableMintable _governanceToken,
        VotingConfig memory _votingConfig
    ) {
        admin = _admin;
        governanceToken = _governanceToken;
        votingConfig = validate(_votingConfig);
    }


    /**
     * An attacker may be able to fool voters to vote for his ballot by giving wrong information about what the
     * ballot is really about. To protect users, the data of a ballot could be decoded by this function and user
     * could verify what action the ballot will perform if it is accepted.
     */
    function DecodeBallotAction(Ballot ballot) authenticate(ballot) public {
        proposals[ballot].action(proposals[ballot].data, true);
    }


    function verifyOwnership() public {
        governanceToken.setOwner(address(this));
    }


    function executeProposal(Ballot ballot) authenticate(ballot) onlyAfter(ballot.endTime()) public {
        proposals[ballot].active = false;
        if (_isMajority(ballot.totalWeight())) {
            proposals[ballot].action(proposals[ballot].data, false);
        }
        delete proposals[ballot];
        ballot.destroy();
    }


    function proposeTokenSale(TokenSaleConfig calldata config, bool governorIsBeneficiary, uint ballotEndTime)
    public payable returns (Ballot b) {
        config.originalToken.increaseMintingAllowance(address(this), 0);
        address beneficiary;
        if (governorIsBeneficiary) {
            beneficiary = address(this);
        } else {
            require(
                governanceToken.canControl(config.fiatTokenContract),
                "governance token does not support fiatToken"
            );
            beneficiary = address(governanceToken);
        }
        b = _newBallot(ballotEndTime);
        _saveProposal(b, _createTokenSale, abi.encode(validate(config), beneficiary));
    }


    function proposeGrant(address payable recipient, uint amount, IERC20 token, uint ballotEndTime)
    public payable returns (Ballot b) {
        b = _newBallot(ballotEndTime);
        _saveProposal(b, _grant, abi.encode(recipient, amount, token));
    }


    function proposeChangeOfSettings(address payable newAdmin, VotingConfig calldata newVotingConfig, uint ballotEndTime)
    public payable returns (Ballot b) {
        require(newAdmin != address(this), "admin can not be the contract itself");
        b = _newBallot(ballotEndTime);
        _saveProposal(b, _changeSettings, abi.encode(newAdmin, validate(newVotingConfig)));
    }
    
    
    function proposeMintApproval(address minter, uint amount, uint ballotEndTime)
    public payable returns (Ballot b) {
        b = _newBallot(ballotEndTime);
        _saveProposal(b, _approveMinter, abi.encode(minter, amount));
    }


    function proposeMinting(address recipient, uint amount, uint ballotEndTime)
    public payable returns (Ballot b) {
        b = _newBallot(ballotEndTime);
        _saveProposal(b, _mint, abi.encode(recipient, amount));
    }


    function proposeAdminReset(Administered target, uint ballotEndTime)
    public payable returns(Ballot b) {
        require(target.admin() == address(this), "admin of target is not this contract");
        b = _newBallot(ballotEndTime);
        _saveProposal(b, _resetAdmin, abi.encode(target));
    }

    
    function proposeNewGovernor(address payable newGovernor, uint ballotEndTime) onlyBy(admin)
    public payable returns (Ballot b) {
        b = _newBallot(ballotEndTime);
        _saveProposal(b, _retire, abi.encode(newGovernor));
    }


    receive() external virtual payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

   
    function _isMajority(uint weight) internal view returns(bool) {
        return 100 * weight > votingConfig.majorityPercent * governanceToken.totalSupply();
    }
    
    
    function _saveProposal(
        Ballot b,
        function(bytes storage, bool) internal action,
        bytes memory data
    ) internal {
        proposals[b].data = data; 
        proposals[b].action = action;
        proposals[b].active = true;
    }
    
   
    function _newBallot(uint ballotEndTime) internal returns(Ballot b) {
        require(msg.value >= votingConfig.proposalFee, "proposal fee was not paid");
        uint lockTime = ballotEndTime + votingConfig.lockDuration;
        b = new Ballot(admin, governanceToken, ballotEndTime, lockTime);
        emit BallotCreated(b, ballotEndTime);
    }


    function _createTokenSale(bytes storage data, bool isForCheck) internal {
        (TokenSaleConfig memory tsConfig, address beneficiary) = abi.decode(data, (TokenSaleConfig, address));
        if (isForCheck) {
            emit DecodedCreateTokenSale(tsConfig, beneficiary);
            return;
        }
        TokenSale newTs = new TokenSale(admin, beneficiary, tsConfig);
        tsConfig.originalToken.increaseMintingAllowance(address(newTs), tsConfig.totalSupply);
        tokenSales.push(newTs);
        emit TokenSaleCreated(newTs);
    }


    function _approveMinter(bytes storage data, bool isForCheck) internal {
        (address minter, uint amount) = abi.decode(data, (address, uint));
        if (isForCheck) {
            emit DecodedApproveMinter(minter, amount);
            return;
        }
        governanceToken.increaseMintingAllowance(minter, amount);
    }


    function _mint(bytes storage data, bool isForCheck) internal {
        (address recipient, uint amount) = abi.decode(data, (address, uint));
        if (isForCheck) {
            emit DecodedMint(recipient, amount);
            return;
        }
        governanceToken.mint(recipient, amount);
    }
    
    
    function _retire(bytes storage data, bool isForCheck) internal {
        address payable newSystem = abi.decode(data, (address));
        if (isForCheck) {
            emit DecodedGovernanceChange(newSystem);
            return;
        }
        governanceToken.setOwner(newSystem);
        if (governanceToken.admin() == address(this)) governanceToken.setAdmin(newSystem);
        emit GovernanceSystemChanged(newSystem);
        selfdestruct(newSystem);
    }


    function _grant(bytes storage data, bool isForCheck) internal{
        (address payable recipient, uint amount, IERC20 token) = abi.decode(data, (address, uint, IERC20));
        if (isForCheck) {
            emit DecodedGrant(recipient, amount, token);
            return;
        }
        if (address(token) == address(0)){
            recipient.transfer(amount);
        } else {
            bool success = token.transfer(recipient, amount);
            require(success, "error in token transfer");
        }
        emit GrantGiven(recipient, amount, token);
    }


    function _changeSettings(bytes storage data, bool isForCheck) internal {
        (address payable newAdmin, VotingConfig memory newVotingConfig) = abi.decode(data, (address, VotingConfig));
        if (isForCheck) {
            emit DecodedChangeOfSettings(newAdmin, newVotingConfig);
            return;
        }
        admin = newAdmin;
        votingConfig = newVotingConfig;
        emit SettingsChanged(newAdmin, newVotingConfig);
    }

    function _resetAdmin(bytes storage data, bool isForCheck) internal {
        Administered target = abi.decode(data, (Administered));
        if (isForCheck) {
            emit DecodedAdminReset(target, admin);
            return;
        }
        target.setAdmin(admin);
        emit AdminReset(target, admin);
    }
}




pragma solidity ^0.8.0;



uint56 constant INITIAL_LOCK_DURATION = 180 days;
uint64 constant INITIAL_PROPOSAL_FEE = 1e14;
uint8 constant INITIAL_MAJORITY_PERCENT = 66;


contract ADAGs is GovernanceSystem {
    constructor(address payable _admin, LockableMintable _argennonToken)
    GovernanceSystem(
        _admin,
        _argennonToken,
        VotingConfig({
            proposalFee : INITIAL_PROPOSAL_FEE,
            lockDuration : INITIAL_LOCK_DURATION,
            majorityPercent : INITIAL_MAJORITY_PERCENT
        })
    ) {}


    function createInitialCrowdfunding(TokenSaleConfig calldata config) onlyBy(admin) public {
        require(tokenSales.length == 0, "already created");
        TokenSale newTs = new TokenSale(admin, address(governanceToken), config);
        governanceToken.increaseMintingAllowance(address(newTs), config.totalSupply);
        tokenSales.push(newTs);
        emit TokenSaleCreated(newTs);
    }
}
