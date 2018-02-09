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
        uint num_helpers_sent;
        mapping(address => bool) helpersSent;
        // hack to iterate through a Mapping
        mapping (uint => address) helpersSentIndex;
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
    //SensingRound[] current_rounds_queue;
    mapping (uint => SensingRound) current_rounds_queue;
    uint NUM_CURRENT_ROUNDS = 0;

    uint public minSensingDuration = 2; //seconds for Helper to send response of sensing results
    uint public sensing_band;
    uint public bandwidth_granularity;
    //uint public _costPerRound = 1000000000000000; // 1 finney = 0.001 ether
    uint public costPerRound;
    // address of SU
    address public owner_su;
    uint number_helpers = 0;



    // EVENTS for testing purposes, notify when a new SensingRound is started/created
    event NewRoundCreated(uint  round_index);
    event RoundDeleted(uint  round_index);
    event DebugInt(uint integer);
    event HelperAlreadySent(address helper, uint round_index);
    event IncrementedAmountOwed(address helper, uint round_index);

    // Useful events
    event NotifyUsersToValidate(uint  roundId);
    event ValidatedRound(uint  roundId, bool valid);
    event PenalizedHelperForRound(uint roundId, address helper, uint amount_owed);
    event Payout(address indexed _provider,
                    uint indexed _timestamp,
                    uint amount_owed
    );
    event RoundCompleted( uint round_index);//, uint indexed _timestamp );
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

    function helperNotifyDataSent(address _helper, uint round_index) public returns(bool) {
      if (number_helpers == 0) {
        throw;//return "No helpers defined";//throw "No helpers defined";
      }

      // no round exists? create a new one
      // can't check for NULL or 0, so we have to compare the index to size of array
      if (round_index >= NUM_CURRENT_ROUNDS) {
        // create new SensingRound
        current_rounds_queue[round_index] = SensingRound({
          //SUReceivedData : _SUReceivedData,
          roundId : round_index,
          num_helpers_sent : 0
        });

        // create new event to notify
        NewRoundCreated(round_index);
        NUM_CURRENT_ROUNDS++;
      }

      // Add this Helper to the SensingRound selected
      SensingRound storage r = current_rounds_queue[round_index];
      if (r.helpersSent[_helper] != true) {
        r.helpersSent[_helper] = true;
      } else {
        HelperAlreadySent(_helper, round_index);
        return false;
      }

      r.helpersSentIndex[r.num_helpers_sent] = _helper;
      r.num_helpers_sent++;

      // Should we mark this round as completed?
      if (current_rounds_queue[round_index].num_helpers_sent >= number_helpers) {
        _round_completed(round_index);
      }
      return true;
    }

    function _round_completed (uint round_index) private returns (bool) {
      SensingRound storage round = current_rounds_queue[round_index];
      // dont complete thisx round if all helpers havent sent their shit yet
      if (round.num_helpers_sent < number_helpers) {
        return false;
      }
      RoundCompleted(round_index);

      if (true) {
        // when round is completed, verify it?
        NotifyUsersToValidate(round_index);
      } else {
        // delete round when completed
        _delete_round(round_index);
      }

      // Increase amount_owed (payment owed) to all helpers
      for (uint i=0; i <= round.num_helpers_sent; i++) {
        HelperProvider storage hp = helperProviders[round.helpersSentIndex[i]];
        hp.amount_owed += 1;
        IncrementedAmountOwed(round.helpersSentIndex[i], round_index);
      }

      // TODO: only validate random # of times
      return true;
    }

    function _delete_round(uint round_index) private {
      SensingRound storage round = current_rounds_queue[round_index];
      delete current_rounds_queue[round_index];
      NUM_CURRENT_ROUNDS--;
      RoundDeleted(round_index);
    }

    function penalize_cheaters(address[] cheaters, uint round_index) public returns(bool) {
      SensingRound storage round = current_rounds_queue[round_index];

      // TODO: iterate through cheaters and decrement their amount_owed if caught
      for (uint i=0; i < cheaters.length; i++) {
        address cheater_addr = cheaters[i];
        HelperProvider storage hp = helperProviders[cheater_addr];
        hp.amount_owed -= 1;
        PenalizedHelperForRound(round_index, cheater_addr, hp.amount_owed);
      }
      return true;
    }

    // TODO: send list of helpers who cheated [0,1]
/**
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
      for (uint j=0; j < round.num_helpers_sent; j++) {
        address other_helper = round.helpersSentIndex[j];
        // has this other_helper set their SpectrumData yet?
        if (round.spectrum_data[other_helper].data.length > 0) {
          num_helpers_sent_spectrum_data++;
        }
      }

      // if received all helpers in this round
      if (num_helpers_sent_spectrum_data >= round.num_helpers_sent) {
        bool valid = _validate_round(round_index);
      }

      return true;
    }
*/

    function _validate_round(uint round_index) private returns (bool) {
      bool valid = true;
      uint index_to_check = 0;
      uint last_helper_data = 10;

      SensingRound storage round = current_rounds_queue[round_index];
      for (uint i=0; i < round.num_helpers_sent; i++) {
        address helper_addr = round.helpersSentIndex[i];
        if (last_helper_data != round.spectrum_data[helper_addr].data[index_to_check] && last_helper_data != 10) {
          valid = false;
          helperProviders[helper_addr].amount_owed -= 1;
        }
        last_helper_data = round.spectrum_data[helper_addr].data[index_to_check];
      }

      ValidatedRound(round_index, valid);
      return valid;
    }

    /* Each helper calls withdraw() to get their share of what is owed
    msg.sender = helper
     */
    function withdraw() public returns(bool) {
      HelperProvider storage hp = helperProviders[msg.sender];
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

}
