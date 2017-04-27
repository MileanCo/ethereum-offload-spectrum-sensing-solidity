pragma solidity ^0.4.0;
contract SLA {

    struct Provider {
        uint id;
        uint costPerKbps;
        uint penaltyPerKbps;
        uint debit;
        uint infractions;
        // any other relevant parameter to identify the small cell provider
    }

    address public _owner;
    mapping(address => Provider) providers;
    mapping (address => uint) public pendingWithdrawals;
    uint constant maxInfractions = 3;

    event InsufficientThroughput(address indexed _provider,
                               uint indexed _timestamp,
                               uint indexed _qci,
                               uint _amountInKbps);
    event PeriodicPayout(address indexed _provider,
                         uint indexed _timestamp,
                         uint _tputInKbps,
                         uint _payment);
    event InsufficientFunds(uint indexed _timestamp);
    event RegisteredProvider(address indexed _provider,
                             uint indexed _id,
                             uint indexed _timestamp);
    event BlockedProvider(address indexed _provider,
                          uint indexed _timestamp);
    event OwnershipChange(address indexed _newOwner);

    /// Create a new SLA contract, specifies the address of the owner
    function SLA() {
        _owner = msg.sender;
    }

    modifier ownerOnly {
        if(msg.sender != _owner) {
            throw;
        }
        _;
    }

    /// Add a new small cell provider to the list
    function registerProvider(address _provider, uint _id,
                 uint _costPerKbps, uint _penaltyPerKbps) public ownerOnly returns(bool) {
        // Check if a provider with that address was already registered
        if (providers[_provider].costPerKbps != 0) {
            return false;
        }
        // Check that _costPerKbps and _penaltyPerKbps are positive
        if (_costPerKbps <= 0 || _penaltyPerKbps <= 0) {
            return false;
        }
        // Register the new provider
        providers[_provider] = Provider({id: _id,
            costPerKbps: _costPerKbps, penaltyPerKbps: _penaltyPerKbps, debit: 0,
            infractions: 0
        });
        RegisteredProvider(_provider, _id, block.timestamp);
        return true;
    }

    /* Notify the provider of its credit for the amount of traffic observed.
     * Uses the withdraw pattern to minimize security risks. Note that we first
     * deduct from any outstanding debit from the provider (e.g. due to breaches)
     */
    function notifyPayment(address _provider, uint _tputInKbps) ownerOnly {
        // Check that a provider with that address was previously registered
        if (providers[_provider].costPerKbps == 0) {
            throw;
        }
        uint payment = providers[_provider].costPerKbps * _tputInKbps;
        if (providers[_provider].debit >= payment) {
            providers[_provider].debit -= payment;
            PeriodicPayout(_provider, block.timestamp, _tputInKbps, 0);
        } else if (providers[_provider].debit > 0) {
            uint difference = payment - providers[_provider].debit;
            providers[_provider].debit = 0;
            pendingWithdrawals[_provider] += difference;
            PeriodicPayout(_provider, block.timestamp, _tputInKbps, difference);
        } else {
            pendingWithdrawals[_provider] += payment;
            PeriodicPayout(_provider, block.timestamp, _tputInKbps, payment);
        }

    }

    /* Allows providers to withdraw any outstanding credit after the firing of
     * a PeriodicPayout event
     */
    function withdraw() public returns(bool) {
        uint amount = pendingWithdrawals[msg.sender];
        if (amount <= 0)
            return false;
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

    /* Notify the provider of a throughput breach in the SLA.
     * Deducts the penalty from the pending withdrawals if sufficient, or
     * increases the debit amount of the provider otherwise.
     */
    function throughputBreach(address _provider, uint _qci,
                              uint _amountInKbps) ownerOnly returns(bool) {
        // Check that a provider with that address was previously registered
        if (providers[_provider].costPerKbps == 0) {
            return false;
        }
        InsufficientThroughput(_provider, block.timestamp, _qci, _amountInKbps);
        providers[_provider].infractions += 1;
        if (providers[_provider].infractions >= maxInfractions) {
            blockProvider(_provider);
            return true;
        }
        uint payment = providers[_provider].penaltyPerKbps * _amountInKbps;
        if (pendingWithdrawals[_provider] >= payment) {
            pendingWithdrawals[_provider] -= payment;
        } else {
            uint difference = payment - pendingWithdrawals[_provider];
            pendingWithdrawals[_provider] = 0;
            providers[_provider].debit += difference;
        }
        return true;
    }

    /* block a provider, effectively removing it from the list */
    function blockProvider(address _provider) ownerOnly {
        // Check that a provider with that address was already registered
        if (providers[_provider].costPerKbps == 0) {
            throw;
        }
        delete providers[_provider];
        BlockedProvider(_provider, block.timestamp);
    }

    // Destroy the contract and return funds to owner
    function selfDestruct() public ownerOnly {
      selfdestruct(_owner);
    }

    // Change ownership of the contract
    function changeOwner(address _newOwner) public ownerOnly {
      if (_owner != _newOwner) {
        _owner = _newOwner;
        OwnershipChange(_newOwner);
      }
    }
}
