

Please check out the Argennon community on [Discord](https://discord.gg/7u3cXNt5yN), [Telegram](https://t.me/Argennon), [Reddit](https://www.reddit.com/r/Argennon/) and [Twitter](https://twitter.com/Argennon_org)!

<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-8-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

## The Argennon Project

Argennon (*the classical pronunciation should be used: /ɑrˈɡen.non/*) is a next-gen cloud based blockchain and smart contract platform which tries to solve shortcomings of existing platforms. The Argennon blockchain uses a hybrid proof of stake (HPoS) consensus protocol, which is based on participation of every Argennon user. This hybrid protocol combines the benefits of a centralized and a decentralized system.

Thanks to the cloud based design of the Argennon blockchain, transaction validation does not require costly computational resources, and normal personal computers with limited hardware capabilities can actively participate in the Argennon consensus protocol. This property makes Argennon a truly decentralized and democratic blockchain and one of the most secure existing platforms.

By using cryptographic accumulators, the integrity of data on the Argennon cloud is guaranteed, and there is no need for trusting cloud servers. At the same time, by using a smart clustering algorithm the network usage and the overhead of the commitment scheme is kept manageable.

The Argennon cloud is formed by a permission-less network of Publicly Verifiable Database (PV-DB) servers. A PV-DB server in Argennon, is a conventional data server which uses its computational and storage resources to help the Argennon network process transactions. A large portion of incentive rewards in the Argennon platform is devoted to PV-DB servers. This incentivizes the development of conventional networking, storage and computational hardware, which can benefit all areas of information technology. This contrasts with the approach of other blockchains that incentivizes the development of a totally useless technology of hash calculation.

An initial draft of the Argennon white paper can be
found [here](https://raw.githubusercontent.com/aybehrouz/AVM/main/pdf/A.pdf). In addition,
this [link](https://www.argennon.com/features.html) provides a brief overview of the important properties of the Argennon
platform.

Until the launch of the Argennon main-net, an ERC20 token and a governance system will be deployed on the Binance Smart
Chain or the Ethereum network in order to represent investors' share in the project and giving them the opportunity to
determine the project's path.

### The Argennon ERC20 Token

The Argennon token (ARG /ɑrɡ/) is an ERC20 token intended to represent an investor's share in the Argennon project.
After the launch of the Argennon blockchain, the ARG ERC20 token will be convertible in 1:1 ratio to the native currency
of the Argennon blockchain. Meanwhile, the ARG ERC20 token will act as a governance token:

- The ARG ERC20 smart contract is a profit distributor. That means when an amount of an ERC20 token which is registered
  as a profit source, is sent to the contract address, that amount will be distributed between all ARG holders,
  proportional to their ARG balance.
- Holders of the ARG token are eligible to vote in the Argennon Decentralized Autonomous Governance system (ADAGs).
    - In order to vote, a user needs to lock his ARG tokens for at least 6 months. During this period he will not be
      able to transfer his tokens.
    - Any proposal that gets more than 66% (2/3) of the total ARG supply vote will be accepted by the ADAGs.

### ADAGs

The Argennon Decentralized Autonomous Governance system (ADAGs /eɪ-dagz/) is a smart contract which is able to perform
*governance actions*. These actions, for the ADAGs version, functioning on the Binance Smart Chain or the Ethereum
network, include:

- Starting new token sales with different configurations
- Minting new ARG tokens
- Sending funds to any address as grants
- Changing the threshold of voting weight needed for accepting a proposal
    - can be changed between 0.55 and 0.8 of total ARG supply
- Changing the minimum lock period required for voting
    - can be changed between 120 and 540 days
- Changing the required fee for creating a proposal
    - can be changed between 0 and 0.5 BNB
- Changing the administrator of other Argennon contracts
    - this operation is possible only if ADAGs is the current admin of that contract
- Deploying a new governance system
    - this operation can only be proposed by ADAGs admin. (*It should be noted that this will not give the admin a
      special role, because the admin of ADAGs can be changed through a normal proposal and voting mechanism.*)

### Token Sales

Several token sales may be held before the launch of the Argennon blockchain, all of them will follow a set of
predefined rules:

- Every token sale is conducted using a smart contract: the *TS contract*, and it has its own token: the *ICO token*.
  Users may only buy *ICO tokens* from the *TS contract*. These ICO tokens can be burnt and converted to the ARG token
  in 1:1 ratio using the TS contract at any time.
- The ICO token is redeemable. This means anyone can redeem his ICO tokens using the TS contract and get a refund. The
  redemption price depends on the time since the start of the token sale and the amount of funds the token sale has
  raised so far:
    - If the amount of raised funds has not yet reached the threshold defined in the TS contract, a user may redeem at
      100% price.
    - If the amount of raised funds has reached the threshold, then the redemption price will drop to the price defined
      in the TS contract, which is determined by the ADAGs. It is guaranteed that a user can redeem at that price for a
      configured time interval, which is determined by the ADAGs. After that time interval, the ICO token may not be
      redeemable, and the user should only convert them to the ARG token*. The exact configuration of the token sale is
      decided by the ADAGs, However:
        - the redemption price can not be less than 50%.
        - the redemption duration can not be shorter than 6 months.
- When a token sale is done, the earnings of the token sale will be automatically sent to the ARG ERC20 contract address
  and hence, it will be distributed between ARG holders, or it will be sent to the ADAGs smart contract and will be used
  for grant programs.

**Actually even after this time interval, the ICO tokens are still redeemable. However, since the contract will allow
the withdrawal of funds, the redemption price could be anything based on the amount of remaining funds.*

### Tokenomics

The final total supply of the Argennon currency will be **100 billion** which **must** be reached in **30 years**. At
max, half of this amount may be minted before the launch of the Argennon main-net. Consequently, The ARG ERC20 token
will have a 50 billion cap. The other half, including 50 billion Argennons, will be minted only
after the launch of the Argennon blockchain, and will be mainly used as incentive rewards.

The minting of the ARG ERC20 token and the ARG currency will follow these rules:

- **5 billion:** founder's share.
    - **95% (4.75 billion)** of the founder's share will be locked by the ARG ERC20 contract inside founder's account,
      and it can not be transferred and liquidated into the market for the first **two years**.
- **5 billion:** founder's initial minting allowance which will be used for awarding ARG grants to early contributors.
    - These grants can only be given to people who have helped the development and growth of the Argennon ecosystem.
    - These grants must not be sold.
    - Before the launch of the Argennon mainnet, a grant more than 5,000,000 ARGs can be given to a single person only
      if the grant is locked for at least **one year**.
    - All these grants are documented [here](https://www.argennon.com/grants.html).
- **1 billion:** first token sale which will be sold for **$0.0005 per ARG**.
    - This is the only token sale which is not conducted by the ADAGs.
- **39-44 billion:** controlled by the ADAGs (the Argennon governance system). This amount may be used for token sales,
  air drops and grants, decided by the ADAGs.
    - Token sales will be **public** and can only be done using the TS contract, complying with the Argennon token sale rules.
- **50 billion:** will be minted after the launch of the Argennon blockchain and will be used for the Argennon incentive
  mechanism. (*The Argennon incentive mechanism is similar to mining rewards in other blockchains.*)


Therefore, the ARG token should not be minted in order to be sold on the market, to add liquidity to liquidity pools or
to do any type of activities for price manipulation.

The minting of the ARG ERC20 token has to be limited by the maximum supply defined by
the ARG ERC20 contract. This maximum allowed supply is a function of time. For the first year a maximum supply of 10
billion is allowed, and after that, the maximum allowed supply increases 5 billion per year linearly, until it could
reach the 50 billion cap after **nine years**. It should be noted that this is a hard limit on the **maximum** supply of
the ARG ERC20 token and the actual supply may be lower than this amount.

After the launch of the Argennon blockchain, all unminted ARG ERC20 tokens with respect to the 50 billion cap, will be
considered as the reserve of the ADAGs counterpart on the Argennon blockchain.

## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://github.com/liang0561"><img src="https://avatars.githubusercontent.com/u/75945582?v=4?s=100" width="100px;" alt=""/><br /><sub><b>liang0561</b></sub></a><br /><a href="#financial-liang0561" title="Financial">💵</a> <a href="#blog-liang0561" title="Blogposts">📝</a></td>
    <td align="center"><a href="https://github.com/SatoshiMiracle"><img src="https://avatars.githubusercontent.com/u/72975337?v=4?s=100" width="100px;" alt=""/><br /><sub><b>SatoshiMiracle</b></sub></a><br /><a href="https://github.com/Argennon-Project/ADAGs/issues?q=author%3ASatoshiMiracle" title="Bug reports">🐛</a> <a href="#blog-SatoshiMiracle" title="Blogposts">📝</a> <a href="#content-SatoshiMiracle" title="Content">🖋</a> <a href="#fundingFinding-SatoshiMiracle" title="Funding Finding">🔍</a> <a href="#ideas-SatoshiMiracle" title="Ideas, Planning, & Feedback">🤔</a> <a href="#question-SatoshiMiracle" title="Answering Questions">💬</a> <a href="https://github.com/Argennon-Project/ADAGs/pulls?q=is%3Apr+reviewed-by%3ASatoshiMiracle" title="Reviewed Pull Requests">👀</a> <a href="#userTesting-SatoshiMiracle" title="User Testing">📓</a> <a href="#security-SatoshiMiracle" title="Security">🛡️</a></td>
    <td align="center"><a href="https://github.com/Rejinderi"><img src="https://avatars.githubusercontent.com/u/4333016?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Rejinderi</b></sub></a><br /><a href="#blog-Rejinderi" title="Blogposts">📝</a> <a href="#financial-Rejinderi" title="Financial">💵</a> <a href="#fundingFinding-Rejinderi" title="Funding Finding">🔍</a> <a href="#ideas-Rejinderi" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://medium.com/@greedybucks"><img src="https://avatars.githubusercontent.com/u/54760103?v=4?s=100" width="100px;" alt=""/><br /><sub><b>hacktivist</b></sub></a><br /><a href="#blog-hacktivist24" title="Blogposts">📝</a> <a href="#fundingFinding-hacktivist24" title="Funding Finding">🔍</a></td>
    <td align="center"><a href="https://github.com/Tuananhthepussyhunter"><img src="https://avatars.githubusercontent.com/u/71578941?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Tuananhthepussyhunter</b></sub></a><br /><a href="#blog-Tuananhthepussyhunter" title="Blogposts">📝</a> <a href="#fundingFinding-Tuananhthepussyhunter" title="Funding Finding">🔍</a> <a href="#question-Tuananhthepussyhunter" title="Answering Questions">💬</a></td>
    <td align="center"><a href="https://github.com/codemaster138"><img src="https://avatars.githubusercontent.com/u/43313420?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Jake</b></sub></a><br /><a href="#ideas-codemaster138" title="Ideas, Planning, & Feedback">🤔</a> <a href="#security-codemaster138" title="Security">🛡️</a></td>
    <td align="center"><a href="https://github.com/uneevn"><img src="https://avatars.githubusercontent.com/u/90345889?v=4?s=100" width="100px;" alt=""/><br /><sub><b>uneevn</b></sub></a><br /><a href="#security-uneevn" title="Security">🛡️</a> <a href="#ideas-uneevn" title="Ideas, Planning, & Feedback">🤔</a> <a href="#question-uneevn" title="Answering Questions">💬</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://github.com/ak223wd"><img src="https://avatars.githubusercontent.com/u/50454050?v=4?s=100" width="100px;" alt=""/><br /><sub><b>ak223wd</b></sub></a><br /><a href="#fundingFinding-ak223wd" title="Funding Finding">🔍</a></td>
  </tr>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
