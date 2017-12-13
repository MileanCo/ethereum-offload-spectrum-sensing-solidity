var SensingService = artifacts.require("./SensingService.sol");

contract('SensingService', function(accounts) {

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

  function get_new_contract() {
    return SensingService.deployed().then(
        function(instance) {
          return instance.owner.call({
            from: accounts[0],
            helpers: helpers_list,
            sensing_band:sensing_band,
            bandwidth_granularity:bandwidth_granularity
          });
    });
  }

  function get_sensing_data() {
    return [0,1,0,1,1,1,1,0,0,0,1,0,1];
  }

  it("should save the address of the creator as the owner var ", function() {
    get_new_contract().then(
        function(address) {
          assert.equal(address, accounts[0], "accounts[0] wasn't the owner of the contract");
    }).catch(
        function(error) {
          console.log(error);
          assert.fail();
    });
  });

  it(" recieveSensingData from account 1", function() {
    var sensing_service;
    return SensingService.deployed().then(function(instance) {
      sensing_service = instance;
      console.log("sending account1 data to contract");
      var promise = sensing_service.setSensingData(accounts[1], get_sensing_data());
      return promise;

    }).then(function(tx_id) {
      console.log(tx_id);
      console.log("sending account2 data to contract");
      return sensing_service.setSensingData(accounts[2], get_sensing_data());

    }).then(function(event_tx_id) {
      console.log(event_tx_id);
      console.log("checking if payout events occurred");

      for (var i = 0; i < event_tx_id.logs.length; i++) {
        var log = event_tx_id.logs[i];
        console.log(log.event);
        if (log.event == "Payout") {
          found = true;
          console.log("WIN");
          //assert.equal(log.args._tputInKbps.toNumber(), amount);
          break;
        }
      }

      //return instance.setSensingData(accounts[2], get_sensing_data());

    }).catch(function(error){
      console.log(error);
      assert.fail();
    });
  });



});
