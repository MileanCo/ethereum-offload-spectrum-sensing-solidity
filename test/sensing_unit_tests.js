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
    return SensingService.deployed().then(function(instance) {
      console.log("sending account1 data to contract");
      instance.setSensingData(accounts[1], get_sensing_data());

      console.log("sending account2 data to contract");
      instance.setSensingData(accounts[2], get_sensing_data());



    }).then(function(tx_id) {
      console.log(tx_id);

    }).catch(function(error){
      console.log(error);
      assert.fail();
    });
  });



});
