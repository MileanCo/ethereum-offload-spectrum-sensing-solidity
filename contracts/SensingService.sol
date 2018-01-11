pragma solidity ^0.4.0;
contract SensingService {
    struct HelperProvider {
        uint id;
        // what the Helper is owed for sensing
        uint debit;
        // Number of times Penalized for cheating (or bad matrix)
        uint infractions;
    }

    struct SensingRound {
      address[] helpersReceived;
      //uint max_helpers_needed;
      mapping(address => SpectrumData) spectrum_data;
      uint round_id;
    }

    struct SpectrumData {
      uint[] data;
      uint timestamp_received;
    }

    uint public minSensingDuration = 2; //seconds for Helper to send response of sensing results
    uint public sensing_band;
    uint public bandwidth_granularity;
    // address of SU
    address public owner;
    uint number_helpers;

    event Payout(address indexed _provider,
                    uint indexed _timestamp
                        // uint _payment);
                  );

    // EVENTS for testing purposes, notify when a new SensingRound is started/created
    event NewRoundCreated(uint indexed round_id);
    event RoundDeleted(uint indexed round_id);

    // Useful events
    event NotifyHelpersToValidate(uint indexed round_id);

    // mapping = "Hash", with the Eth Account Address as the 'key' into this 'array'
    // http://solidity.readthedocs.io/en/develop/types.html#mappings
    mapping (address => HelperProvider) helperProviders;
    mapping (uint => address) providerIndex;

    SensingRound[] rounds;



    // SU creates a new contract
    function SensingService(address[] helpers, uint _sensing_band, uint _bandwidth_granularity) public {
        owner = msg.sender;
        sensing_band = _sensing_band;
        bandwidth_granularity = _bandwidth_granularity;

        // for each helper in helpers; register helper
        for (uint i=0; i<helpers.length; i++) {
          address h_addr = helpers[i];
          _registerHelper(h_addr, i);
        }
    }

    modifier ownerOnly {
        if(msg.sender != owner) {
            throw;
        }
        // wtf is this... required though
        _;
    }

    // Add a new Helper to this contract
    function _registerHelper(address _provider, uint _id) private returns(bool) {
      // TODO: check the input parameters
      helperProviders[_provider].id = _id;
      helperProviders[_provider].debit = 0;
      helperProviders[_provider].infractions = 0;


      uint provider_ID = number_helpers++;
      providerIndex[provider_ID] = _provider;

      return true;
    }

    function notifySensingDataSent(address _helper) public returns(bool) {
      // GET ROUND_INDEX DESIRED
      // insert this data in the first available round
      uint round_index = 0;
      for (uint i=0; i < rounds.length; i++) {
        SensingRound storage round = rounds[i];
        round_index = i;

        bool round_free = true;
        // Iterate thru this SensingRound's Helpers to see if it's occupied by this address
        for (uint j=0; j < round.helpersReceived.length; j++) {
          address other_helper = round.helpersReceived[j];
          if (other_helper == _helper) {
            round_free = false;
            // We found it
            break;
          }
        }
        // found round to insert in, exit loop
        if (round_free) {
          break;
        }
      }

      // no round exists? create a new one
      // can't check for NULL or 0, so we have to compare the index to size of array
      if (round_index >= rounds.length) {
        address[] memory helpers_received = new address[](1);
        // create new SensingRound
        SensingRound memory new_round = SensingRound({
          helpersReceived : helpers_received,
          round_id : round_index
        });
        rounds.push(new_round);
        // create new event to notify
        NewRoundCreated(round_index);
      }

      // Add this Helper to the SensingRound selected
      rounds[round_index].helpersReceived.push(_helper);

      if (rounds[round_index].helpersReceived.length >= number_helpers) {
        _pay_round(round_index);
      }

      return true;
    }


    function setSensingDataForRound(address _helper, uint round_index) public returns(bool){

      return true;
    }


    function validate_round(uint round_index) {
      SensingRound storage round = rounds[round_index];

      NotifyHelpersToValidate(round_index);
/**
      for (uint i=0; i < round.helpersReceived.length; i++) {
        address helper_addr = round.helpersReceived[i];
        HelperProvider helper = helperProviders[addr];

        // send Event to notify Helpers to send the spectrum data by given index


      }*/
    }

    function deliverPayments() public ownerOnly {
      for (uint i=0; i < rounds.length; i++) {
        var success = _pay_round(i);
      }
    }

    function _pay_round (uint round_index) private returns (bool) {
      SensingRound storage round = rounds[round_index];
      // dont pay this round if all helpers havent sent their shit yet
      if (round.helpersReceived.length < number_helpers) {
        return false;
      }
      // Pay all helpers for this round
      for (uint i=0; i < round.helpersReceived.length; i++) {
        address helper_addr = round.helpersReceived[i];
        Payout(helper_addr, block.timestamp);
      }
      // delete round when not needed
      _delete_round(round_index);
      return true;
    }

    function _delete_round(uint round_index) private {
      SensingRound storage round = rounds[round_index];
      delete rounds[round_index];
      RoundDeleted(round_index);
    }
}
