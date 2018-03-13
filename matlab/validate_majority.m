function [ pu_status ] = validate( index, helper_data )
%VALIDATE Summary of this function goes here
%   Detailed explanation goes here

%validate here if PU Band is busy or not from the different helper values
        for i = 1 : size(helper_data,1)
           values(i) = helper_data(i,index); 
        end
        
%here the mean itself is the wrong values, since (majority)cheater data is fed as negation of PU        
        if mean(values) > 0.5
            pu_status = 1;
        else
            pu_status = 0;
        end
            
end

