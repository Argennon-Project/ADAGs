The Argennon project is a ...

The Argennon token (ARG) is an ERC20 token intended to represent an investor's share in the project. The functionality
of ARG token is as follows:

- After lunch of the Argennon blockchain the ARG tokens will be convertible in 1:1 ratio to the main currency of the
  Argennon blockchain.
- The ARG ERC20 contract is a profit distributor. That means when some amount of a registered ERC20 token (for instance
  USDT or WETH) is sent to its address, that amount will be distributed between all ARG holders. When, a crowdfunding is
  done the earnings of the crowdfunding will be sent to the ARG ERC20 contract address and hence it will be distributed
  between ARG holders.
- Holders of ARG token are eligible to vote in the Argennon Distributed Autonomous Governance system (ADAGs). The ADAGs
  is a smart contract which decides about new crowdfunding campaigns, their configuration and minting new ARG tokens.

Several crowdfunding campaigns may be held before the lunch of the Argennon blockchain, all of them will follow these
rules:

- Any crowdfunding is conducted using a smart contract: the CF contract, and has its own token: the ICO token. Users may
  buy ICO tokens from the CF contract. A user can burn his ICO tokens and convert them to the ARG token in 1:1 ratio
  using the CF contract at any time.
- The ICO token is redeemable. This means that anyone can redeem his ICO tokens by using the CF contract and get a
  refund. The redemption price depends on the time since the start of the crowdfunding and the amount of funds the
  crowdfunding has raised so far:
    - If the amount of raised funds has not reached some predefined threshold, a user can redeem at 100% price.
    - If the amount of raised funds has reached the threshold, then the redemption price will drop to the configured
      price of the CF contract, which is determined by the ADAGs and usually is 90%. It is guaranteed that the user can
      redeem at that price for a configured time interval, which again is determined by the ADAGs and usually is one
      year. After that time interval, the token will not be redeemable, and user should only convert his ICO tokens to
      ARG tokens.

The final maximum supply of the Argennon currency will be 100 billion. The ERC20 ARG token on the other hand, will have
a 50 billion cap. Consequently, 50 billion tokens will be minted only after the lunch of the Argennon mainnet which will
be mainly used as staking rewards.

The minting of the ARG ERC20 token will follow these rules:

- 10 billion -> founder's share
- 5 billion -> founder's initial reserve which will be given to early contributors as rewards.
- 1 billion -> first crowdfunding which will be sold for 50,000$

The minting of the remaining 34 billion will be decided by the ADAGs, but it has to be limited to 5 billion per year at
max. This limit is imposed by the ARG token ERC20 contract. After the lunch of the Argennon blockchain, all unminted ARG
tokens will become the reserve of the ADAGs counterpart on the Argennon blockchain.