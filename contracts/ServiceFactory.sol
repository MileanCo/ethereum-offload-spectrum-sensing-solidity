pragma solidity ^0.4.18;

import "contracts/SensingService.sol"; // defines "SimpleAuction"

contract ServiceFactory {

  // no Constructor

    event LogNewSensingService(address serviceAddr);

    function newSensingService(address[] helpers, uint _sensing_band, uint _bandwidth_granularity) returns(address createdContract) {
        SensingService sensingService = new SensingService(helpers, msg.sender, _sensing_band, _bandwidth_granularity);
        LogNewSensingService(sensingService);
        return sensingService;
    }
}
