
exports.LOCKED_ERROR = "Error: Returned error: VM Exception while processing transaction: revert Not enough " +
    "non-locked tokens. -- Reason given: Not enough non-locked tokens..";
exports.LOCK_UPDATE_ERROR = "Error: Returned error: VM Exception while processing transaction: revert Locks can only " +
    "be extended. -- Reason given: Locks can only be extended..";

exports.expectError = async function (promise, error) {
    let passed = false;
    try {
        await promise;
        passed = true;
    } catch (e) {
        assert.equal(e.toString(), error,"Invalid error.");
    }
    if (passed) throw(`No errors given, While expecting ${error}.`);
}