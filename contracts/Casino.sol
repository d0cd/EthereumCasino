pragma solidity ^0.4.4;

contract Casino {
  struct UserAccount {
    uint balance;
    address ID;
    uint gamesWon;
    uint gamesLost;
    uint gamesTied;
  }

  mapping (address => UserAccount) accounts;


  function Casino() {}

  function registerPlayer() payable {
    if (accounts[msg.sender].ID != address(0x0)) {
      accounts[msg.sender] = UserAccount(msg.value, msg.sender, 0,0,0);
    } else {
      throw;
    }
  }

  function createNewGame() payable {
  }

  function withdrawFunds() returns (bool) {
    uint amtToSend = accounts[msg.sender].balance;
    accounts[msg.sender].balance = 0;
    if (msg.sender.send(amtToSend)) {
      return true;
    } else {
      accounts[msg.sender].balance = amtToSend;
      return false;
    }
  }

  function depositFunds() payable {
    if (accounts[msg.sender].ID != address(0x0)) {
      accounts[msg.sender].balance += msg.value;
    } else {
      throw;
    }

  }

}
