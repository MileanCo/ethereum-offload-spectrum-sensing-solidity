// console.log(sla_artifacts);
// load web3 to interact with the blockchain
var Web3 = require('web3')
if (typeof web3 != 'undefined') {
  web3 = new Web3(web3.currentProvider);
} else {
  web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));
}
var accounts = web3.eth.accounts;
var owner = accounts[0];
var provider = accounts[1];
// deploy contract and register provider
const sla_artifacts = require('../build/contracts/SLA.json')
const contract = require('truffle-contract')
let SLA = contract(sla_artifacts);
SLA.setProvider(web3.currentProvider);
var sla;
return SLA.deployed().then(function(instance){
  sla = instance;
  return sla.registerProvider(provider, 0, 0, 1, {from: owner});
}).then(function(registeredTx){
  console.log("Balance of account 0: %s", web3.eth.getBalance(accounts[0]).toString(10));
  console.log("Balance of account 1: %s", web3.eth.getBalance(accounts[1]).toString(10));
  // watch for payout notifications
  return payoutEvent = sla.PeriodicPayout([{_provider: provider}], function(error, result){
    if (!error) {
      console.log('New PeriodicPayout event caught for an average throughput of %d Kbps, withdrawing', result.args._trafficInKb);
      sla.withdraw({from: provider}).then(function(withdrawTx){
        console.log("New balance of account 1: %s", web3.eth.getBalance(accounts[1]).toString(10));
      }).catch(function(error) {
        console.log(error);
      });
    } else {
      console.log(error);
    }
  });
}).catch(function(error){
  console.log(error);
});
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
setInterval(avgThroughput, time_interval);
ws.on('message', function(data, flags) {
  if (is_first) {
    // First message is list of available nodes
    is_first = false;
  } else {
    var parsed = JSON.parse(data);
    var throughput = parseFloat(parsed[1].values[0].value)  // * 1024 // Mbps to Kbps
    // console.log('Message from server: %s ', data)
    console.log('Parsed Downlink throughput: %d ', throughput);
    tput_values.push(throughput);
  }
});

function avgThroughput() {
  var avg_t = tput_values.reduce((x, y) => x + y) / tput_values.length;
  console.log('Avg throughput over %d seconds: %d', time_interval / 1000, avg_t)
  tput_values = [];
  if (avg_t > 0)  {
    payout(avg_t);
  }
}

function payout(throughput) {
  return SLA.deployed().then(function(instance) {
    instance.notifyPayment(provider, throughput * 1024, {from: owner});
  }).catch(function(error){
    console.log(error);
  });
}