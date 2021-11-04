### An Overview of Argennon Properties:

- Argennon is a cloud based blockchain. Argennon validators do not keep a local copy of the state data. Instead, the
  state is stored on a **trust-less** cloud of publicly verifiable database (PV-DB) servers.

- By using cryptographic commitment schemes the integrity of data on the cloud is guaranteed, and there is no need for
  trusting PV-DB servers. At the same time, by using a smart clustering algorithm the network usage and the overhead of
  the commitment scheme is kept manageable.

- Argennon uses a **hybrid** POS consensus protocol. A democratically elected committee of delegates is responsible for
  minting and proposing new blocks. Then, each block is validated by a large committee of normal validators. **Every**
  Argennon user is a member of at least one committee of validators. Thanks to the cloud based design of the Argennon
  blockchain, transaction validation does not require a large physical storage space and being a validator does not
  require costly computational resources. Everyone with an Argennon wallet can participate in the Argennon consensus
  protocol. This makes Argennon a truly democratic and decentralized blockchain.

- Sharding **decreases** the security of a blockchain. Argennon does not need shards. Due to the cloud based design of
  the Argennon blockchain, validators do not need to validate blocks sequentially and the validation of multiple blocks
  can be done in parallel by different committees of validators.

- By using a dependency detection algorithm, Argennon is also able to parallelize transaction validation of a **single**
  block. As a result, a multicore machine is able to validate the Argennon blockchain as fast as multiple independent
  shards.

- The hybrid Argennon consensus protocol makes Argennon one of the most secure blockchains. Only one honest delegate can
  stop any attacks against the integrity of the Argennon blockchain, and if all the delegates are malicious, as long as
  more than half of the Argennon total stake is controlled by honest users, the Argennon blockchain will preserve its
  consistency.

- The Argennon network relies on a **permission-less** network of PV-DB servers, forming the Argennon cloud. A PV-DB
  server is a conventional data server which uses its computational and storage resources to help the Argennon network
  process transactions. A large portion of incentive rewards in the Argennon protocol is devoted to PV-DB servers. This
  will incentivize the development of conventional networking, storage and computational hardware, which can benefit all
  areas of information technology. This contrasts with the approach of other blockchains that incentivize development of
  a totally useless technology of hash calculation.

- By design, the Argennon blockchain is decoupled from cryptography. There is **no** hash based addresses and a user can
  easily change his/her private keys. Moreover, If at any time the cryptographic algorithms used become insecure, they
  could be easily upgraded.

- In Argennon, operations are authorized by **explicit** signatures. This eliminates the need for approval schemes or
  call back patterns and encourages developers to better utilize the capabilities of digital signatures.

- The Argennon Smart Contract Execution Environment (AscEE) is able to execute a smart contract as fast as a native
  application. This means that an Argennon smart contract is as efficient as the AscEE code itself. This way, performing
  costly mathematical calculations with a smart contract is not an engineering mistake anymore.

- The Argennon Execution Environment protects smart contracts from reentrancy by low level locks. These locks will be
  opened automatically so there will be no risk of permanent deadlocks. The Argennon Execution Environment also provides
  **deferred calls** mechanism, which enables a smart contract to call back another smart contract without causing
  reentrancy complexities.

- An Argennon smart contract can safely call external smart contracts. There is no way that a smart contract can affect
  its caller. Even the execution resources are separated and the called smart contract can not abort the execution of
  its caller by excessive gas usage.

- Most of the arithmetic in the Argennon Execution Environment is done using floating point operations instead of
  unsigned integer operations. As a result, there will be almost no need for a word size bigger than 64 bits. At the
  same time, operations will have a bounded fractional error in contrast to integer operations that could have an
  arbitrary large fractional error.

- The Argennon Execution Environment provides a built-in standard library. This standard library provides a secure and
  convenient way for implementing many frequently used functionalities. In addition, this library is **updatable**
  through the Argennon governance system. This means that bugs or security vulnerabilities in the AscEE standard library
  could be quickly patched and smart contracts that use this library, including non-updatable smart contracts, can
  benefit from improvements and bug fixes.

- Argennon standards are defined based on how a contract should use the AscEE standard library and not only how its
  interface should look. As a result, users can expect certain type of behaviour from a contract which complies with an
  Argennon standard.

- Interaction with Argennon smart contract is done through conventional HTTP. This enables Argennon smart contracts to
  have HTTP based **RESTful APIs**, documented by standardized descriptions like OpenAPI. This way, any client,
  including clients being used for conventional centralized web services, will be able to use Argennon smart contracts,
  regardless of how the API is implemented internally.

- ARG, the main currency of the Argennon blockchain, is controlled by a smart contract. This eliminates the need for ARG
  wrappers and also makes the transfer logic of ARG more transparent and trustable.

- Memory architecture of the AscEE completely hides the complexities of the Argennon blockchain. This enables AscEE
  compatible programming languages to have a flavour completely similar to conventional programming languages. For
  instance, the Argon language, which is the primary AscEE OOP language, supports **composition**, which is a very
  important OO design pattern.

<!---
*α* =  − ln (1 − *M*<sub>*n* + *k*</sub>/*X*) / *n*
<img src="https://render.githubusercontent.com/render/math?math=e^{i \pi} = -1">
h<sub>&theta;</sub>(x) = &pi;<sub>o</sub> x + &theta;<sub>1</sub>x
--->
