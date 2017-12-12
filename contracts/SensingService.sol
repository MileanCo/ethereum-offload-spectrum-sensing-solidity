pragma solidity ^0.4.0;
contract SensingService {

    struct HelperProvider {
        uint id;
        // what the Helper is owed for sensing
        uint debit;
        // Number of times Penalized for cheating (or bad matrix)
        uint infractions;
        // Sensing Data received by this Helper
        // x = time_index, y = data
        uint[][] sensingData;
    }

    uint public minSensingDuration = 2; //seconds for Helper to send response of sensing results
    uint public sensing_band;
    uint public bandwidth_granularity;

    // address of SU
    address public owner;
    // mapping = "Hash", with the Eth Account Address as the 'key' into this 'array'
    // http://solidity.readthedocs.io/en/develop/types.html#mappings
    mapping(address => HelperProvider) helperProviders;


    // SU creates a new contract
    function SensingService(address[] helpers, uint _sensing_band, uint _bandwidth_granularity) {
        owner = msg.sender;
        sensing_band = _sensing_band;
        bandwidth_granularity = _bandwidth_granularity;

        // for each helper in helpers; register helper
        for (uint i=0; i<helpers.length; i++) {
          address h_addr = helpers[i];
          registerHelper(h_addr, i);
        }
    }

    modifier ownerOnly {
        if(msg.sender != owner) {
            throw;
        }
        _;
    }

    // Add a new Helper to this contract
    function registerHelper(address _provider, uint _id) public ownerOnly returns(bool) {
      //uint[][] _new_sensing_matrix = new uint[][];

      // TODO: check the input parameters
      /**
      helperProviders[_provider] = HelperProvider({
        id : _id,
        debit : 0,
        infractions : 0,
        sensingData : _new_sensing_matrix
      });*/

      helperProviders[_provider].id = _id;
      helperProviders[_provider].debit = 0;
      helperProviders[_provider].infractions = 0;

      return true;
    }

    // Helper 'sends' sensingData to Contract
    // duration_index = time interval that sensing data was gathered.
    function recieveSensingData(address _helper, uint[] data) public returns(bool) {
      // set sensingData of this helper at given timestamp
      helperProviders[_helper].sensingData.push(data);
      return true;
    }
}
