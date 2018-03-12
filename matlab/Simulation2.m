clear all

mc_index=3;

for n=1:mc_index                                                           %Montecarlo -change mc_index to higher value for better averaging  
SIM_LENGTH = 10000;                                                        %simulation length in seconds
SENSE_INT = 1;                                                             %Sensing interval
HELPER_INT = 1;                                                            %With what frequency helpers send data
NO_OF_HELPERS = 6;                                                         %no of helpers
PU_activity = zeros(1,SIM_LENGTH);                                         %transmission activity of Primary User (1,0)
SU_activity = zeros(1,SIM_LENGTH);                                         %transmission activity of Secondary User (1,0)
SUSS_activity = zeros(1,SIM_LENGTH);                                       %transmission activity of Secondary User Spectrum Sensing (1,0)
Cheating_record = zeros(SIM_LENGTH/HELPER_INT,NO_OF_HELPERS);              %Keep record of cheaters and when (1,0)
helper_data = zeros(NO_OF_HELPERS,SIM_LENGTH);                             %sensing data from helpers (1,0)
B = 1;                                                                     %bandwidth


%% Randomize Primary User Activity
%generate a random number X between 0-25
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
 transition_probabilities =[0.1 0.9;0.1 0.9] ; %[ 1|1 0|1 ; 1|0 0|0] %case1(low PU activity)-[0.1 0.9;0.1 0.9] %case2(high PU activity)-[0.7 0.3;0.7 0.3] 
 chain = zeros(1,SIM_LENGTH);
    chain(1)=1;
    for i=2:SIM_LENGTH
        this_step_distribution = transition_probabilities(chain(i-1),:);
        cumulative_distribution = cumsum(this_step_distribution);
        r = rand();
        chain(i) = find(cumulative_distribution>r,1);
    end
    
    %1 = 1, 2 = 0 
    chain(chain == 1) = 1;
    chain(chain == 2) = 0;
    
    PU_activity = chain;                      % chain represents PU actvity with markov chain 

%% traditional case
for j = 1 : 25
    
    SENSE_INT = j;
    for i = 1 : SENSE_INT : SIM_LENGTH - SENSE_INT
        %if PU inactive, SU can transmit until next check
        if PU_activity(i) == 0
            SU_activity(1, (i + 1) : i + (SENSE_INT - 1)) = 1;
        end
    end
    
    [no_of_collisions(j) , SU_activity_new, PU_activity_new] = collision(SU_activity, PU_activity);
    sum(SU_activity);
    sum(SU_activity_new);
    SU_throughput(j) = sum(B*SU_activity_new)/SIM_LENGTH;
    PU_throughput(j) = sum(B*PU_activity_new)/SIM_LENGTH;
    %normalize
    SU_throughput(j) = SU_throughput(j) * (1 / (1 - (sum(PU_activity)/SIM_LENGTH)));
    lost_opportunities(j) = lost_opp(PU_activity, SU_activity);
    [collisions_prob(j)] = collision_probability(SU_activity, PU_activity);
end
SU_throughput_traditional(n,:) = SU_throughput;
no_of_collisions_traditional(n,:) = no_of_collisions;    
lost_opportunities_traditional(n,:) =  lost_opportunities;
collisions_prob_tradtional(n,:)= collisions_prob;
PU_throughput_traditional(n,:) = PU_throughput;

%% Helpers Sensing Case
SU_activity = zeros(1,SIM_LENGTH);                                          %transmission activity of Secondary User (1,0)
SUSS_activity = zeros(1,SIM_LENGTH);                                        %transmission activity of Secondary User Spectrum Sensing (1,0)
Cheating_record = zeros(SIM_LENGTH/HELPER_INT,NO_OF_HELPERS);               %Keep record of cheaters and when (1,0)
helper_data = zeros(NO_OF_HELPERS,SIM_LENGTH);              
PU_activity = chain;
    
    %basically copy pu_data to helper data
    for i = 1 : NO_OF_HELPERS
        helper_data(i,:) = PU_activity(1,:);
    end
    
    for j = 1 : 25
        HELPER_INT = j;
        for  k = 1 : HELPER_INT : SIM_LENGTH - HELPER_INT
            if helper_data(1,k) == 0
                SUSS_activity(1, k : k + (HELPER_INT - 1)) = 1;
            else
                SUSS_activity(1, k : k + (HELPER_INT - 1)) = 0;
            end
        end
    [no_of_collisionsSS(j) ,SUSS_activity_new, PU_activity_new ] = collision(SUSS_activity, PU_activity);
    SUSS_throughput(j) = sum(B*SUSS_activity_new)/SIM_LENGTH;
    PU_throughput(j) = sum(B*PU_activity_new)/SIM_LENGTH;
    %normalize
    SUSS_throughput(j) = SUSS_throughput(j) * (1 / (1 - (sum(PU_activity)/SIM_LENGTH)));
    lost_opportunities(j) = lost_opp(PU_activity, SUSS_activity);
    [collisions_prob(j)] = collision_probability(SUSS_activity, PU_activity);
    end
    SUSS_throughput_ss(n,:) = SUSS_throughput;
    no_of_collisionsSS_ss(n,:) = no_of_collisionsSS;    
    lost_opportunities_ss(n,:) =  lost_opportunities;
    collisions_prob_ss(n,:)= collisions_prob;   
    PU_throughput_ss(n,:) = PU_throughput;
    
