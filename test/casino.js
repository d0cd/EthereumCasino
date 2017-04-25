var Casino = artifacts.require("Casino");
var BlockJack = artifacts.require("BlockJack");

var blockjack;

contract("Casino", function(accounts) {
  it("should create new BlockJack game", function() {
    return Casino.deployed()
  .then(function(instance) {
    var casino = instance;
    return casino.createBlockJack.call(2139873123, 2, 5, {from: accounts[1], value: 100});
  }).then(function(address) {
    console.log(address.valueOf());
    // console.log(typeof(address));
    blockjack = BlockJack.at(address);
    console.log(typeof(address))
    return blockjack.getNumPlayers.call();
  }).then(function(numPlayers) {
     assert.equal(numPlayers.valueOf(), 1, "One player should be added in");
    blockjack.addPlayer(23489723942, {from: accounts[2], value: 100});
    return blockjack.getNumPlayers.call();
  }).then(function (newNumPlayers){
    assert.equal(newNumPlayers.valueOf(), 5, "One player should be added in");
  })
  })
})
