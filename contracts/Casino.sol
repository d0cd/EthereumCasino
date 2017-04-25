pragma solidity ^0.4.4;

import "./BlockJack.sol";

contract Casino {

    struct Game {
        uint gameNum;
        address addr;
        uint playerCap;
    }

    Game[] games;

    uint gameIndex;


    function Casino() {
      gameIndex = 0;
    }


    function createBlockJack(uint randSeed, uint playerCap, uint bet) payable returns (address) {
        address newGame = new BlockJack(randSeed, playerCap, bet, gameIndex);
        games[gameIndex] = Game(gameIndex, newGame, playerCap);
        gameIndex += 1;
        return newGame;
    }

    function removeGame(uint index) {
      games[index] = games[gameIndex];
      gameIndex -= 1;
    }

    function getAddr(uint index) returns (address) {
        return games[index].addr;
    }

    function getTotalNumGames() returns (uint) {
      return gameIndex + 1;
    }
}
