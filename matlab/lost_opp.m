function [ lost_opp ] = lost_opp( PU_activity, SU_activity )
%LOST_OPP Summary of this function goes here
%   Detailed explanation goes here
    lost_opp = 0;
    for i = 1 : size(PU_activity,2)
        if PU_activity(1,i) == 0 && SU_activity(1,i) == 0
           lost_opp = lost_opp + 1; 
        end
    end

