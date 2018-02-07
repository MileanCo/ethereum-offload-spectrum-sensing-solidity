function [ result  ] = validate( index, helper_data )
%VALIDATE Summary of this function goes here
%   Detailed explanation goes here

%validate here if PU Band is busy or not from the different helper values
        for i = 1 : size(helper_data,1)
           values(i) = helper_data(i,index); 
        end
        
        if mean(values) > 0.5
            result = 1;
        else
            result = 0;
        end
            
end

