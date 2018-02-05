function [ cheating_record ] = evaluate( helper_data, index, result )
%EVALUATE Summary of this function goes here
%   Detailed explanation goes here
    
%EVALUATE WHICH HELPER HAS CHEATED
    for i = 1 : size(helper_data,1)
        if  helper_data(i,index) == result
            cheating_record(i) = 0;
        else
            cheating_record(i) = 1;
        end
    end
end

