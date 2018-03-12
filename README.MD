SLA to Offload Spectrum Sensing - to other nodes to increase efficiency of devices utilizing cognitive radio

Forked from https://arxiv.org/abs/1703.04502

# Setup
1. Install [TruffleJS](https://github.com/trufflesuite/truffle)
2. Install [Ganache](http://truffleframework.com/ganache/) - run a local Ethereum blockchain to run tests, execute commands, and inspect state
3. Install [NodeJS](https://nodejs.org/en/) > version 9

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
<br>
The simulation script runs for about 10 rounds, where for each round every Helper sends the SU their share of spectrum data, and notifies the contract this has been done. This increases the Helper's amount_owed in the contract. For each of these rounds, a cheater is identified. The cheater's amount_owed is decremented everytime they are "detected" (in test/Cheating_Record.json). At the end of the 10 rounds, each Helper calls withdraw() on the contract to get their amount_owed of money from the SU (SU initially puts in some Ether (money) for the contract to spend). <br>

The config of the simulation.js is in lines ~17-33.
<br>

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
...
Payout<br>
Amount owed withdrawn: 5000000000000000000 from helper 0xf17f52151ebef6c7334fad080c5704d77216b732<br>
Payout<br>
Amount owed withdrawn: 11000000000000000000 from helper 0xc5fdf4076b8f3a5357c5e395ab970b5b54098fef<br>
{ round_index: 11,<br>
  helpers: <br>
   { '0xf17f52151ebef6c7334fad080c5704d77216b732': { gasUsed: 1233808, times_cheated: 6 },<br>
     '0xc5fdf4076b8f3a5357c5e395ab970b5b54098fef': { gasUsed: 1209540, times_cheated: 0 } },<br>
  su: { gasUsed: 276936 },<br>
...
^C

# Some notes on Ethereum Blockchain, solidity, spectrum sensing, etc
Contracts are like objects in OOP. Each new "transaction" would result in a new Contract being made between interested parties.
When a user has finished sensing the spectrum, it will call methods on this contract object to send the result back to the original SU.
This will trigger the payment of the original user to the one who did the work.


Contracts are stored on the blockchain (database) as "Executable code", and other people can interact with it, depending on their role. This is what happens when you call 'truffle migrate', it moves the code onto the blockchain specified in the config (truffle.js)

# Instructions for the matlab files
## SETUP

1. Extract the folder containing the matlab codes.
2. Make sure all the files are extracted in the same location.

## HOW TO RUN

1. Open the mat file 'Simulation2.m'. This is the source mat file with calls to different functions.
2. Set the 'mc_index' to desired value to obtain required number of monte carlo iterations.
3. Set the 'transition_probabilities' under the '%% Randomize PU Activity with Markov Chains' section to obtain different PU activity scenarios.
   The probability matrix is defined as [1|1  0|1 ; 1|0  0|0] .So, for example , low PU activity of 10% ON would be [0.1 0.9 ;0.1 0.9].
4. Click on 'RUN'.
5. The simulation results(5 plots) are generated after sometime.


## Additional Pointers
1. There are totally 9 mat files (1 source and 8 functions) - Simulation2 (source) , validate, validate_majority, evaluate, evaluate_majority, collision, collision_majority, collision_probability and lost_opp.
2. Comments are provided within the source file for easy readability purposes.
3. Functions
   validate/validate_majority - It computes the average result of helper matrices to determine the PU activity state.
   evaluate/evaluate_majority - It evaluates the presence of cheaters and identifies them in a 'cheating record' matrix.
   collision/collision_majority - It computes the no. of collisions of SU with PU.
   collision_probability - It computes the ratio (no_collisions) / (no_tx_attempts + no_collisions) to determine the probability of collisions when SU is transmitting.
   Lost_opp -It computes the TX opportunities lost by SU when PU activity is 0.
