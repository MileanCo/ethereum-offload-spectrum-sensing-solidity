pragma solidity ^0.4.0;
contract SensingService {
    struct HelperProvider {
        uint id;
        // what the Helper is owed for sensing
        uint debit;
        // Number of times Penalized for cheating (or bad matrix)
        uint infractions;

        // Stack of spectrum data
        SpectrumData[] spectrum_data;
    }

    struct SpectrumData {
      uint[] data;
      uint round_id;
      uint timestamp_received;
    }

    struct Round {
      address[] helpersReceived;
      uint max_helpers_needed;
      uint round_id;
    }

    uint public minSensingDuration = 2; //seconds for Helper to send response of sensing results
    uint public sensing_band;
    uint public bandwidth_granularity;
    // address of SU
    address public owner;
    uint number_helpers;


    // Sensing Data received by this Helper
    // x = time_index, y = data
    //SensingSlot[] sensing_slot_stack;

    event Payout(address indexed _provider,
                      uint indexed _timestamp
                        // uint _payment);
                  );

    // mapping = "Hash", with the Eth Account Address as the 'key' into this 'array'
    // http://solidity.readthedocs.io/en/develop/types.html#mappings
    mapping (address => HelperProvider) helperProviders;
    mapping (uint => address) providerIndex;

    Round[] rounds;


    // SU creates a new contract
    function SensingService(address[] helpers, uint _sensing_band, uint _bandwidth_granularity) {
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
        _;
    }

    // Add a new Helper to this contract
    function _registerHelper(address _provider, uint _id) returns(bool) {
      // TODO: check the input parameters
      helperProviders[_provider].id = _id;
      helperProviders[_provider].debit = 0;
      helperProviders[_provider].infractions = 0;


      uint provider_ID = number_helpers++;
      providerIndex[provider_ID] = _provider;

      return true;
    }

    // Helper 'sends' sensingData to Contract
    // duration_index = time interval that sensing data was gathered.
    function setSensingData(address _helper, uint[] data) public returns(bool) {
      // set sensingData of this helper at given timestamp


      // insert this data in the first available round
      //uint round_index = 0;
      for (uint i=0; i < rounds.length; i++) {
        Round round = rounds[i];

        bool round_free = true;
        // Iterate thru this slot's Helpers to see if it's occupied by this address
        for (uint j=0; j < round.helpersReceived.length; j++) {
          address helper = round.helpersReceived[j];
          if (helper == _helper) {
            round_free = false;
            // We found it
            break;
          }
        }

        if (round_free) {

          SpectrumData memory spectrum_data = SpectrumData({
              data:data,
              timestamp_received:block.timestamp,
              round_id : i
          });
          helperProviders[_helper].spectrum_data.push(spectrum_data);
          // set this Helper as 'used' in the current Round
          rounds[i].helpersReceived.push(_helper);

          break;
        }
      }

      // now check if we are done with certian rounds
      check_rounds_and_pay_helpers();

      return true;
    }

    function check_rounds_and_pay_helpers() {
      for (uint i=0; i < rounds.length; i++) {
        Round round = rounds[i];

        if (round.helpersReceived.length >= number_helpers) {
          validate_round(i);
          pay_round(i);
          //delete_round(i);
        }
      }
    }

    function validate_round(uint round_index) {
      Round round = rounds[round_index];
      //address last_helper_addr;
      for (uint j=0; j < round.helpersReceived.length; j++) {
        address addr = round.helpersReceived[j];
        HelperProvider helper = helperProviders[addr];

        // TODO VALIDATE MATRICES

      }
    }

    function pay_round (uint round_index) {
      Round round = rounds[round_index];
      for (uint j=0; j < round.helpersReceived.length; j++) {
        address helper_addr = round.helpersReceived[j];
        Payout(helper_addr, block.timestamp);

      }
    }

    function delete_round(uint round_index) {
      Round round = rounds[round_index];
      delete rounds[round_index];

    }
}
