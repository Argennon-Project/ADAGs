const Errors = require('./errors.js');
const LockableTestToken = artifacts.require("LockableTestToken");

contract('LockableERC20', (accounts) => {

    let lockableToken;

    before(async () => {
        lockableToken = await LockableTestToken.new(accounts[0], 1000);
    })

    it('should transfer and lock tokens', async () => {
        await lockableToken.extendLock(300, Math.floor(Date.now() / 1000) - 200, {from: accounts[1]});

        await lockableToken.transfer(accounts[1], 200, {from: accounts[0]});
        const balance = await lockableToken.balanceOf.call(accounts[1]);
        assert.equal(balance.toNumber(), 200, "200 was not transferred.");

        const lock = await lockableToken.locked.call(accounts[1]);
        assert.equal(lock.amount.valueOf(), 200, "200 was not locked.");

        Errors.expect(lockableToken.transfer(accounts[0], 100, {from: accounts[1]}), Errors.LOCK_ERROR);
    });

    it('should extend lock', async () => {
        const lockableToken = await LockableTestToken.new(accounts[0], 1000);
        await lockableToken.transfer(accounts[1], 400, {from: accounts[0]});
        const balance = await lockableToken.balanceOf.call(accounts[1]);
        assert.equal(balance.toNumber(), 400, "400 was not transferred.");
    });

    /*
    it('should send coin correctly', async () => {
      const metaCoinInstance = await MetaCoin.deployed();

      // Setup 2 accounts.
      const accountOne = accounts[0];
      const accountTwo = accounts[1];

      // Get initial balances of first and second account.
      const accountOneStartingBalance = (await metaCoinInstance.getBalance.call(accountOne)).toNumber();
      const accountTwoStartingBalance = (await metaCoinInstance.getBalance.call(accountTwo)).toNumber();

      // Make transaction from first account to second.
      const amount = 10;
      await metaCoinInstance.sendCoin(accountTwo, amount, { from: accountOne });

      // Get balances of first and second account after the transactions.
      const accountOneEndingBalance = (await metaCoinInstance.getBalance.call(accountOne)).toNumber();
      const accountTwoEndingBalance = (await metaCoinInstance.getBalance.call(accountTwo)).toNumber();


      assert.equal(accountOneEndingBalance, accountOneStartingBalance - amount, "Amount wasn't correctly taken from the sender");
      assert.equal(accountTwoEndingBalance, accountTwoStartingBalance + amount, "Amount wasn't correctly sent to the receiver");
    });*/
});
