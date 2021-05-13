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
}


interface LockableToken {
    struct LockInfo {
        uint128 amount;
        uint128 releaseTime;
    }
    function locked(address account) external returns(LockInfo memory);
    function totalSupply() external view returns(uint256);
}


interface MintableToken {
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
        self.a = m * self.a;
        return self;
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



contract Owned is AccessControlled {
    address public owner;


    event OwnerChanged(address newOwner);


    constructor(address _owner) {
        owner = _owner;
    }
    
     
    function setOwner(address newOwner) onlyBy(owner) public virtual {
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }
    
}




pragma solidity ^0.8.0;



contract MintableERC20 is ERC20, Owned {
    uint immutable public slope;
    uint immutable public duration;
    uint immutable public startTime;
    uint immutable public initialMaxSupply;
    mapping(address => uint) public mintingAllowances;


    /**
     * The maximum allowed total supply of the created token will be controlled by a linear function of time. This
     * function is equal to `_initialMaxSupply` before `_startTime`. After `_startTime`, the maximum allowed total
     * supply will increase linearly from `_initialMaxSupply` to reach `_finalMaxSupply` after `_duration` of time.
     *
     * @param _owner is the owner of the token who is allowed to mint and give minting allowances.
     */
    constructor(address _owner,
        string memory _name, string memory _symbol, 
        uint _initialMaxSupply, uint _finalMaxSupply, uint _startTime, uint _duration
    )
    Owned(_owner)
    ERC20(_name, _symbol) {
        uint _slope = (_finalMaxSupply - _initialMaxSupply) / _duration;
        require(_slope > 0 || _initialMaxSupply == _finalMaxSupply, "bad inputs");

        startTime = _startTime;
        initialMaxSupply = _initialMaxSupply;
        duration = _duration;
        slope = _slope;
    }
    
    
    event MintingAllowanceIncreased(address minter, uint amount);


    /**
     * Returns the maximum allowed total supply of the token for the specified time. The maximum supply is an
     * increasing function of time. Exceeding allowed supply limit is impossible.
     *
     * @param timestamp is the time stamp in seconds as is in block.timestamp.
     */
    function maxAllowedSupply(uint timestamp) public view virtual returns (uint) {
        if (timestamp <= startTime)
            return initialMaxSupply;
        if (timestamp > duration + startTime)
            timestamp = duration + startTime;
        return slope * (timestamp - startTime) + initialMaxSupply;
    }


    /**
     * Adds `amount` to the minting allowance of the `minter`, and grants the allowance of minting `amount` more tokens
     * to the `minter` in addition to his previous allowance.
     * 
     * @param minter is the address who is allowed to mint tokens.
     * @param amount is the amount that the allowance will increase. This value will be added to the previous allowance.
     */
    function increaseMintingAllowance(address minter, uint amount) onlyBy(owner) public {
        mintingAllowances[minter] += amount;
        emit MintingAllowanceIncreased(minter, amount);
    }

  
    /**
     * Mints `amount` new tokens and sends it to `recipient`. Only `owner` can call this method or an address which
     * has enough minting allowance. Minting of the new tokens can not increase the total supply beyond the allowed
     * max supply.
     * 
     * @param recipient the address who will receive the new tokens.
     * @param amount the raw amount to be minted.
     */
    function mint(address recipient, uint amount) public {
        if (msg.sender != owner) {
            require(mintingAllowances[msg.sender] >= amount, "amount exceeds allowance");
            mintingAllowances[msg.sender] -= amount;
        }
        _mint(recipient, amount);
    }
    
    
    function _mint(address account, uint amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= maxAllowedSupply(block.timestamp), "totalSupply exceeds limit");
    }
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
     * @param token is the address of the ERC20 contract that you want to withdraw from the contract's
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


