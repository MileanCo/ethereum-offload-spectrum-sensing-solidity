pragma solidity ^0.4.18;


contract SensingService {
    struct HelperProvider {
        uint id;
        // what the Helper is owed for sensing
        uint amount_owed;
        // Number of times Penalized for cheating (or bad matrix)
        uint infractions;
    }

    struct SensingRound {
        address[] helpersSentData;
        //address[] SUReceivedData; // TODD
        //uint max_helpers_needed;
        mapping(address => SpectrumData) spectrum_data;
        uint roundId;
    }

    struct SpectrumData {
        uint[] data;
      //  uint timestamp_received;
    }

    // Queue of active rounds... shoudl be < 2
    SensingRound[] current_rounds_queue;

    uint public minSensingDuration = 2; //seconds for Helper to send response of sensing results
    uint public sensing_band;
    uint public bandwidth_granularity;
    // address of SU
    address public owner_su;
    uint number_helpers = 0;



    // EVENTS for testing purposes, notify when a new SensingRound is started/created
    event NewRoundCreated(uint indexed roundId);
    event RoundDeleted(uint indexed roundId);
    event DebugInt(uint integer);

    // Useful events
    event NotifyUsersToValidate(uint indexed roundId);
    event Payout(address indexed _provider,
                    uint indexed _timestamp
                        // uint _payment);
    );
    event RoundCompleted(//address indexed _provider,
                    uint indexed _timestamp
                        // uint _payment);
    );
    event InsufficientFunds(uint indexed _timestamp);

    // mapping = "Hash", with the Eth Account Address as the 'key' into this 'array'
    // http://solidity.readthedocs.io/en/develop/types.html#mappings
    mapping (address => HelperProvider) helperProviders;
    // hack to iterate through a Mapping
    mapping (uint => address) providerIndex;


    // Constructor / init() method...  SU creates a new contract
    function SensingService(address[] helpers, address _owner_su, uint _sensing_band, uint _bandwidth_granularity) public {
        owner_su = _owner_su;
        sensing_band = _sensing_band;
        bandwidth_granularity = _bandwidth_granularity;
        //current_rounds_queue = new SensingRound[](0);
        //delete current_rounds_queue[0];
        number_helpers = helpers.length;

        // for each helper in helpers; register helper
        for (uint i=0; i<helpers.length; i++) {
          address h_addr = helpers[i];
          _registerHelper(h_addr, i);
        }
    }

    modifier ownerOnly {
        if(msg.sender != owner_su) {
            throw;
        }
        // wtf is this... required though
        _;
    }

    // Add a new Helper to this contract
    function _registerHelper(address _provider, uint _id) private returns(bool) {
      // TODO: check the input parameters
      helperProviders[_provider].id = _id;
      helperProviders[_provider].amount_owed = 0;
      helperProviders[_provider].infractions = 0;

      uint provider_ID = number_helpers;
      providerIndex[provider_ID] = _provider;
      InsufficientFunds(0);

      return true;
    }

    function ownerRecievedData() public ownerOnly {

    }

    function helperNotifyDataSent(address _helper) public returns(bool) {
      if (number_helpers == 0) {
        throw;//return "No helpers defined";//throw "No helpers defined";
      }

      // GET ROUND_INDEX DESIRED
      // insert this data in the first available round
      uint round_index = 0;
      for (uint i=0; i < current_rounds_queue.length; i++) {
        SensingRound storage round = current_rounds_queue[i];
        round_index = i;

        bool round_free = true;
        // Iterate thru this SensingRound's Helpers to see if it's occupied by this address
        for (uint j=0; j < round.helpersSentData.length; j++) {
          address other_helper = round.helpersSentData[j];
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
      if (round_index >= current_rounds_queue.length) {
        // create new empty array
        address[] memory _helpersSentData = new address[](0);
      //  address[] memory _SUReceivedData //= new address[](0);
        // create new SensingRound
        SensingRound memory new_round = SensingRound({
          helpersSentData : _helpersSentData,
          //SUReceivedData : _SUReceivedData,
          roundId : round_index
        });
        current_rounds_queue.push(new_round);
        // create new event to notify
        NewRoundCreated(round_index);
      }

      // Add this Helper to the SensingRound selected
      current_rounds_queue[round_index].helpersSentData.push(_helper);

      // Should we mark this round as completed?
      //DebugInt(number_helpers);
      //DebugInt(current_rounds_queue[round_index].helpersSentData.length);
      if (current_rounds_queue[round_index].helpersSentData.length >= number_helpers) {
        _round_completed(round_index);
      }


      return true;
    }


    function setSensingDataForRound(address _helper, uint round_index) public returns(bool){

      return true;
    }


    function validate_round(uint round_index) {
      SensingRound storage round = current_rounds_queue[round_index];

      NotifyUsersToValidate(round_index);
/**
      for (uint i=0; i < round.helpersSentData.length; i++) {
        address helper_addr = round.helpersSentData[i];
        HelperProvider helper = helperProviders[addr];

        // send Event to notify Helpers to send the spectrum data by given index


      }*/
    }

    function deliverPayments() public ownerOnly {
      for (uint i=0; i < current_rounds_queue.length; i++) {
        var success = _round_completed(i);
      }
    }

    /* Each helper calls withdraw() to get their share of what is owed
    msg.sender = helper
     */
    function withdraw() public returns(bool) {
      HelperProvider hp = helperProviders[msg.sender];
      if (hp.amount_owed <= 0) {
        return false;
      }

      // send Ether to the sender of this message
      if (msg.sender.send(hp.amount_owed)) {
          hp.amount_owed = 0;
          return true;
      } else {
          InsufficientFunds(block.timestamp);
          return false;
      }
    }

    function _round_completed (uint round_index) private returns (bool) {
      SensingRound storage round = current_rounds_queue[round_index];
      // dont complete thisx round if all helpers havent sent their shit yet
      if (round.helpersSentData.length < number_helpers) {
        return false;
      }
      // Increase amount_owed (payment owed) to all helpers
      for (uint i=0; i < round.helpersSentData.length; i++) {
        address helper_addr = round.helpersSentData[i];
        helperProviders[helper_addr].amount_owed += 1;
      }
      RoundCompleted(block.timestamp);


      if (true) {
        // when round is completed, verify it?
        validate_round(round_index);
      } else {
        // delete round when completed
        _delete_round(round_index);
      }

      return true;
    }

    function _delete_round(uint round_index) private {
      SensingRound storage round = current_rounds_queue[round_index];
      delete current_rounds_queue[round_index];
      RoundDeleted(round_index);
    }
}
