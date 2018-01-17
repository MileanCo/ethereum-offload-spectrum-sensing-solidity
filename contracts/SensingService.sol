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
        address[] helpersSent;
        //address[] SUReceivedData; // TODD
        mapping(address => SpectrumData) spectrum_data;
        uint roundId;
    }

    struct SpectrumData {
        // uint[][] data; UnimplementedFeatureError: Nested arrays not yet implemented.
        uint[] data;
      //  uint timestamp_received;
    }

    // Queue of active rounds... shoudl be < 2
    SensingRound[] current_rounds_queue;

    uint public minSensingDuration = 2; //seconds for Helper to send response of sensing results
    uint public sensing_band;
    uint public bandwidth_granularity;
    //uint public _costPerRound = 1000000000000000; // 1 finney = 0.001 ether
    uint public costPerRound;
    // address of SU
    address public owner_su;
    uint number_helpers = 0;



    // EVENTS for testing purposes, notify when a new SensingRound is started/created
    event NewRoundCreated(uint indexed roundId);
    event RoundDeleted(uint indexed roundId);
    event DebugInt(uint integer);

    // Useful events
    event NotifyUsersToValidate(uint indexed roundId);
    event ValidatedRound(uint indexed roundId, bool valid);
    event Payout(address indexed _provider,
                    uint indexed _timestamp,
                    uint amount
    );
    event RoundCompleted(//address indexed _provider,
                    uint indexed _timestamp
                        // uint _payment);
    );
    event InsufficientFunds(uint indexed _timestamp, uint amount_owed);

    // mapping = "Hash", with the Eth Account Address as the 'key' into this 'array'
    // http://solidity.readthedocs.io/en/develop/types.html#mappings
    mapping (address => HelperProvider) helperProviders;
    // hack to iterate through a Mapping
    mapping (uint => address) providerIndex;


    // Constructor / init() method...  SU creates a new contract
    function SensingService(address[] helpers, address _owner_su, uint _sensing_band, uint _bandwidth_granularity, uint _costPerRound) public {
        owner_su = _owner_su;
        sensing_band = _sensing_band;
        bandwidth_granularity = _bandwidth_granularity;
        costPerRound = _costPerRound;

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
        for (uint j=0; j < round.helpersSent.length; j++) {
          address other_helper = round.helpersSent[j];
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
        address[] memory _helpersSent = new address[](0);

        // create new SensingRound
        SensingRound memory new_round = SensingRound({
          helpersSent : _helpersSent,
          //SUReceivedData : _SUReceivedData,
          roundId : round_index
        });
        current_rounds_queue.push(new_round);
        // create new event to notify
        NewRoundCreated(round_index);
      }

      // Add this Helper to the SensingRound selected
      current_rounds_queue[round_index].helpersSent.push(_helper);

      // Should we mark this round as completed?
      //DebugInt(number_helpers);
      //DebugInt(current_rounds_queue[round_index].helpersSent.length);
      if (current_rounds_queue[round_index].helpersSent.length >= number_helpers) {
        _round_completed(round_index);
      }


      return true;
    }


    function setSensingDataForRound(address _helper, uint[] _data, uint round_index) public returns(bool) {
      SensingRound storage round = current_rounds_queue[round_index];

      if (round.spectrum_data[_helper].data.length > 0) {
        // ALREADY got this round
        return false;
      }
      // check that this Helper actually participated in this round
      round.spectrum_data[_helper] = SpectrumData({
        data: _data
      });

      // TODO: determine if we should validate_round
      uint num_helpers_sent_spectrum_data = 0;
      for (uint j=0; j < round.helpersSent.length; j++) {
        address other_helper = round.helpersSent[j];
        // has this other_helper set their SpectrumData yet?
        if (round.spectrum_data[other_helper].data.length > 0) {
          num_helpers_sent_spectrum_data++;
        }
      }

      // if received all helpers in this round
      if (num_helpers_sent_spectrum_data >= round.helpersSent.length) {
        bool valid = _validate_round(round_index);
      }

      return true;
    }


    function _validate_round(uint round_index) private returns (bool) {
      bool valid = true;
      uint index_to_check = 0;
      uint last_helper_data = 10;

      SensingRound storage round = current_rounds_queue[round_index];
      for (uint i=0; i < round.helpersSent.length; i++) {
        address helper_addr = round.helpersSent[i];
        if (last_helper_data != round.spectrum_data[helper_addr].data[index_to_check] && last_helper_data != 10) {
          valid = false;
          helperProviders[helper_addr].amount_owed -= 1;
        }
        last_helper_data = round.spectrum_data[helper_addr].data[index_to_check];
      }

      ValidatedRound(round_index, valid);
      return valid;
    }
/**
    function deliverPayments() public ownerOnly {
      for (uint i=0; i < current_rounds_queue.length; i++) {
        var success = _round_completed(i);
      }
    }*/

    /* Each helper calls withdraw() to get their share of what is owed
    msg.sender = helper
     */
    function withdraw() public returns(bool) {
      HelperProvider hp = helperProviders[msg.sender];
      if (hp.amount_owed <= 0) {
        return false;
      }
      uint amount_owed = hp.amount_owed * costPerRound;
      // send Ether to the sender of this message
      if (msg.sender.send(amount_owed)) {
          hp.amount_owed = 0;
          Payout(msg.sender, block.timestamp, amount_owed);
          return true;
      } else {
          InsufficientFunds(block.timestamp, amount_owed);
          return false;
      }
    }

    /* Top up the balance of the contract so that providers can withdraw funds
     * to receive payment for the traffic they served.
     */
    function increaseFunds() payable {}

    function _round_completed (uint round_index) private returns (bool) {
      SensingRound storage round = current_rounds_queue[round_index];
      // dont complete thisx round if all helpers havent sent their shit yet
      if (round.helpersSent.length < number_helpers) {
        return false;
      }
      // Increase amount_owed (payment owed) to all helpers
      for (uint i=0; i < round.helpersSent.length; i++) {
        address helper_addr = round.helpersSent[i];
        helperProviders[helper_addr].amount_owed += 1;
      }
      RoundCompleted(block.timestamp);


      // TODO: only validate random # of times
      if (true) {
        // when round is completed, verify it?
        NotifyUsersToValidate(round_index);
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
