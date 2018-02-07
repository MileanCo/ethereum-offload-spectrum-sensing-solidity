// console.log(sla_artifacts);
// load web3 to interact with the blockchain
var Web3 = require('web3')
if (typeof web3 != 'undefined') {
  web3 = new Web3(web3.currentProvider);
} else {
  web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));
}
var accounts = web3.eth.accounts;
var owner_su = accounts[0];
var helpers_list = [
  accounts[1],
  accounts[2],
  //accounts[3],
];

//const _costPerKbps = web3.toWei(1, 'szabo');

// READ CHEATING RECORD JSON FILE
var fs = require('fs');
var contents = fs.readFileSync('test/Cheating_Record.json', 'utf8');
var cheating_record_json = JSON.parse(contents);
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
// test this works
get_cheaters_round(0);

// deploy contract and register provider
//const sla_artifacts = require('../build/contracts/SLA.json')
const ServiceFactory_artifacts = require('../build/contracts/ServiceFactory.json')
const SensingService_artifacts = require('../build/contracts/SensingService.json')
const contract = require('truffle-contract');

let ServiceFactory = contract(ServiceFactory_artifacts);
let SensingService = contract(SensingService_artifacts);
ServiceFactory.setProvider(web3.currentProvider);
SensingService.setProvider(web3.currentProvider);
var serviceFactory;
var sensingService;



ServiceFactory.deployed().then(function(instance) {
  serviceFactory = instance;
  // returns transaction
  return serviceFactory.newSensingService(helpers_list, sensing_band, bandwidth_granularity, _costPerRound, {from:owner_su} );
}).then(function(tx_obj) {
    // now we have created a new SensingService contract instance... retrieve it and then run some tests.
    console.log(tx_obj.logs[0].args);
    var new_contract_address = tx_obj.logs[0].args.serviceAddr;
    SensingService.at(new_contract_address).then(function(instance) {
      sensingService = instance;
      //if (web3.eth.fromWei(web3.eth.getBalance(SLA.address)) < 5) {
      console.log("increasing funds for sensingContract from owner's account");
      return sensingService.increaseFunds({from: owner_su, value: web3.toWei(_relativeCostPerRound*3, "ether") });
    }).catch(
      function(error) {
        console.log(error);
    });
// errors for Factory
}).catch(
  function(error) {
    console.log(error);
    //assert.fail();
});

//hej

// Enter here the name of the node you want to listen to (eg dub, bcn0, bcn1, etc.)
node_name = "default"
time_interval = 1 * 5 * 1000; // interval in ms over which compute the throughput
var WebSocket = require('ws');
var ws = new WebSocket('ws://airscope.ie:8080/','ascope');
ws.on('open', function() {
  console.log("Connection successful");
  ws.send(node_name);
  console.log("Requesting node: " + node_name);
});
var is_first = true;
var tput_values = [];

setInterval(run_round, time_interval);
ws.on('message', function(data, flags) {
  if (is_first) {
    // First message is list of available nodes
    is_first = false;
  } else {
    var parsed = JSON.parse(data);
    console.log(parsed);
  }
});

var round_index = 0;
function run_round() {
  return sensingService.helperNotifyDataSent(helpers_list[0], {from: owner_su})
    .then(function() {
      sensingService.helperNotifyDataSent(helpers_list[1], {from: owner_su})
        .then(function() {
          sensingService.set_helpers_cheaters(get_cheaters_round[round_index], round_index, {from: owner_su});
          round_index ++;
          payout();
        })
      })
    });

  /**
  var avg_t = tput_values.reduce((x, y) => x + y) / tput_values.length;
  console.log('Avg throughput over %d seconds: %d', time_interval / 1000, avg_t)
  tput_values = [];
  if (avg_t > 0)  {
    payout(avg_t);
  }*/
}

function payout(throughput) {
  return  sensingService.withdraw({from:helpers_list[1]})
    .then( function() {
        sensingService.withdraw({from:helpers_list[1]})
    });

  /*
  var kbps_tput = throughput * 1024;
  return sla.notifyPayment(provider, kbps_tput, {from: owner})
  .then(function(notify_txid){
    console.log("Payment notification event fired.");
  }).catch(function(error){
    console.log(error);
  });*/
}