    /**
     * Registers a new profit source which must be an ERC20 contract. After registration, the balance of this contract
     * address in the registered ERC20 token will be considered the profit of shareholders, and it will be distributed
     * between holders of this token.
     *
     * Only `admin` can call this method. If the profit sources are finalized this method will fail.
     *
     * @return sourceIndex which is the index of the registered profit source which acts as an identifier of the source,
     * and is used as `sourceIndex` parameter of several other methods of this contract.
     */
    function registerProfitSource(IERC20 tokenContract) onlyBy(admin) public returns(uint sourceIndex) {
        require(!finalProfitSources, "profit sources are final");
        require(!canControl(tokenContract), "already registered");
        tokenContract.balanceOf(address(this));
        ProfitSource storage newSource = trackers.push();
        newSource.fiatToken = tokenContract;
        newSource.stakeToken = this;
        require(trackers.length <= MAX_SOURCE_COUNT, "max source count reached");
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
     * Gets the amount of profit that `account` has acquired in the ERC20 token specified by `sourceIndex`.
     * 
     * @param sourceIndex is the index of the ERC20 token in the `trackers` list.
     * @return the total amount of gained profit.
     */
    function profit(address account, uint8 sourceIndex) public view returns (uint) {
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
    mapping(address => int) profitDeltas;
    IERC20 fiatToken;
    StakeToken stakeToken;
    uint withdrawalSum;
}


uint8 constant DELTAS_SHIFT = 36;
uint constant PROFIT_DISTRIBUTION_THRESHOLD = 1e9;
uint constant MAX_TOTAL_PROFIT = 2 ** 160;

library ProfitTracker {
    using Rational for RationalNumber;
    
    function transferStake(ProfitSource storage self, address sender, address recipient, uint amount) internal {
        RationalNumber memory profit = _tokensGainedProfitShifted(self, amount);
        if (profit.a == 0)
            return;

        self.profitDeltas[sender] += int(profit.floor());
        self.profitDeltas[recipient] -= int(profit.ceil());

        if (self.stakeToken.isExcludedFromProfits(sender) && self.profitDeltas[sender] > 0) {
            self.withdrawalSum += uint(self.profitDeltas[sender]) >> DELTAS_SHIFT;
            self.profitDeltas[sender] = 0;
        }
    }


    function profitBalance(ProfitSource storage self, address recipient) internal view returns (uint) {
        uint userBalance = self.stakeToken.balanceOf(recipient);
        int rawProfit = int(_tokensGainedProfitShifted(self, userBalance).floor()) + self.profitDeltas[recipient];
        if (rawProfit < 0)
            rawProfit = 0;
        return uint(rawProfit) >> DELTAS_SHIFT;
    }
    
    
    function withdrawProfit(ProfitSource storage self, address recipient, uint amount) internal {
        require(amount <= profitBalance(self, recipient), "profit balance is not enough");
        self.profitDeltas[recipient] -= int(amount << DELTAS_SHIFT);
        self.withdrawalSum += amount;
        
        bool success = self.fiatToken.transfer(recipient, amount);
        require(success);
    }
    
    
    function _tokensGainedProfitShifted(ProfitSource storage self, uint tokenAmount)
    private view returns (RationalNumber memory) {
        uint totalGained;
        try self.fiatToken.balanceOf(address(this)) returns (uint fiatBalance) {
            totalGained = self.withdrawalSum + fiatBalance;
        } catch {
            totalGained = self.withdrawalSum;
        }
        if (totalGained < PROFIT_DISTRIBUTION_THRESHOLD || totalGained >= MAX_TOTAL_PROFIT)
            return RationalNumber(0, 1);
       
        totalGained = totalGained << DELTAS_SHIFT;
        return RationalNumber(tokenAmount * totalGained, self.stakeToken.totalSupply());
    }
}




pragma solidity ^0.8.0;



abstract contract LockableERC20 is ERC20 {
    struct Lock {
        uint128 threshold;
        uint128 releaseTime;
    }
    struct LockedTokens {
        uint128 amount;
        uint128 releaseTime;
    }
    
    
    /**
     * Returns the information of the defined lock for an address. An account can't transfer any tokens as long as
     * its balance is lower than `threshold` amount. The lock will be active till `releaseTime`, and it can not 
     * be canceled by any means. A lock can only be extended.
     */
    mapping(address => Lock) public locksData;
    
    
    event LockUpdated(address account, uint128 amount, uint128 releaseTime);


    /**
     * Returns the actual amount of tokens that are locked in an account till the release time. The balance of
     * `account` will always be higher than the locked amount. The release time may have been expired and should
     * always be checked.
     *
     * @return a `LockedTokens` struct which its first field is the amount of locked tokens and its second field
     * is the timestamp that the tokens will be unlocked after.
     */
    function locked(address account) public view returns(LockedTokens memory) {
        return LockedTokens({
            amount: uint128(min(balanceOf(account), locksData[account].threshold)),
            releaseTime: locksData[account].releaseTime
        });
    }
    
    
    /**
     * Extends the defined lock on your account. This operation is irreversible.
     * 
     * @param threshold is the maximum amount of locked tokens. When the balance of your account is higher than this
     * threshold, the extra token may be transferred.
     * @param releaseTime is the lock's release time. After this time the lock will be deactivated.
     */
    function setLock(uint128 threshold, uint128 releaseTime) public {
        _updateLock(msg.sender);
        require(
            threshold >= locksData[msg.sender].threshold &&
            releaseTime >= locksData[msg.sender].releaseTime,
            "locks can only be extended"
        );
        locksData[msg.sender].threshold = threshold;
        locksData[msg.sender].releaseTime = releaseTime;
        emit LockUpdated(msg.sender, locksData[msg.sender].threshold, locksData[msg.sender].releaseTime);
    }


    function _beforeTokenTransfer(address from, address, uint256 amount) internal override virtual {
        if (locksData[from].threshold == 0)
            return;
        _updateLock(from);
        require(balanceOf(from) >= locksData[msg.sender].threshold + amount, "not enough non-locked tokens");
    }


    function _updateLock(address account) internal {
        if (locksData[account].releaseTime < block.timestamp) {
            locksData[account].threshold = 0;
            locksData[account].releaseTime = 0;
        }
    }
}




pragma solidity ^0.8.0;





string constant NAME = "Argennon";
string constant SYMBOL = "ARG";
uint8 constant DECIMALS = 6;
uint constant CAP = 50e15;
uint constant INITIAL_SUPPLY = 10e15;
uint constant DURATION = 2920 days;


address constant FOUNDER = address(0x1BE77304cA7b3B0FBFaa3cd0F6dd47B360936c0d);
uint constant FOUNDERS_SHARE = 5e15;
uint constant FOUNDERS_INITIAL_MINT_APPROVAL = 1e15;



contract ArgennonToken is LockableERC20, MintableERC20, DistributorERC20 {
   
    
    constructor(address payable _admin, address _owner) 
    Administered(_admin)
    MintableERC20(_owner, NAME, SYMBOL, INITIAL_SUPPLY, CAP, block.timestamp + 365 days, DURATION) {
        ERC20._mint(FOUNDER, FOUNDERS_SHARE);
        mintingAllowances[_admin] = FOUNDERS_INITIAL_MINT_APPROVAL;
    }
    
    
    function founder() public pure returns(string memory) {
        return "aybehrouz";
    }
    
    
    function founderAccount() public pure returns(address) {
        return FOUNDER;
    }
    
    
    function decimals() public pure override returns(uint8) {
        return DECIMALS;
    }
    
    
    function _mint(address account, uint256 amount) internal override(ERC20, MintableERC20) {
        MintableERC20._mint(account, amount);
    }
    

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal
    override(ERC20, LockableERC20, DistributorERC20) {
        LockableERC20._beforeTokenTransfer(from, to, amount);
        DistributorERC20._beforeTokenTransfer(from, to, amount);
    }
}
