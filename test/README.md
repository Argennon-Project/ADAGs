### Running Tests

Unit tests can be run using truffle suit. To run unit tests by truffle follow these steps:

 Use truffle to initialize a new project:

    mkdir MyProject && cd MyProject
    truffle init

Copy `contracts` and `test` into `MyProject` Directory.

Install OpenZeppelin in your new project:

    npm init -y
    npm install --save-exact openzeppelin-solidity

Make sure `Tools.sol` file is using truffle compatible imports:

```solidity
// for truffle use these imports:
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
```

Configure truffle to use the right solc compiler version by changing `truffle-config.js` file:

```
// Configure your compilers
  compilers: {
    solc: {
      version: "0.8.4",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 150
        },
      //  evmVersion: "byzantium"
      }
    }
  },
```

Now you should be able to run unit tests:

    truffle test

Tests may take several minutes to complete.

To run a specific test, include the test file name in the command. For example to only run the tests included in
`lockable_test.js` run this command:

    truffle test test/lockable_test.js