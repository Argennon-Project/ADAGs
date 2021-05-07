// SPDX-License-Identifier: GPL-3.0-or-later

const Errors = require('./errors.js');
const MintableToken = artifacts.require("MintableERC20");

contract("MintableERC20", (accounts) => {

    let mintableToken, owner;

    beforeEach(async () => {
        owner = accounts[0];
        mintableToken = await MintableToken.new(owner, "", "", 100000, 500000, Math.floor(Date.now() / 1000), 1000);
    });

    it("allows owner to mint or approve minting", async () => {
        await mintableToken.mint(accounts[2], 100, {from: owner});
        await Errors.expectError(
            mintableToken.mint(accounts[2], 100, {from: accounts[1]}),
            Errors.MINT_ALLOWANCE_ERROR
        );
        await Errors.expectError(
            mintableToken.increaseMintingAllowance(accounts[1], 100, {from: accounts[1]}),
            Errors.NOT_AUTHORIZED_ERROR
        );
        await mintableToken.increaseMintingAllowance(accounts[1], 30, {from: owner});
        await mintableToken.increaseMintingAllowance(accounts[1], 70, {from: owner});
        await mintableToken.mint(accounts[2], 50, {from: accounts[1]});
        await mintableToken.mint(accounts[2], 50, {from: accounts[1]});
        await Errors.expectError(
            mintableToken.mint(accounts[2], 1, {from: accounts[1]}),
            Errors.MINT_ALLOWANCE_ERROR
        );
        assert.equal(
            (await mintableToken.balanceOf.call(accounts[2])).toNumber(),
            200,
            "200 was not minted"
        );
    });

    it("doesn't let exceeding the total supply limit", async () => {
        await mintableToken.mint(accounts[2], 100000, {from: owner});
        await mintableToken.increaseMintingAllowance(accounts[1], 300000, {from: owner});
        await Errors.expectError(
            mintableToken.mint(accounts[2], 200000, {from: owner}),
            Errors.EXCEEDS_MAX_SUPPLY_ERROR
        );
        await Errors.expectError(
            mintableToken.mint(accounts[2], 200000, {from: accounts[1]}),
            Errors.EXCEEDS_MAX_SUPPLY_ERROR
        );
        assert.equal(
            (await mintableToken.balanceOf.call(accounts[2])).toNumber(),
            100000,
            "100000 was not minted"
        );
    });

    it('should have a linear max total supply', async () => {
        const now = Math.floor(Date.now() / 1000);
        mintableToken = await MintableToken.new(owner, "", "", 2n ** 128n , 2n ** 130n, now + 1000, 2 ** 14);
        assert.equal(
            (await mintableToken.maxAllowedSupply.call(now + 500)).valueOf(),
            2n ** 128n,
            "max total supply is invalid at point_1"
        );
        assert.equal(
            (await mintableToken.maxAllowedSupply.call(now + 1000 + 2 ** 10)).valueOf(),
            2n ** 128n + 3n * 2n ** 124n,
            "max total supply is invalid at point_2"
        );
        assert.equal(
            (await mintableToken.maxAllowedSupply.call(now + 1000 + 2 ** 12)).valueOf(),
            2n ** 128n + 3n * 2n ** 126n,
            "max total supply is invalid at point_3"
        );
        assert.equal(
            (await mintableToken.maxAllowedSupply.call(now + 100000)).valueOf(),
            2n ** 130n,
            "max total supply is invalid at point_4"
        );
    });

    it('should check initial parameters', async () => {
        const now = Math.floor(Date.now() / 1000);
        await MintableToken.new(owner, "", "", 2n ** 128n , 2n ** 128n, now + 1000, 5000);
        await Errors.expectError(
            MintableToken.new(owner, "", "", 2n ** 128n , 2n ** 128n + 3999n, now + 1000, 5000),
            Errors.BAD_INPUT_ERROR
        );
    });
});
