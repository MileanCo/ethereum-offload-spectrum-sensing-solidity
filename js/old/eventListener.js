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
  // watch for payout notifications
  return payoutEvent = sla.PeriodicPayout([{_provider: provider}], function(error, result){
    if (!error) {
      console.log('New PeriodicPayout event caught for an average throughput of %d Kbps, withdrawing', result.args._tputInKbps.toNumber());
      sla.withdraw({from: provider}).then(function(withdrawTx){
        console.log("New balance of account 1: %s", web3.fromWei(web3.eth.getBalance(accounts[1])).toString(10));
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
