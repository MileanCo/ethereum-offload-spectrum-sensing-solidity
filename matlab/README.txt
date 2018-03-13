SETUP

1. Extract the folder containing the matlab codes.
2. Make sure all the files are extracted in the same location.

HOW TO RUN

1. Open the mat file 'Simulation2.m'. This is the source mat file with calls to different functions.
2. Set the 'mc_index' to desired value to obtain required number of monte carlo iterations.
3. Set the 'transition_probabilities' under the '%% Randomize PU Activity with Markov Chains' section to obtain different PU activity scenarios.
   The probability matrix is defined as [1|1  0|1 ; 1|0  0|0] .So, for example , low PU activity of 10% ON would be [0.1 0.9 ;0.1 0.9].
4. Click on 'RUN'.
5. The simulation results(5 plots) are generated after sometime.


Additional Pointers
1. There are totally 9 mat files (1 source and 8 functions) - Simulation2 (source) , validate, validate_majority, evaluate, evaluate_majority, collision, collision_majority, collision_probability and lost_opp.
2. Comments are provided within the source file for easy readability purposes.
3. Functions
   validate/validate_majority - It computes the average result of helper matrices to determine the PU activity state.
   evaluate/evaluate_majority - It evaluates the presence of cheaters and identifies them in a 'cheating record' matrix.
   collision/collision_majority - It computes the no. of collisions of SU with PU.
   collision_probability - It computes the ratio (no_collisions) / (no_tx_attempts + no_collisions) to determine the probability of collisions when SU is transmitting.
   Lost_opp -It computes the TX opportunities lost by SU when PU activity is 0.