clear all
SIM_LENGTH = 10000;                                                          %simulation length in seconds
SENSE_INT = 1;                                                                  %Sensing interval
HELPER_INT = 1;                                                                 %With what frequency helpers send data
NO_OF_HELPERS = 3;                                                             %no of helpers
PU_activity = zeros(1,SIM_LENGTH);                                          %transmission activity of Primary User (1,0)
SU_activity = zeros(1,SIM_LENGTH);                                          %transmission activity of Secondary User (1,0)
SUSS_activity = zeros(1,SIM_LENGTH);                                        %transmission activity of Secondary User Spectrum Sensing (1,0)
Cheating_record = zeros(SIM_LENGTH/HELPER_INT,NO_OF_HELPERS);                             %Keep record of cheaters and when (1,0)
helper_data = zeros(NO_OF_HELPERS,SIM_LENGTH);                                 %sensing data from helpers (1,0)
CHEATERS = 1;                                                               %Binary activation variable if we want to include cheaters or not 0/1
B = 1;
%bandwidth


%% Randomize Primary User Activity
%generate a random number X between 0-50
%if it's larger than 25 --> PU active else inactive
%add next X values with 1 (active) or 0 (inactive) until array is full
count = 1;
while (count < size(PU_activity,2))
    random = round(rand(1)*20);
    if  random > 10
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

%% Randomize PU Activity with Markov Chains
 transition_probabilities = [0.9 0.1;0.1 0.9];
 chain = zeros(1,SIM_LENGTH);
    chain(1)=1;
    for i=2:SIM_LENGTH
        this_step_distribution = transition_probabilities(chain(i-1),:);
        cumulative_distribution = cumsum(this_step_distribution);
        r = rand();
        chain(i) = find(cumulative_distribution>r,1);
    end
    
    %1 = 0, 2 = 1 
    chain(chain == 1) = 0;
    chain(chain == 2) = 1;
    
    PU_activity = chain;

%% traditional case
for j = 1 : 200
    
    SENSE_INT = j;
    for i = 1 : SENSE_INT : SIM_LENGTH - SENSE_INT
        %if PU inactive, SU can transmit until next check
        if PU_activity(i) == 0
            SU_activity(1, (i + 1) : i + (SENSE_INT - 1)) = 1;
        end
    end
    
    [no_of_collisions(j) SU_activity_new] = collision(SU_activity, PU_activity);
    sum(SU_activity)
    sum(SU_activity_new)
    SU_throughput(j) = sum(B*SU_activity_new)/SIM_LENGTH;
    %normalize
    SU_throughput(j) = SU_throughput(j) * (1 / (1 - (sum(PU_activity)/SIM_LENGTH)));
    lost_opportunities(j) = lost_opp(PU_activity, SU_activity);
end

figure(1)
plot(1:size(SU_throughput,2), SU_throughput)
xlabel('Sensing interval (s)');
ylabel('Throughput (ratio)');
figure(2)
plot(1:size(no_of_collisions,2), no_of_collisions)
xlabel('Sensing interval (s)');
ylabel('No. of collisions');
figure(3)
plot(1:size(lost_opportunities,2), lost_opportunities)
xlabel('Sensing interval (s)');
ylabel('Lost opportunuties');


%% Helpers Sensing Case

if CHEATERS == 0 %cheaters don't exist
    
    %basically copy pu_data to helper data
    for i = 1 : NO_OF_HELPERS
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
        [no_of_collisionsSS(j) SUSS_activity_new] = collision(SUSS_activity, PU_activity);
        SUSS_throughput(j) = sum(B*SUSS_activity)/SIM_LENGTH;
        %normalize
        SUSS_throughput(j) = SUSS_throughput(j) * (1 / (1 - (sum(PU_activity)/SIM_LENGTH)));
        lost_opportunities(j) = lost_opp(PU_activity, SUSS_activity);
    end
    
    figure(4)
    plot(1:size(SUSS_throughput,2), SUSS_throughput)
    xlabel('Sensing interval (s)');
    ylabel('Throughput (bps)');
    title('Throughput with helpers and without cheaters');
    ylim([0 1])
    figure(5)
    plot(1:size(no_of_collisionsSS,2), no_of_collisionsSS)
    xlabel('Sensing interval (s)');
    ylabel('No. of collisions');
    title('Collisions with helpers and without cheaters');
    figure(6)
    plot(1:size(lost_opportunities,2), lost_opportunities)
    xlabel('Sensing interval (s)');
    ylabel('Lost opportunuties');
    
else %cheaters exist
    %change number of cheaters
    for z = 1 : floor(NO_OF_HELPERS / 2) %can never be majority of cheaters. RIGHT?!?!
        for i = 1 : NO_OF_HELPERS
            helper_data(i,:) = PU_activity(1,:);
        end
        cheater = datasample(1:NO_OF_HELPERS,z,'Replace',false); %randomize the cheaters (sample data without replacement)
        
        for i = 1 : size(cheater,2)
            helper_data(i,:) = round(rand(1,SIM_LENGTH));
        end
        
        for j = 1 : 200
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
                Cheating_record(k,:) = evaluate(helper_data, k, busy)'; %evalute who's been cheating
            end
            [no_of_collisionsSS(j) SUSS_activity_new] = collision(SUSS_activity, PU_activity);
            SUSS_throughput(j) = sum(B*SUSS_activity)/SIM_LENGTH;
            %normalize
            SUSS_throughput(j) = SUSS_throughput(j) * (1 / (1 - (sum(PU_activity)/SIM_LENGTH)));
            lost_opportunities(j) = lost_opp(PU_activity, SUSS_activity);
        end
    end
    figure(4)
    plot(1:size(SUSS_throughput,2), SUSS_throughput)
    xlabel('Sensing interval (s)');
    ylabel('Throughput (bps)');
    ylim([0 1])
    title('Throughput with cheating helpers (minority)');
    figure(5)
    plot(1:size(no_of_collisionsSS,2), no_of_collisionsSS)
    title('Collisions with helpers');
    xlabel('Sensing interval (s)');
    ylabel('No. of collisions');
    figure(6)
    plot(1:size(lost_opportunities,2), lost_opportunities)
    xlabel('Sensing interval (s)');
    ylabel('Lost opportunuties');
end


%% Generate files
PU_activity_outfile = savejson('',PU_activity,'PU_activity.json');
SU_activity_outfile = savejson('',SUSS_activity,'SU Activity.json');
Cheating_record_outfile = savejson('', Cheating_record, 'Cheating Record.json');
