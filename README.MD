SLA to Offload Spectrum Sensing - to other nodes to increase efficiency of devices utilizing cognitive radio

Forked from https://arxiv.org/abs/1703.04502

# Setup
1. Install [TruffleJS](https://github.com/trufflesuite/truffle)
2. Install [TestRPC](https://github.com/ethereumjs/testrpc)

# How to Run
1. In a Terminal window, run 'testrpc'
2. In a new Terminal window, run:
3. cd ~project download directory where truffle.js lives~
4. truffle compile
5. truffle migrate (this will 'connect' to your local instance of Ethereum (testrpc), utilizing the dev settings in truffle.js)
6. truffle test

# How to run simulations / scenarios
6. npm install
7. node js/client.js

# Example:
Loquat:sla-solidity milean$ truffle compile<br>

Loquat:sla-solidity milean$ truffle migrate<br>
Using network 'development'.<br>
Network up to date.<br>
Loquat:sla-solidity milean$<br>
Loquat:sla-solidity milean$ node js/client.js<br>
Balance of account 0: 99.629911599999734558<br>
Balance of account 1: 100.0080582<br>
Connection successful<br>
Requesting node: default<br>
Parsed Downlink throughput: 0.22<br>
Parsed Downlink throughput: 0.21<br>
Parsed Downlink throughput: 0.66<br>
Parsed Downlink throughput: 1.07<br>
Avg throughput over 5 seconds: 0.54<br>
Payment notification event fired.<br>
Parsed Downlink throughput: 0.2<br>
Parsed Downlink throughput: 0.21<br>
Parsed Downlink throughput: 0.59<br>
Parsed Downlink throughput: 1.08<br>
Parsed Downlink throughput: 0.8
<br>Avg throughput over 5 seconds: 0.576
<br>Payment notification event fired.
<br>Parsed Downlink throughput: 0.4
<br>Parsed Downlink throughput: 0.49
<br>Parsed Downlink throughput: 4.02
<br>Parsed Downlink throughput: 1.67
<br>Parsed Downlink throughput: 0.78
<br>Avg throughput over 5 seconds: 1.472
<br>Payment notification event fired.
<br>Parsed Downlink throughput: 1.03<br>
^C

# Some notes on Ethereum Blockchain, solidity, spectrum sensing, etc
Contracts are like objects in OOP. Each new "transaction" would result in a new Contract being made between interested parties.
When a user has finished sensing the spectrum, it will call methods on this contract object to send the result back to the original SU.
This will trigger the payment of the original user to the one who did the work.


Contracts are stored on the blockchain (database) as "Executable code", and other people can interact with it, depending on their role. This is what happens when you call 'truffle migrate', it moves the code onto the blockchain specified in the config (truffle.js)
