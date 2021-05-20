// SPDX-License-Identifier: AGPL-3.0-only

exports.NOT_AUTHORIZED_ERROR = "Error: Returned error: VM Exception while processing transaction: revert " +
    "sender not authorized -- Reason given: sender not authorized.";
exports.LOCKED_ERROR = "Error: Returned error: VM Exception while processing transaction: revert not enough " +
    "non-locked tokens -- Reason given: not enough non-locked tokens.";
exports.LOCK_UPDATE_ERROR = "Error: Returned error: VM Exception while processing transaction: revert locks can only " +
    "be extended -- Reason given: locks can only be extended.";
exports.BAD_INPUT_ERROR = "Error: Returned error: VM Exception while processing transaction: revert bad inputs " +
    "-- Reason given: bad inputs.";
exports.LOW_BALANCE_ERROR = "Error: Returned error: VM Exception while processing transaction: revert profit balance " +
    "is not enough -- Reason given: profit balance is not enough.";
exports.WITHDRAW_NOT_ALLOWED_ERROR = "Error: Returned error: VM Exception while processing transaction: revert " +
    "withdrawal not allowed -- Reason given: withdrawal not allowed.";
exports.ALREADY_REGISTERED_ERROR = "Error: Returned error: VM Exception while processing transaction: revert already " +
    "registered -- Reason given: already registered.";
exports.GENERAL_ERROR = "Error: Returned error: VM Exception while processing transaction: revert";
exports.PRECISION_ERROR = "Error: Returned error: VM Exception while processing transaction: revert not enough " +
    "precision -- Reason given: not enough precision.";
exports.FINAL_SOURCES_ERROR = "Error: Returned error: VM Exception while processing transaction: revert profit " +
    "sources are final -- Reason given: profit sources are final.";

exports.Mintable = {
    MINT_ALLOWANCE_ERROR: "Error: Returned error: VM Exception while processing transaction: revert amount " +
        "exceeds minting allowance -- Reason given: amount exceeds minting allowance.",
    EXCEEDS_MAX_SUPPLY_ERROR: "Error: Returned error: VM Exception while processing transaction: revert " +
        "totalSupply exceeds limit -- Reason given: totalSupply exceeds limit.",
}

exports.CrowdFunding = {
    NOT_YET_ALLOWED_ERROR: "Error: Returned error: VM Exception while processing transaction: revert withdrawals " +
        "are not yet allowed -- Reason given: withdrawals are not yet allowed.",
    AMOUNT_TOO_HIGH_ERROR: "Error: Returned error: VM Exception while processing transaction: revert amount is too " +
        "high -- Reason given: amount is too high.",
};

exports.expectError = async function (promise, error) {
    let passed = false;
    try {
        await promise;
        passed = true;
    } catch (e) {
        assert.equal(e.toString(), error, "Invalid error");
    }
    if (passed) throw(`No errors given, While expecting: ${error}`);
}

exports.check = async function (f, wants, accounts, exact, name, decimals) {
    for (let i = 0; i < wants.length; i++) {
        const got = (await f(accounts[i])).valueOf();
        const want = Math.round(wants[i] * decimals);
        //console.log(got.toString());
        if (exact) {
            assert.equal(got, want,  `In ${name}, for acc${i}`);
        } else {
            assert.isOk(
                want - got >= 0 && want - got <= 1,
                `In ${name}, for acc${i} got ${got} but wanted a value close to ${want}`
            );
        }
    }
}
