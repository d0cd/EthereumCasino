var BlockJack = artifacts.require("BlockJack");

module.exports = function(deployer) {
  // deployment steps
  //Creates a BlockJack game with maximum of four players and a buyIn of 5 ether.
  deployer.deploy(BlockJack, 171823121, 2, 5);
};
