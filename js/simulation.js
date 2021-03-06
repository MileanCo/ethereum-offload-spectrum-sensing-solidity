//import {shuffle} from './shuffle.js';
var shuffle = require('./shuffle.js');

module.exports = function(callback) {
  // load web3 to interact with the blockchain
  var Web3 = require('web3')
  if (typeof web3 != 'undefined') {
    web3 = new Web3(web3.currentProvider);
  } else {
    web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:7545'));
  }
  var assert = require('assert');
  var accounts = web3.eth.accounts;

  //
  // START CONFIG
  //
  var sensing_band = 10;
  var bandwidth_granularity = 100;
  var owner_su = accounts[0];
  var helpers_list = [
    accounts[1],
    accounts[2],
    //accounts[3],
    //accounts[4],
    /*,
    accounts[5],
    accounts[6],
    accounts[7],
    accounts[8],
    accounts[9],
    accounts[10]*/
  ];
  var TOTAL_ROUNDS_TO_RUN = 10;
  var ROUND_SLEEP_SECONDS = 3;
  //
  // END CONFIG
  //


  var data = {
    round_index : 0,
    helpers:{},
    su : {
      gasUsed : 0
    },
    rounds:{

    }
  };

  // Set data for each helper being used
  for (var i=0;i<helpers_list.length;i++) {
    data.helpers[helpers_list[i]] = {gasUsed:0, times_cheated:0};
  }
  console.log(data);

  const _relativeCostPerRound = 1;
  const _costPerRound = web3.toWei(_relativeCostPerRound, "ether");

  console.log("Starting with owner:");
  console.log(owner_su);
  console.log("Starting with helpers:");
  console.log(helpers_list);
  console.log("Starting with sensing_band %s bandwidth_granularity %s _costPerRound %s", sensing_band, bandwidth_granularity, _costPerRound);

  // READ CHEATING RECORD JSON FILE
  var fs = require('fs');
  var contents = fs.readFileSync('test/Cheating_Record.json', 'utf8');
  var cheating_record_json = JSON.parse(contents);

  function get_cheaters_round(round_index) {
    if (round_index < 0) {
      throw "no round_index provided";
    }

    // READ who cheated in round from index
    // create cheater array from that
    var round_cheaters = cheating_record_json[round_index];
    //console.log(round_cheaters);
    var cheaters_addr = [];
    for (var i=0; i<round_cheaters.length; i++) {
      var c = round_cheaters[i];
      var helper_index = i + 1; // +1 b/c [0] = su_owner
      if (c) {
        if (helper_index > helpers_list.length) {
          throw ("cannot use an account that is not in helpers_list");
        }
        cheaters_addr.push(accounts[helper_index]);
      }
    }

    return cheaters_addr;
  }

  // deploy contract and register provider
  var ServiceFactoryContract = artifacts.require("./ServiceFactory.sol");
  var SensingServiceContract = artifacts.require("./SensingService.sol");

  var serviceFactory;
  var sensingService;

  ServiceFactoryContract.deployed().then(function(instance) {
    serviceFactory = instance;
    // returns transaction
    console.log("newSensingService()");
    //address[] helpers, uint _sensing_band, uint _bandwidth_granularity, uint _costPerRound
    return serviceFactory.newSensingService(helpers_list, sensing_band, bandwidth_granularity, _costPerRound, {from:owner_su} );
  }).then(function(tx_obj) {
      console.log(tx_obj);
      // now we have created a new SensingService contract instance... retrieve it and then run some tests.
      console.log(tx_obj.logs[0]);
      var new_contract_address = tx_obj.logs[0].args.serviceAddr;
      console.log("got new SensingService contract at " + new_contract_address);
      SensingServiceContract.at(new_contract_address).then(function(instance) {
        sensingService = instance;
        //if (web3.eth.fromWei(web3.eth.getBalance(SLA.address)) < 5) {
        console.log("increasing funds for sensingContract from owner's account");
        var needed_balance = _relativeCostPerRound * TOTAL_ROUNDS_TO_RUN * (helpers_list.length+1);
        return sensingService.increaseFunds({from: owner_su, value: web3.toWei(needed_balance, "ether") });
      }).then(function(tx_obj) {
        console.log(tx_obj);
        main();
      }).catch(
        function(error) {
          console.log(error);
      });
  // errors for Factory
  }).catch( function(error) {
      console.log(error);
      assert.fail();
  });

  var main_round_loop;
  function main() {
    // Enter here the name of the node you want to listen to (eg dub, bcn0, bcn1, etc.)
    node_name = "default"

    var WebSocket = require('ws');
    var ws = new WebSocket('ws://airscope.ie:8080/','ascope');
    ws.on('open', function() {
      console.log("Connection successful");
      ws.send(node_name);
      console.log("Requesting node: " + node_name);
    });
    var is_first = true;
    var tput_values = [];

    var time_interval = 1 * ROUND_SLEEP_SECONDS * 1000; // interval in ms over which compute the throughput
    console.log("set interval to run at " + time_interval);
    // launch this inside a Fiber so we can do synchronous calls (no callback hell)
    main_round_loop = setInterval(run_round, time_interval);

    ws.on('message', function(data, flags) {
      if (is_first) {
        // First message is list of available nodes
        is_first = false;
      } else {
        var parsed = JSON.parse(data);
        //console.log(parsed);
      }
    });
  }

  // https://ethereum.stackexchange.com/questions/4027/how-do-you-get-the-balance-of-an-account-using-truffle-ether-pudding
  const promisify = (inner) =>
    new Promise((resolve, reject) =>
      inner((err, res) => {
        if (err) { reject(err) }
        resolve(res);
      })
    );
  const getBalance = (account, at) =>
    promisify(cb => web3.eth.getBalance(account, at, cb));


  async function run_round() {
    if (data.round_index > TOTAL_ROUNDS_TO_RUN) {
      console.log("\n############\n LAST ROUND REACHED " + data.round_index);
      await pay_rounds();
      //throw("DONE");
      clearInterval(main_round_loop);
      data.TOTAL_ROUNDS_TO_RUN = TOTAL_ROUNDS_TO_RUN;
      console.log(data);
      console.log(data.rounds);
      return;
    }

    data.rounds[data.round_index] = {};
    // randomly reorder array to simulate different arrival times of messages from helpers
    var helpers_list_reordered = shuffle.shuffle(helpers_list.slice());

    for (var i=0; i < helpers_list_reordered.length; i++) {
      data.rounds[data.round_index][helpers_list_reordered[i]] = {};
      //var index = i;
      console.log("sensingService.helperNotifyDataSent + i " + i);
      //sensingService.helperNotifyDataSent(helpers_list[i], data.round_index, {from: helpers_list[i]} ).then(function(tx_obj) {
      var tx_obj = await sensingService.helperNotifyDataSent(helpers_list_reordered[i], data.round_index, {from: helpers_list_reordered[i]} );
      console.log(tx_obj);
      // find which helper this is
      var helper_addr = helpers_list_reordered[i];

      // add usage data for charts
      var cheaters = get_cheaters_round(i);
      data.helpers[helper_addr].gasUsed += tx_obj.receipt.gasUsed;
      data.rounds[data.round_index][helpers_list_reordered[i]].gasUsed = tx_obj.receipt.gasUsed;
      data.rounds[data.round_index][helpers_list_reordered[i]].ether = await getBalance(helpers_list_reordered[i]);
      data.rounds[data.round_index][helpers_list_reordered[i]].ether = web3.fromWei(data.rounds[data.round_index][helpers_list_reordered[i]].ether);
      if (cheaters.indexOf(helpers_list_reordered[i]) >= 0) {
        data.rounds[data.round_index][helpers_list_reordered[i]].cheated = 1;
      }

      if (i==0) {
        assert.equal(tx_obj.logs[0].event, "NewRoundCreated");
        console.log(tx_obj.logs[0].event);
        var id = tx_obj.logs[0].args.round_index;
        console.log("new round from solidity: " + id.toNumber());
        console.log(tx_obj.logs[1]);
      // if it's the last i
      } else if (i == helpers_list_reordered.length-1){
        //console.log(tx_obj);
        assert.equal(tx_obj.logs[0].event, "RoundCompleted");
        console.log(tx_obj.logs[0].event);
        assert.equal(tx_obj.logs[1].event, "NotifyUsersToValidate");
        console.log(tx_obj.logs[1].event);
        console.log(tx_obj.logs[2].event);
        console.log(tx_obj.logs[3].event);
      }
    }

    data.round_index++;
  };

  async function pay_rounds() {
    // iterate through all rounds and penalize accordingly
    for (var i=0; i < TOTAL_ROUNDS_TO_RUN; i++) {
      var cheaters = get_cheaters_round(i);
      console.log("Checking cheaters for round " + i);
      console.log("Cheaters: " + cheaters);
      var tx_obj = await sensingService.penalize_cheaters(cheaters, i, {from: owner_su});
      if (tx_obj.logs[0]) {
        console.log(tx_obj.logs[0].event);
      }
      data.su.gasUsed += tx_obj.receipt.gasUsed;

      if (cheaters[0]) {
        console.log(tx_obj.logs[0].event);
        console.log(tx_obj.logs[0].args.amount_owed.toNumber());
      }
      update_helper_data_for(cheaters);
      console.log("\n");
    }
    // now helpers withdraw from their accounts
    await helpers_withdraw_amount_owed();

  }

  async function helpers_withdraw_amount_owed() {
    for (var i=0; i < helpers_list.length; i++) {
      var tx_obj = await sensingService.withdraw({from:helpers_list[i]});

      if (tx_obj.logs[0]) {
        console.log(tx_obj.logs[0].event);
        var amount_owned = tx_obj.logs[0].args.amount_owed;
        console.log("Amount owed withdrawn: " + amount_owned.toNumber() + " from helper " + helpers_list[i] );
      } else {
        console.log("No money to withdraw from this round (penalized)");
      }
      var helper_addr = helpers_list[i];
      data.helpers[helper_addr].gasUsed += tx_obj.receipt.gasUsed;

    }
  }
  // iterate through cheaters and decrement their amount_owed if caught
  function update_helper_data_for(cheaters) {
    for (var i=0; i < cheaters.length; i++) {
      data.helpers[cheaters[i]].times_cheated += 1;
    }
    return true;
  }
}
