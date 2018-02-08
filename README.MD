SLA to Offload Spectrum Sensing - to other nodes to increase efficiency of devices utilizing cognitive radio

Forked from https://arxiv.org/abs/1703.04502

# Setup
1. Install [TruffleJS](https://github.com/trufflesuite/truffle)
2. Install [Ganache](http://truffleframework.com/ganache/) - run a local Ethereum blockchain to run tests, execute commands, and inspect state

# How to Run
1. start Ganache
2. In a new Terminal window, run:
3. cd "project download directory where truffle.js lives"
4. truffle compile
5. truffle migrate (this will 'connect' to your local instance of Ethereum (Ganache), utilizing the dev settings in truffle.js)
6. truffle test
7. truffle exec  js/simulation.js

# How to run simulations / scenarios
7. npm install
8. truffle exec  js/simulation.js

# Example:
Loquat:sla-solidity milean$ truffle exec  js/simulation.js <br>
Using network 'development'.<br>
<br>
Starting with owner:<br>
0x627306090abab3a6e1400e9345bc60c78a8bef57<br>
Starting with helpers:<br>
[ '0xf17f52151ebef6c7334fad080c5704d77216b732',<br>
  '0xc5fdf4076b8f3a5357c5e395ab970b5b54098fef' ]<br>
Starting with sensing_band 10 bandwidth_granularity 100 costPerRound 1000000000000000000<br>
newSensingService()<br>
got new SensingService contract at 0xf2beae25b23f0ccdd234410354cb42d08ed54981<br>
increasing funds for sensingContract from owner's account<br>
<br>
set interval to run at 2000<br>
Connection successful<br>
Requesting node: default<br>
Running round 0<br>
events:<br>
NewRoundCreated<br>
RoundCompleted<br>
NotifyUsersToValidate<br>
IncrementedAmountOwed<br>
IncrementedAmountOwed<br>
^C

# Some notes on Ethereum Blockchain, solidity, spectrum sensing, etc
Contracts are like objects in OOP. Each new "transaction" would result in a new Contract being made between interested parties.
When a user has finished sensing the spectrum, it will call methods on this contract object to send the result back to the original SU.
This will trigger the payment of the original user to the one who did the work.


Contracts are stored on the blockchain (database) as "Executable code", and other people can interact with it, depending on their role. This is what happens when you call 'truffle migrate', it moves the code onto the blockchain specified in the config (truffle.js)
