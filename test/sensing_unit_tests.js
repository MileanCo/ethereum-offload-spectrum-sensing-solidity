var ServiceFactory = artifacts.require("./ServiceFactory.sol");
var SensingService = artifacts.require("./SensingService.sol");


contract('ServiceFactory', function(accounts) {
    const _costPerKbps = 1000000000000000; // 1 finney = 0.001 ether
    console.log("we have these accounts available: ");
    console.log(accounts);

    var sensing_band = 10;
    var bandwidth_granularity = 100;
    var helpers_list = [
      accounts[1],
      accounts[2],
      //accounts[3],
    ];

  function get_sensing_data() {
    return [0,1,0,1,1,1,1,0,0,0,1,0,1];
  }

  it("should save the address of the creator as the owner var ", function() {
    var serviceFactory;
    // this retreives a deployed contract already...
    // first we retrieved the Factory contract (which creates instances of SensingService)
    ServiceFactory.deployed().then(function(instance) {
      serviceFactory = instance;
      return serviceFactory.newSensingService(helpers_list, sensing_band, bandwidth_granularity, {from:accounts[0]} );
    }).then(function(tx_obj) {
      // now we have created a new SensingService contract instance... retrieve it and then run some tests.
      var sensingService;
      console.log(tx_obj.logs[0].args);
      var new_contract_address = tx_obj.logs[0].args.serviceAddr;
      SensingService.at(new_contract_address).then(function(instance) {
        sensingService = instance;
        return sensingService.owner_su.call({from: accounts[0]});
      }).then(function(address) {
          assert.equal(address, accounts[0], "accounts[0] wasn't the owner of the contract");
      }).catch(
        function(error) {
          console.log(error);
          assert.fail();
      });
    // errors for Factory
    }).catch(
      function(error) {
        console.log(error);
        assert.fail();
    });
  });

  // .call = explicitly let the Ethereum network know we're not intending to persist any changes.

  it(" recieveSensingData from all helpers and then pay", function() {
    var serviceFactory;

    ServiceFactory.deployed().then(function(instance) {
      serviceFactory = instance;
      return serviceFactory.newSensingService(helpers_list, sensing_band, bandwidth_granularity, {from:accounts[0]} );
    }).then(function(tx_obj) {
      // now we have created a new SensingService contract instance... retrieve it and then run some tests.
      var sensingService;
      console.log(tx_obj.logs[0].args);
      var new_contract_address = tx_obj.logs[0].args.serviceAddr;
      SensingService.at(new_contract_address).then(function(instance) {
        sensingService = instance;
        console.log("sending account1 "+accounts[1]+" data to contract");
        // execute as a Transaction (need 2 make changes)
        return sensingService.helperNotifyDataSent(accounts[1], {from: accounts[1]});
        //return promise;

      }).then(function(event_tx_obj) {
        console.log(event_tx_obj);
        //console.log(event_tx_obj.logs[0]);
        // check that we got NewRoundCreated, nothing else
        //if (event_tx_obj.logs.length > 1) {
        //  assert.fail("Should only have 1 event, NewRoundCreated");
        //}
        for (var i = 0; i < event_tx_obj.logs.length; i++) {
          var log = event_tx_obj.logs[i];
          console.log(log.event);
          if (log.event == "RoundCompleted") {
            assert.equal(log.event, "Bad", "Invalid RoundCompleted event occured");
          } else if (log.event == "DebugInt") {
            console.log(log);
          }
        }

        console.log("sending account2 "+accounts[2]+" data to contract");
        // execute as a Transaction (need 2 make changes)
        return sensingService.helperNotifyDataSent(accounts[2], {from: accounts[2]});

      }).then(function(event_tx_obj) {
        console.log("checking if payout events occurred");
        console.log(event_tx_obj);

        // check that we got NotifyUsersToValidate event and RoundCompleted event
        for (var i = 0; i < event_tx_obj.logs.length; i++) {
          var log = event_tx_obj.logs[i];
          console.log(log.event);
          if (log.event == "Payout") {
            console.log("WIN");
            //assert.equal(log.args._tputInKbps.toNumber(), amount);
            break;
          }
        }

        //return instance.setSensingData(accounts[2], get_sensing_data());
        //return sensingService.owner.call({from: accounts[0]});
        /**
      }).then(function(address) {
        assert.equal(address, accounts[0], "accounts[1] wasn't the new owner of the contract");*/

      }).catch(function(error){
        console.log(error);
        assert.fail();
      });
    // errors for Factory
    }).catch(
      function(error) {
        console.log(error);
        assert.fail();
    });
  });


});
