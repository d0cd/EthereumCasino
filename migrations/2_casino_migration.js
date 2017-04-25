var Casino = artifacts.require("Casino");

module.exports = function(deployer) {
  // deployment steps
  //Creates a BlockJack game with maximum of four players and a buyIn of 5 ether.
  deployer.deploy(Casino);
};
