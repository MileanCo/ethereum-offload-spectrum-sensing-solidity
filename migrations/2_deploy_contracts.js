var ServiceFactory = artifacts.require("./ServiceFactory.sol");

module.exports = function(deployer) {
  deployer.deploy(ServiceFactory);
};
