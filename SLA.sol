pragma solidity ^0.4.0;
contract SLA {

    struct Provider {
        string locationAddress;
        uint costPerKb;
        uint penaltyPerMb;
        uint debit;
        uint infractions;
        // any other relevant parameter to identify the small cell provider
    }
    
    address owner;
    mapping(address => Provider) providers;
    mapping (address => uint) pendingWithdrawals;
    uint constant maxInfractions = 3;
    
    event InsufficientThroughput(address indexed _provider, 
                               uint indexed _timestamp,
                               uint _amountInMb);
    event PeriodicPayout(address indexed _provider,
                         uint indexed _timestamp,
                         uint trafficInKb);
    event InsufficientFunds(uint indexed _timestamp);
    event BlockedProvider(address indexed _provider, 
                          uint indexed _timestamp);

    /// Create a new SLA contract, specifies the address of the owner
    function SLA() {
        owner = msg.sender;
    }
    
    modifier ownerOnly {
        if(msg.sender != owner) { 
            throw;
        }
        _;
    }
    
    /// Add a new small cell provider to the list
    function registerProvider(address _provider, string _location, 
                 uint _costPerKb, uint _penaltyPerMb) ownerOnly returns(bool) {
        // Check if a provider with that address was already registered
        if (providers[_provider].costPerKb != 0) {
            return false;
        }
        providers[_provider] = Provider({locationAddress: _location, 
            costPerKb: _costPerKb, penaltyPerMb: _penaltyPerMb, debit: 0,
            infractions: 0
        });
        return true;
    }
    
    /* Notify the provider of its credit for the amount of traffic observed. 
     * Uses the withdraw pattern to minimize security risks. Note that we first
     * deduct from any outstanding debit from the provider (e.g. due to breaches)
     */
    function notifyPayment(address _provider, uint _trafficInKb) ownerOnly {
        uint payment = providers[_provider].costPerKb * _trafficInKb;
        if (providers[_provider].debit >= payment) {
            providers[_provider].debit -= payment;
        } else if (providers[_provider].debit > 0) {
            uint difference = payment - providers[_provider].debit;
            providers[_provider].debit = 0;
            pendingWithdrawals[_provider] += difference;
        } else {
            pendingWithdrawals[_provider] += payment;
        }
        PeriodicPayout(_provider, block.timestamp, _trafficInKb);
    }

    /* Allows providers to withdraw any outstanding credit after the firing of
     * a PeriodicPayout event
     */
    function withdraw() public returns(bool) {
        uint amount = pendingWithdrawals[msg.sender];
        if (amount == 0)
            return true;
        pendingWithdrawals[msg.sender] = 0;
        if (msg.sender.send(amount)) {
            return true;
        } else {
            pendingWithdrawals[msg.sender] = amount;
            InsufficientFunds(block.timestamp);
            return false;
        }
    }
    
    /* Top up the balance of the contract so that providers can withdraw funds 
     * to receive payment for the traffic they served.
     */
    function increaseFunds() payable {}
    
    /* Notify the provider of a capacity breach in the SLA. 
     * Deducts the penalty from the pending withdrawals if sufficient, or 
     * increases the debit amount of the provider otherwise.
     */
    function throughputBreach(address _provider, 
                              uint _amountInMb) ownerOnly returns(bool) {
        InsufficientThroughput(_provider, block.timestamp, _amountInMb);
        providers[_provider].infractions += 1;
        if (providers[_provider].infractions >= maxInfractions) {
            blockProvider(_provider);
        }
        uint payment = providers[_provider].penaltyPerMb * _amountInMb;
        if (pendingWithdrawals[_provider] >= payment) {
            pendingWithdrawals[_provider] -= payment;
            return true;
        } else {
            uint difference = payment - pendingWithdrawals[_provider];
            pendingWithdrawals[_provider] = 0;
            providers[_provider].debit += difference;
        }
    }
    
    /* block a provider, effectively removing it from the list */
    function blockProvider(address _provider) ownerOnly {
        delete providers[_provider];
        BlockedProvider(_provider, block.timestamp);
    }
}