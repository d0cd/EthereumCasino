pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/BlockJack.sol";

contract TestBlockJack {
  BlockJack blockjack;
  function testNewContract() {
    blockjack = new BlockJack(272182891, 4, 5);

    uint expected = 5;

    Assert.equal(blockjack.getBuyIn(), expected, "BuyIn should be 5 ether");
  }

}
