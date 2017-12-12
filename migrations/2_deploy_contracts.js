var SensingService = artifacts.require("./SensingService.sol");

module.exports = function(deployer) {
  deployer.deploy(SensingService);
};
