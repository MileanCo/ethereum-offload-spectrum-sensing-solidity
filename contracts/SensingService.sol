pragma solidity ^0.4.0;
contract SensingService {

    struct HelperProvider {
        uint id;
        string location;
        // what the Helper is owed for sensing
        uint debit;
        // Number of times Penalized for cheating (or bad matrix)
        uint infractions;
        // Sensing Data received by this Helper
        // x = time, y = data
        bool[][] sensingMatrix;
    }

    // address of SU
    address public _owner;
    // mapping = "Hash", with the Eth Account Address as the 'key' into this 'array'
    // http://solidity.readthedocs.io/en/develop/types.html#mappings
    mapping(address => HelperProvider) helperProviders;


    // SU creates a new contract
    function SensingService() {
        _owner = msg.sender;
    }

    // Add a new Helper to this contract
    function registerHelper(address _provider, uint _id, string _location) public ownerOnly returns(bool) {
      // TODO: check the input parameters
      helperProviders[_provider] = HelperProvider({id:_id, location:_location});
      return true;
    }

    // what would this do?
    function willingToSend(string location, uint t_start, uint t_end, uint price) {

    }

    // Helper 'sends' sensingData to Contract
    function recieveSensingData(address _helper, bool[] data, uint timestamp) {
      helperProviders[_helper].sensingMatrix[timestamp] = data;
    }
}
