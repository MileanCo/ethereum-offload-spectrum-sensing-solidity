function [ no_collisions, SU_activity ] = collision_majority( SU_activity, PU_activity )
%COLLISION Summary of this function goes here
%   Detailed explanation goes here
    no_collisions = 0;
    
    %if both have been active during the same time slot
for i = 1 : size(SU_activity,2)
    if SU_activity(1,i) == 1 && PU_activity(1,i) == 1
       no_collisions = no_collisions + 1;
       SU_activity(1,i) = 0;
       PU_activity(1,i)= 0;
    end
end

