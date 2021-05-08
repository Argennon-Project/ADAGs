The Argennon token (ARG) is an ERC20 token intended to represent an investor's share in the Argennon project. The
functionality of ARG token is as follows:

- After lunch of the Argennon blockchain the ARG tokens will be convertible in 1:1 ratio to the main currency of the
  Argennon blockchain.
- The ARG ERC20 contract is a profit distributor. That means when an amount of an ERC20 token which is registered as a
  profit source of the contract, is sent to the contract address, that amount will be distributed between all ARG
  holders. When a crowdfunding is done, the earnings of the crowdfunding will be sent to the ARG ERC20 contract address
  and hence it will be distributed between ARG holders.
- Holders of the ARG token are eligible to vote in the Argennon Distributed Autonomous Governance system (ADAGs). The
  ADAGs is a smart contract which decides about new crowdfunding campaigns, their configuration and minting of new ARG
  tokens.

Several crowdfunding campaigns may be held before the lunch of the Argennon blockchain, all of them will follow these
rules:

- Every crowdfunding is conducted using a smart contract: the CF contract, and it has its own token: the ICO token.
  Users may buy ICO tokens from the CF contract. A user can burn his ICO tokens and convert them to the ARG token in 1:1
  ratio using the CF contract at any time.
- The ICO token is redeemable. This means anyone can redeem his ICO tokens by using the CF contract and get a refund.
  The redemption price depends on the time since the start of the crowdfunding and the amount of funds the crowdfunding
  has raised so far:
    - If the amount of raised funds has not yet reached the threshold defined in the CF contract, a user may redeem at
      100% price.
    - If the amount of raised funds has reached the threshold, then the redemption price will drop to the configured
      price of the CF contract, which is determined by the ADAGs and usually is 90%. It is guaranteed that a user can
      redeem at that price for a configured time interval, which again is determined by the ADAGs and usually is one
      year. After that time interval, the ICO token will not be redeemable, and user should only convert them to the ARG
      token.

The final maximum supply of the Argennon currency will be 100 billion. The ERC20 ARG token on the other hand, will have
a 50 billion cap. Consequently, 50 billion tokens will be minted only after the lunch of the Argennon mainnet. These
tokens will be mainly used as staking rewards.

The minting of the ARG ERC20 token will follow these rules:

- 10 billion -> founder's share
- 1 billion -> founder's initial reserve which will be given to early contributors as rewards.
- 1 billion -> first crowdfunding which will be sold for 50,000$

The minting of the remaining ARG ERC20 tokens will be decided by the ADAGs, but it has to obey the maximum supply limit
defined by the ARG ERC20 contract. This maximum allowed supply is a function of time. For the first year a maximum
supply of 20 billion is allowed, and after that the maximum allowed supply increases 5 billion per year for 6 years
until it reaches the 50 billion cap. It should be noted that this is a hard limit on the maximum supply and the actual
supply may be lower than this amount.

After the lunch of the Argennon blockchain, all unminted ARG tokens will be considered as the reserve of the ADAGs
counterpart on the Argennon blockchain.