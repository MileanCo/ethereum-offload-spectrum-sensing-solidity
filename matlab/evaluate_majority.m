function [ cheating_record_majority ] = evaluate_majority( helper_data, index, pu_activity )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
for i = 1 : size(helper_data,1)
        if  helper_data(i,index) == pu_activity
            cheating_record_majority(i) = 0;
        else
            cheating_record_majority(i) = 1;
        end
    end


end

