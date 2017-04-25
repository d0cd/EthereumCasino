var BlockJack = artifacts.require("BlockJack");

contract('BlockJack', function(accounts) {
  it("should check deployed BlockJack", function() {
    return BlockJack.deployed().then(function(instance) {
      return instance.getBuyIn.call({from: accounts[0]});
  }).then(function(buyIn) {
      assert.equal(buyIn.valueOf(), 5, "Buy In is not 5");
    });
  });
  //add new player
  it("should add new player", function() {
      var blockjack;
      var account_one = accounts[0];
      var account_two = accounts[1];
      return BlockJack.deployed().then(function(instance) {
        blockjack = instance;
        blockjack.addPlayer(234211234, {from: account_one, value: 100 });
        blockjack.addPlayer(34323451123, {from: account_two, value: 100});
        return instance.getNumPlayers.call({from:account_one});
      }).then(function(numPlayers) {
        assert.equal(numPlayers.valueOf(), 2, "Players were not added");
      });
  });
  it("should allow players to ante", function() {
    var blockjack;
    var account_one = accounts[0];
    var account_two = accounts[1];
    return BlockJack.deployed().then(function(instance) {
      blockjack = instance;
      blockjack.ante(2341123123, {from: account_one});
      blockjack.ante(234618967, {from: account_two});
      return instance.getPot.call({from: account_one});
    }).then(function(pot) {
      assert.equal(pot.valueOf(), 10, "Players did not ante");
    });
  });

  it("should deal cards to players", function() {
    var blockjack;
    var account_one = accounts[0];
    var account_two = accounts[1];
    return BlockJack.deployed().then(function (instance) {
      blockjack = instance;
      blockjack.dealCards({from: account_one});
      return instance.getAllCards.call({from: account_one});
    }).then(function(cards) {
      console.log(cards)
      assert.equal(cards.valueOf(), 7, "Random Card");
    });
  });
  it("should calculate score after both players pass", function(instance) {
    var blockjack;
    var account_one = accounts[0];
    var account_two = accounts[1];
    var balance_one;
    var balance_two;
    var score_one;
    var score_two;
    var cards_one;
    var cards_two;
    return BlockJack.deployed().then(function (instance) {
      blockjack = instance;
      blockjack.play(false, 39785739, {from: account_one});
      blockjack.play(false, 09864393, {from: account_two});
      return blockjack.getScore.call({from: account_one});
    }).then(function(score1) {
      score_one = score1.toNumber();
      return blockjack.getScore.call({from: account_two});
    }).then(function(score2) {
      score_two = score2.toNumber()
      return blockjack.getCards.call(account_one);
    }).then(function(cards) {
      cards_one = cards
      return blockjack.getCards.call(account_two);
    }).then(function (cards) {
      cards_two = cards;
      blockjack.determineWinner(account_one);
      // var balance_one = instance.getBalance.call({from: account_one});

      // var balance_two = instance.getBalance.call({from: account_two});

      return blockjack.getBalance.call({from: account_one});
    }).then(function(balance) {
      balance_one = balance.toNumber();
      return blockjack.getBalance.call({from: account_two});
    }).then(function(balance) {
      balance_two = balance.toNumber();
      console.log(cards_one, score_one);
      console.log("        ");
      console.log(cards_two, score_two);
      console.log(balance_one, balance_two);
      assert.equal(balance_one, 100, "Should be 5 off from 100");
      assert.equal(balance_two, 100, "Should be 5 off from 100");
    });
  });
});
