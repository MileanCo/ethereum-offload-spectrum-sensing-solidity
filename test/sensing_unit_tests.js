var Web3 = require('web3')
if (typeof web3 != 'undefined') {
  web3 = new Web3(web3.currentProvider);
} else {
  web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));
}
var fs = require('fs');
var contents = fs.readFileSync('test/Cheating_Record.json', 'utf8');
var cheating_record_json = JSON.parse(contents);

var ServiceFactory = artifacts.require("./ServiceFactory.sol");
var SensingService = artifacts.require("./SensingService.sol");


contract('ServiceFactory', function(accounts) {
    //const _costPerRound = 1000000000000000; // 1 finney = 0.001 ether
    const _relativeCostPerRound = 1;
    const _costPerRound = web3.toWei(_relativeCostPerRound, "ether");
    console.log("we have these accounts available: ");
    console.log(accounts);

    var sensing_band = 10;
    var bandwidth_granularity = 100;
    var owner_su = accounts[0];
    var helpers_list = [
      accounts[1],
      accounts[2],
      //accounts[3],
    ];

  function get_sensing_data() {
    // TODO: add fancy data
    return [0,1,0,1,1,1,1,0,0,0,1,0,1];
  }
  function get_sensing_data_2() {
    // TODO: add fancy data
    return [1,1,0,1,1,1,1,0,0,0,1,0,1];
  }

  function get_cheaters_round(round_index) {
    if (round_index < 0) {
      throw "no round_index provided";
    }
    // GET CHEATERS FOR ROUND I
    // READY FROM FILE / Python

    // READ who cheated in round from index
    // create cheater array from that

    var round_cheaters = cheating_record_json[round_index];
    console.log(round_cheaters);
    var cheaters_addr = [];
    for (var i=0; i<round_cheaters.length; i++) {
      var c = round_cheaters[i];
      if (c) {
        cheaters_addr.push(accounts[i]);
      }
    }
    console.log(cheaters_addr);

    return cheaters_addr;
  }
  get_cheaters_round(0);

  it("should save the address of the creator as the owner var ", function() {
    var serviceFactory;
    // this retreives a deployed contract already...
    // first we retrieved the Factory contract (which creates instances of SensingService)
    ServiceFactory.deployed().then(function(instance) {
      serviceFactory = instance;
      // returns transaction
      return serviceFactory.newSensingService(helpers_list, sensing_band, bandwidth_granularity, _costPerRound, {from:owner_su} );
    }).then(function(tx_obj) {
      // now we have created a new SensingService contract instance... retrieve it and then run some tests.
      var sensingService;
      console.log(tx_obj.logs[0].args);
      var new_contract_address = tx_obj.logs[0].args.serviceAddr;
      SensingService.at(new_contract_address).then(function(instance) {
        sensingService = instance;
        return sensingService.owner_su.call({from: owner_su});
      }).then(function(address) {
          assert.equal(address, owner_su, "owner_su wasn't the owner of the contract");
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

  it(" recieveSensingData from all helpers, complete round, and validate it", function() {
    var serviceFactory;
    var roundId;
    var round_using = 0;

    ServiceFactory.deployed().then(function(instance) {
      serviceFactory = instance;
      return serviceFactory.newSensingService(helpers_list, sensing_band, bandwidth_granularity, _costPerRound, {from:owner_su} );

    }).then(function(tx_obj) {


      // now we have created a new SensingService contract instance... retrieve it and then run some tests.
      var sensingService;
      console.log(tx_obj.logs[0].args);
      var new_contract_address = tx_obj.logs[0].args.serviceAddr;
      SensingService.at(new_contract_address).then(function(instance) {
        sensingService = instance;

        //if (web3.eth.fromWei(web3.eth.getBalance(SLA.address)) < 5) {
        console.log("increasing funds for sensingContract from owner's account");
        return sensingService.increaseFunds({from: owner_su, value: web3.toWei(_relativeCostPerRound*3, "ether") });

      }).then(function(tx_obj) {
        console.log(tx_obj);
        // execute as a Transaction (need to make changes to data on blockchain)
        console.log("sending account1 "+accounts[1]+" data to contract");
        return sensingService.helperNotifyDataSent(accounts[1], round_using, {from: owner_su});


      }).then(function(tx_obj) {
        console.log(tx_obj);
        for (var i = 0; i < tx_obj.logs.length; i++) {
          var log = tx_obj.logs[i];
          console.log(log.event);
        }
        assert.equal(tx_obj.logs[0].event, "NewRoundCreated", "Invalid event occured");
        console.log("Round id:");
        console.log(tx_obj.logs[0].args);
        roundId = tx_obj.logs[0].args.roundId;

        console.log("sending account2 "+accounts[2]+" data to contract");
        // execute as a Transaction (need 2 make changes)
        return sensingService.helperNotifyDataSent(accounts[2], round_using, {from: owner_su});

      }).then(function(tx_obj) {
        console.log("checking if RoundCompleted and NotifyUsersToValidate events occurred");
        console.log(tx_obj);
        for (var i = 0; i < tx_obj.logs.length; i++) {
          var log = tx_obj.logs[i];
          console.log(log.event);
        }
        assert.equal(tx_obj.logs[0].event, "RoundCompleted", "Invalid event occured");
        assert.equal(tx_obj.logs[1].event, "NotifyUsersToValidate", "Invalid event occured");
        // now send the users data for validation
        console.log("send list of cheaters for this round");
        //return sensingService.setSensingDataForRound(accounts[1], get_sensing_data(), roundId, {from: owner_su});
        var r_index = 0;
        var cheaters = get_cheaters_round(r_index);
        console.log(cheaters);
        //return sensingService.set_helpers_cheaters(cheaters, r_index, {from: owner_su});
        return sensingService.penalize_cheaters(cheaters, r_index, {from: owner_su});


      }).then(function(tx_obj) {
        console.log("checking ValidatedRound event occured" );
        console.log(tx_obj);
        for (var i = 0; i < tx_obj.logs.length; i++) {
          var log = tx_obj.logs[i];
          console.log(log.event);
        }
        if (tx_obj.logs[0]) {
          assert.equal(tx_obj.logs[0].event, "ValidatedRound", "Invalid event occured");
          console.log(tx_obj.logs[0].args);
        } else {
          assert("no events fired");
        }

        // TEST DONE
        console.log("Account1 is withdrawing their credits (getting ether)");
        return  sensingService.withdraw({from:accounts[1]});

      }).then(function(tx_obj) {
        console.log("checking withdraw event occured" );
        console.log(tx_obj);
        for (var i = 0; i < tx_obj.logs.length; i++) {
          var log = tx_obj.logs[i];
          //console.log(log.event);
        }
        assert.equal(tx_obj.logs[0].event, "Payout", "Invalid event occured");
        // TEST DONE
        console.log("DONE - SUCCESS");
        return  sensingService.withdraw({from:accounts[2]});

      }).then(function(tx_obj) {
        console.log("checking withdraw event occured" );
        console.log(tx_obj);
        for (var i = 0; i < tx_obj.logs.length; i++) {
          var log = tx_obj.logs[i];
        //  console.log(log.event);
        }
        assert.equal(tx_obj.logs[0].event, "Payout", "Invalid event occured");
        // TEST DONE
        console.log("DONE - SUCCESS");

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