%% Minority Cheaters
SU_activity = zeros(1,SIM_LENGTH);                                          %transmission activity of Secondary User (1,0)
SUSS_activity = zeros(1,SIM_LENGTH);                                        %transmission activity of Secondary User Spectrum Sensing (1,0)
Cheating_record = zeros(SIM_LENGTH/HELPER_INT,NO_OF_HELPERS);               %Keep record of cheaters and when (1,0)
helper_data = zeros(NO_OF_HELPERS,SIM_LENGTH);              
PU_activity = chain;

    for z = 1 : floor(NO_OF_HELPERS / 2) 
        for i = 1 : NO_OF_HELPERS
            helper_data(i,:) = PU_activity(1,:);
        end
        cheater = datasample(1:NO_OF_HELPERS,z,'Replace',false);           %randomize the cheaters (sample data without replacement)
        
        for i = 1 : size(cheater,2)
            helper_data(i,:) = round(rand(1,SIM_LENGTH));
        end
        
        for j = 1 : 25
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
        [no_of_collisionsSS(j), SUSS_activity_new, PU_activity_new] = collision(SUSS_activity, PU_activity);
        SUSS_throughput(j) = sum(B*SUSS_activity_new)/SIM_LENGTH;
        PU_throughput(j) = sum(B*PU_activity_new)/SIM_LENGTH;
        %normalize
        SUSS_throughput(j) = SUSS_throughput(j) * (1 / (1 - (sum(PU_activity)/SIM_LENGTH)));
        lost_opportunities(j) = lost_opp(PU_activity, SUSS_activity);
        [collisions_prob(j)] = collision_probability(SUSS_activity, PU_activity);
        end
    end
    SUSS_throughput_minority(n,:) = SUSS_throughput;
    no_of_collisionsSS_minority(n,:) = no_of_collisionsSS;    
    lost_opportunities_minority(n,:) =  lost_opportunities;
    collisions_prob_minority(n,:)= collisions_prob;
    PU_throughput_minority(n,:) =PU_throughput;
   
%% Majority Cheater case
SU_activity = zeros(1,SIM_LENGTH);                                          %transmission activity of Secondary User (1,0)
SUSS_activity = zeros(1,SIM_LENGTH);                                        %transmission activity of Secondary User Spectrum Sensing (1,0)
Cheating_record = zeros(SIM_LENGTH/HELPER_INT,NO_OF_HELPERS);               %Keep record of cheaters and when (1,0)
helper_data = zeros(NO_OF_HELPERS,SIM_LENGTH);              
PU_activity = chain;

for z = floor(NO_OF_HELPERS / 2)+1: NO_OF_HELPERS 
        for i = 1 : NO_OF_HELPERS
            helper_data(i,:) = PU_activity(1,:);
        end
          cheater = datasample(1:NO_OF_HELPERS,z,'Replace',false); %randomize the cheaters (sample data without replacement)
     
          for i = 1 : size(cheater,2)
             helper_data(i,:) = ~PU_activity(1,:); %malicious data - opposite of PU activity at all instants of time
          end

          for j = 1 : 25
            HELPER_INT = j;
            for  k = 1 : HELPER_INT : SIM_LENGTH - HELPER_INT
                %validate the helper data to find out whether the PU band
                %is busy or not
                PU_status = validate_majority(k, helper_data);
                if PU_status == 0
                    SUSS_activity(1, k : k + (HELPER_INT - 1)) = 1;
                else
                    SUSS_activity(1, k : k + (HELPER_INT - 1)) = 0;
                end
                Cheating_record(k,:) = evaluate(helper_data, k, PU_activity)'; %evalute who's been cheating
            end
        [no_of_collisionsSS(j), SUSS_activity_new, PU_activity_new] = collision(SUSS_activity, PU_activity);
        SUSS_throughput(j) = sum(B*SUSS_activity_new)/SIM_LENGTH;
        PU_throughput(j) = sum(B*PU_activity_new)/SIM_LENGTH;
        %normalize
        SUSS_throughput(j) = SUSS_throughput(j) * (1 / (1- (sum(PU_activity)/SIM_LENGTH)));
        lost_opportunities(j) = lost_opp(PU_activity, SUSS_activity);
        [collisions_prob(j)] = collision_probability(SUSS_activity, PU_activity);
        end
