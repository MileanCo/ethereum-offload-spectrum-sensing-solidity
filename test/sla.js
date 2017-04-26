var SLA = artifacts.require("./SLA.sol");

contract('SLA', function(accounts) {
  it("should save the address of the creator as the _owner", function() {
    return SLA.deployed().then(function(instance) {
      return instance._owner.call({from: accounts[0]});
    }).then(function(address) {
      assert.equal(address, accounts[0], "accounts[0] wasn't the owner of the contract");
    }).catch(function(error){
      console.log(error);
      assert.fail();
    });
  });

  it("should reject a provider registration with non-positive _costPerKbps", function() {
    return SLA.deployed().then(function(instance) {
      return instance.registerProvider(accounts[0], 0, 0, 1,
                                       {from: accounts[0]});
    }).then(function(tx_id) {
      for (var i = 0; i < tx_id.logs.length; i++) {
        var log = tx_id.logs[i];
        if (log.event == "RegisteredProvider") {
          assert.fail(false, true, "RegisteredProvider event found, expected none");
        }
      }
    }).catch(function(error){
      console.log(error);
      assert.fail();
    });
  });

  it("should reject a provider registration with non-positive _penaltyPerKbps", function() {
    return SLA.deployed().then(function(instance) {
      return instance.registerProvider(accounts[0], 0, 1, 0,
                                       {from: accounts[0]});
    }).then(function(tx_id) {
      for (var i = 0; i < tx_id.logs.length; i++) {
        var log = tx_id.logs[i];
        if (log.event == "RegisteredProvider") {
          assert.fail(false, true, "RegisteredProvider event found, expected none");
        }
      }
    }).catch(function(error){
      console.log(error);
      assert.fail();
    });
  });

  it("should register a new provider if invoked by the owner", function() {
    return SLA.deployed().then(function(instance) {
      return instance.registerProvider(accounts[0], 0, 1, 1,
                                       {from: accounts[0]});
    }).then(function(tx_id){
      // assert.isTrue(registered, "registerProvider returned false")
      var found = false;
      for (var i = 0; i < tx_id.logs.length; i++) {
        var log = tx_id.logs[i];
        if (log.event == "RegisteredProvider") {
          found = true;
          break;
        }
      }
      assert.isTrue(found);
    }).catch(function(error){
      console.log(error);
      assert.fail();
    });
  });

  it("should fire event and update pendingWithdrawals when notifyPayment is called", function() {
    var amount = 10;
    var instance;
    var account_one_starting_pending;
    var account_one_ending_pending;
    return SLA.deployed().then(function(inst) {
      instance = inst;
      return instance.pendingWithdrawals.call(accounts[1]);
    }).then(function(pending){
      account_one_starting_pending = pending.toNumber();
      return instance.notifyPayment(accounts[0], amount, {from: accounts[0]});
    }).then(function(notify_txid){
      var found = false;
      for (var i = 0; i < notify_txid.logs.length; i++) {
        var log = notify_txid.logs[i];
        if (log.event == "PeriodicPayout") {
          found = true;
          //FIXME: log.event.args returns undefined when testing for some reason
          // assert.equal(log.event.args._tputInKbps.toNumber(), amount);
          break;
        }
      }
      assert.isTrue(found);
      return instance.pendingWithdrawals.call(accounts[1]);
    }).then(function(newPending){
      account_one_ending_pending = newPending.toNumber();
      assert.equal(account_one_ending_pending, account_one_starting_pending + amount);
    }).catch(function(error){
      console.log(error);
      assert.fail();
    });
  });

  it("should reject a second registration for the same provider", function() {
    return SLA.deployed().then(function(instance) {
      return instance.registerProvider(accounts[0], 0, 1, 1,
                                       {from: accounts[0]});
    }).then(function(tx_id) {
      for (var i = 0; i < tx_id.logs.length; i++) {
        var log = tx_id.logs[i];
        if (log.event == "RegisteredProvider") {
          assert.fail(false, true, "RegisteredProvider event found, expected none");
        }
      }
    }).catch(function(error){
      console.log(error);
      assert.fail();
    });
  });

  it("should remove a reigstered provider after it has been blocked", function() {
    return SLA.deployed().then(function(instance) {
      return instance.blockProvider(accounts[0], {from: accounts[0]});
    }).then(function(tx_id) {
      var found = false;
      for (var i = 0; i < tx_id.logs.length; i++) {
        var log = tx_id.logs[i];
        if (log.event == "BlockedProvider") {
          // if (log.event._provider == accounts[0]) {
            found = true;
          // }
        }
      }
      assert.isTrue(found);
    }).catch(function(error){
      console.log(error);
      assert.fail();
    });
  });

  it("should throw when we try to block an unregistered provider");

  var account_zero_starting_balance;
  var account_zero_ending_balance;
  var account_one_starting_balance;
  var account_one_ending_balance;

  it("should allow withdrawal and remove pending funds when withdraw");

});
