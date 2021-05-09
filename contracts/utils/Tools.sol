// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.8.0;


// for truffle use these imports:
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";


// for Remix use these imports:
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


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
        // Solidity should be able to detect overflows.
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
            
        // now we check to see if we have enough precision or not.
        // our error is r / b so our fractional error is (r / b) / (a / b) and we should have (a / r) > 1 / e. 
        if (down) {
            require(self.a / r > INVERTED_PRECISION, "not enough precision");
            return q;
        }
        require(self.a / (self.b - r) > INVERTED_PRECISION, "not enough precision");
        return q + 1;
    }
}


// Helper function for calculating the minimum of two values.
function min(uint a, uint b) pure returns (uint) {
    return a <= b ? a : b; 
}