end
SUSS_throughput_majority(n,:) = SUSS_throughput;
no_of_collisionsSS_majority(n,:) = no_of_collisionsSS;    
lost_opportunities_majority(n,:) =  lost_opportunities;
collisions_prob_majority(n,:)= collisions_prob;
PU_throughput_majority(n,:)= PU_throughput;
end

%%%Plots

%Throughput
figure(1)
    plot(1:size(SU_throughput_traditional,2), sum(SU_throughput_traditional)/n)
    title('Normalized SU Throughput Variation with sensing interval')
    xlabel('Sensing interval (s)');
    ylabel('Throughput (ratio)');
    ylim([0 1.2])
    xlim([1 25])
    hold on
    plot(1:size(SUSS_throughput_ss,2), sum(SUSS_throughput_ss)/n,'--')
    plot(1:size(SUSS_throughput_minority,2), sum(SUSS_throughput_minority)/n,'-x')    
    plot(1:size(SUSS_throughput_majority,2), sum(SUSS_throughput_majority)/n,'-o')
    hold off
legend('traditional','Spectrum Sensing','minority','majority','northeastoutside')  
    

%Collision probabilty
figure(2)
    plot(1:size(collisions_prob_tradtional,2),sum(collisions_prob_tradtional)/n)
    title('Collision Probability')
    xlabel('Sensing interval');
    ylabel('No. of Collisions / No. of Tx attempts');
    xlim([1 25])
    ylim([0 1.2])
    hold on
    plot(1:size(collisions_prob_ss,2),sum(collisions_prob_ss)/n,'--')
    plot(1:size(collisions_prob_minority,2),sum(collisions_prob_minority)/n,'-x')
    plot(1:size(collisions_prob_majority,2),sum(collisions_prob_majority)/n,'-o')
    hold off;
legend('traditional','Spectrum Sensing','minority','majority','northeastoutside')  
       
%Lost opportunities
figure(3)
   plot(1:size(lost_opportunities_traditional,2), sum(lost_opportunities_traditional)/n)
    title('No. of Lost Opportunites with sensing interval')
    xlabel('Sensing interval (s)');
    ylabel('Lost opportunuties');    
    xlim([1 25])
    hold on
    plot(1:size(lost_opportunities_ss,2), sum(lost_opportunities_ss)/n,'--')
    plot(1:size(lost_opportunities_minority,2), sum(lost_opportunities_minority)/n,'-x')
    plot(1:size(lost_opportunities_majority,2), sum(lost_opportunities_majority)/n,'-o')
    hold off;
legend('traditional','Spectrum Sensing','minority','majority','northeastoutside')  


%PU Throughput variation
figure(4)
    plot(1:size(PU_throughput_traditional,2), sum(PU_throughput_traditional)/n)
    title('PU Throughput Variation with sensing interval')
    xlabel('Sensing interval (s)');
    ylabel('Throughput (ratio)');
    xlim([1 25])
    xlim([1 size(PU_throughput_traditional,2)])
    hold on
    plot(1:size(PU_throughput_ss,2), sum(PU_throughput_ss)/n,'--')
    plot(1:size(PU_throughput_minority,2), sum(PU_throughput_minority)/n,'-x')
    plot(1:size(PU_throughput_majority,2), sum(PU_throughput_majority)/n,'-o')
    hold off;
legend('traditional','Spectrum Sensing','minority','majority','northeastoutside')  


%Collisions
figure(5)
    plot(1:size(no_of_collisions_traditional,2), sum(no_of_collisions_traditional)/n)
    title('No. of Collisions with sensing interval ')
    xlabel('Sensing interval (s)');
    ylabel('No. of collisions');
    xlim([1 25])
    hold on
    plot(1:size(no_of_collisionsSS_ss,2), sum(no_of_collisionsSS_ss)/n,'--')
    plot(1:size(no_of_collisionsSS_minority,2), sum(no_of_collisionsSS_minority)/n,'-x')    
    plot(1:size(no_of_collisionsSS_majority,2), sum(no_of_collisionsSS_majority)/n,'-o')
    hold off;
legend('traditional','Spectrum Sensing','minority','majority','northeastoutside')  

%% Generate files
% % PU_activity_outfile = savejson('',PU_activity,'PU_activity.json');
% % SU_activity_outfile = savejson('',SUSS_activity,'SU Activity.json');
% % Cheating_record_outfile = savejson('', Cheating_record, 'Cheating Record.json');
