function [ collision_prob] = collision_probability( SU_activity, PU_activity )
%COLLISION Summary of this function goes here
%   Detailed explanation goes here
    no_collisions = 0;
    no_tx_att = 0;
   
    %if both have been active during the same time slot
for i = 1 : size(SU_activity,2)
    if SU_activity(1,i) == 1 && PU_activity(1,i) == 1
       no_collisions = no_collisions + 1;
       
    end
    if SU_activity(1,i) == 1 && PU_activity(1,i) == 0
       no_tx_att = no_tx_att + 1;   
    end
    
end

collision_prob= ((no_collisions) / (no_tx_att + no_collisions)); 