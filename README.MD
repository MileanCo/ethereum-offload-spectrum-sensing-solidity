SLA to Offload Spectrum Sensing - to other nodes to increase efficiency of devices utilizing cognitive radio

Forked from https://arxiv.org/abs/1703.04502

# Setup
1. Install [TruffleJS](https://github.com/trufflesuite/truffle)
2. Install [TestRPC](https://github.com/ethereumjs/testrpc)

# How to Run
1. In a Terminal window, run 'testrpc'
2. In a new Terminal window, run:
3. truffle compile
4. truffle migrate (this will 'connect' to your local instance of Ethereum (testrpc), utilizing the dev settings in truffle.js)
5. truffle test

# How to run simulations / scenarios
6. npm install
7. node js/client.js

# Example:
Loquat:sla-solidity milean$ truffle compile

Loquat:sla-solidity milean$ truffle migrate

Using network 'development'.

Network up to date.

Loquat:sla-solidity milean$

Loquat:sla-solidity milean$ node js/client.js

Balance of account 0: 99.629911599999734558

Balance of account 1: 100.0080582

Connection successful

Requesting node: default

Parsed Downlink throughput: 0.22

Parsed Downlink throughput: 0.21

Parsed Downlink throughput: 0.66

Parsed Downlink throughput: 1.07

Avg throughput over 5 seconds: 0.54

Payment notification event fired.

Parsed Downlink throughput: 0.2

Parsed Downlink throughput: 0.21

Parsed Downlink throughput: 0.59

Parsed Downlink throughput: 1.08

Parsed Downlink throughput: 0.8

Avg throughput over 5 seconds: 0.576

Payment notification event fired.

Parsed Downlink throughput: 0.4

Parsed Downlink throughput: 0.49

Parsed Downlink throughput: 4.02

Parsed Downlink throughput: 1.67

Parsed Downlink throughput: 0.78

Avg throughput over 5 seconds: 1.472

Payment notification event fired.

Parsed Downlink throughput: 1.03

^C

# Some notes on Ethereum Blockchain, solidity, spectrum sensing, etc
Contracts are like objects in OOP. Each new "transaction" would result in a new Contract being made between interested parties.
When a user has finished sensing the spectrum, it will call methods on this contract object to send the result back to the original SU.
This will trigger the payment of the original user to the one who did the work.


Contracts are stored on the blockchain (database) as "Executable code", and other people can interact with it, depending on their role. This is what happens when you call 'truffle migrate', it moves the code onto the blockchain specified in the config (truffle.js)
