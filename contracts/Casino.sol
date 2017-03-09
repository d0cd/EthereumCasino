pragma solidity ^0.4.4;

contract Casino {
  struct UserAccount {
    uint balance;
    uint gamesWon;
    uint gamesLost;
    uint gamesTied;
  }

  mapping (address => UserAccount) accounts;

  function Casino() {

  }

  function registerPlayer() payable {} 

  function createGame() payable {}

  function withdrawFunds() {}

}
