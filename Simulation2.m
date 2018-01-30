clear all
SIM_LENGTH = 10000;                                                          %simulation length in seconds
SENSE_INT = 1;                                                                  %Sensing interval
HELPER_INT = 1;                                                                 %With what frequency helpers send data
NO_HELPERS = 3;                                                             %no of helpers
PU_activity = zeros(1,SIM_LENGTH);                                          %transmission activity of Primary User (1,0)
SU_activity = zeros(1,SIM_LENGTH);                                          %transmission activity of Secondary User (1,0)
SUSS_activity = zeros(1,SIM_LENGTH);                                        %transmission activity of Secondary User Spectrum Sensing (1,0)
Cheating_record = zeros(NO_HELPERS,SIM_LENGTH);                             %Keep record of cheaters and when (1,0)
helper_data = zeros(NO_HELPERS,SIM_LENGTH);                                 %sensing data from helpers (1,0)
CHEATERS = 0;                                                               %Binary activation variable if we want to include cheaters or not 0/1
B = 10^7;
%bandwidth


%% Randomize Primary User Activity
%generate a random number X between 0-50
%if it's larger than 25 --> PU active else inactive
%add next X values with 1 (active) or 0 (inactive) until array is full
count = 1;
while (count < size(PU_activity,2))
    random = round(rand(1)*50);
    if  random > 25
        %just to make sure array does not extend
        if count + random > size(PU_activity,2)
            PU_activity(1,count : size(PU_activity,2)) = 1;
        else
            PU_activity(1,count : count + random) = 1;
        end
    else
        if count + random > size(PU_activity,2)
            PU_activity(1,count : size(PU_activity,2)) = 0;
        else
            PU_activity(1,count : count + random) = 0;
        end
    end
    count = count + random;
end


%% traditional case
for j = 1 : 200
    SENSE_INT = j;
    for i = 1 : SENSE_INT : SIM_LENGTH - SENSE_INT
        %if PU inactive, SU can transmit until next check
        if PU_activity(i) == 0
            SU_activity(1, (i + 1) : i + (SENSE_INT - 1)) = 1;
        end
    end
    
    SU_throughput(j) = sum(B*SU_activity)/SIM_LENGTH;
    no_of_collisions(j) = collision(SU_activity, PU_activity);
end

figure(1)
plot(1:size(SU_throughput,2), SU_throughput)
xlabel('Sensing interval (s)');
ylabel('Throughput (bps)');
figure(2)
plot(1:size(no_of_collisions,2), no_of_collisions)
xlabel('Sensing interval (s)');
ylabel('No. of collisions');


%% Spectrum Sensing Case

if CHEATERS == 0 %cheaters don't exist
    
    %basically copy pu_data to helper data
    for i = 1 : NO_HELPERS
        helper_data(i,:) = PU_activity(1,:);
    end
    
    for j = 1 : 200
        HELPER_INT = j;
        for  k = 1 : HELPER_INT : SIM_LENGTH - HELPER_INT
            if helper_data(1,k) == 0
                SUSS_activity(1, k : k + (HELPER_INT - 1)) = 1;
            else
                SUSS_activity(1, k : k + (HELPER_INT - 1)) = 0;
            end
        end
        SUSS_throughput(j) = sum(B*SUSS_activity)/SIM_LENGTH;
        no_of_collisionsSS(j) = collision(SUSS_activity, PU_activity);
    end
    
    figure(3)
    plot(1:size(SUSS_throughput,2), SUSS_throughput)
    xlabel('Sensing interval (s)');
    ylabel('Throughput (bps)');
    figure(4)
    plot(1:size(no_of_collisionsSS,2), no_of_collisionsSS)
    xlabel('Sensing interval (s)');
    ylabel('No. of collisions');
    
else %cheaters exist
    %change number of cheaters
    for z = 1 : floor(NO_HELPERS / 2) %can never be majority of cheaters. RIGHT?!?!
        for i = 1 : NO_HELPERS
            helper_data(i,:) = PU_activity(1,:);
        end
        cheater = datasample(1:NO_HELPERS,z,'Replace',false); %randomize the cheaters (sample data without replacement)
        
        for i = 1 : size(cheater,2)
            helper_data(i,:) = round(rand(1,SIM_LENGTH));
        end
        
        for j = 1 : 50
            HELPER_INT = j;
            for  k = 1 : HELPER_INT : SIM_LENGTH - HELPER_INT
                %validate the helper data to find out whether the PU band
                %is busy or not
                busy = validate(k, helper_data);
                if busy == 0
                    SUSS_activity(1, k : k + (HELPER_INT - 1)) = 1;
                else
                    SUSS_activity(1, k : k + (HELPER_INT - 1)) = 0;
                end
                Cheating_record = evaluate(helper_data, Cheating_record, k, busy); %evalute who's been cheating
            end
            SUSS_throughput(j) = sum(B*SUSS_activity)/SIM_LENGTH;
            no_of_collisionsSS(j) = collision(SUSS_activity, PU_activity);
        end
    end
    figure(1)
    plot(1:size(SUSS_throughput,2), SUSS_throughput)
    xlabel('Sensing interval (s)');
    ylabel('Throughput (bps)');
    figure(2)
    plot(1:size(no_of_collisionsSS,2), no_of_collisionsSS)
    xlabel('Sensing interval (s)');
    ylabel('No. of collisions');
end



