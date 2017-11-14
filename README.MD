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


# Some notes on Ethereum Blockchain, solidity, spectrum sensing, etc
Contracts are like objects in OOP. Each new "transaction" would result in a new Contract being made between interested parties.
When a user has finished sensing the spectrum, it will call methods on this contract object to send the result back to the original SU.
This will trigger the payment of the original user to the one who did the work.

Contracts are stored on the blockchain (database) as "Executable code", and other people can interact with it, depending on their role. This is what happens when you call 'truffle migrate', it moves the code onto the blockchain specified in the config (truffle.js)
