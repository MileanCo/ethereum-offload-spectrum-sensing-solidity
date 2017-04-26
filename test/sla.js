var SLA = artifacts.require("./SLA.sol");

contract('SLA', function(accounts) {
  it("should save the address of the creator as the _owner", function() {
    return SLA.deployed().then(function(instance) {
      return instance._owner.call({from: accounts[0]});
  }).then(function(address) {
      assert.equal(address, accounts[0], "accounts[0] wasn't the owner of the contract");
    });
  });

  it("should reject a provider registration with non-positive _costPerKb", function() {
    return SLA.deployed().then(function(instance) {
      return instance.registerProvider(accounts[0], 0, 0, 1,
                                       {from: accounts[0]});
    }).then(function(tx_id) {
      for (var i = 0; i < tx_id.logs.length; i++) {
        var log = tx_id.logs[i];
        if (log.event == "RegisteredProvider") {
          assert.isTrue(false);
        }
      }
    }).catch(function(error){
      console.log(error);
    });
  });

  it("should reject a provider registration with non-positive _penaltyPerKb", function() {
    return SLA.deployed().then(function(instance) {
      return instance.registerProvider(accounts[0], 0, 1, 0,
                                       {from: accounts[0]});
    }).then(function(tx_id) {
      for (var i = 0; i < tx_id.logs.length; i++) {
        var log = tx_id.logs[i];
        if (log.event == "RegisteredProvider") {
          assert.isTrue(false);
        }
      }
    }).catch(function(error){
      console.log(error);
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
    });
  });

  it("should fire event when notifyPayment", function() {
    //TODO: check that the pendingWithdrawals increases after the call
    return SLA.deployed().then(function(instance) {
      return instance.notifyPayment(accounts[0], 10, {from: accounts[0]});
    }).then(function(notify_txid){
      var found = false;
      for (var i = 0; i < notify_txid.logs.length; i++) {
        var log = notify_txid.logs[i];
        if (log.event == "PeriodicPayout") {
          found = true;
          break;
        }
      }
      assert.isTrue(found);
    }).catch(function(error){
      console.log(error);
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
          assert.isTrue(false);
        }
      }
    }).catch(function(error){
      console.log(error);
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
    });
  });

  it("should throw when we try to block an unregistered provider", function() {
    assert.isTrue(false);
  });

  it("should allow withdrawal and remove pending funds when withdraw", function() {
    assert.isTrue(false);
  });

});
