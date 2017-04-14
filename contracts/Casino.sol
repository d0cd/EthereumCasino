pragma solidity ^0.4.4;

contract Casino {
    struct UserAccount {
        uint balance;
        address ID;
        uint gamesWon;
        uint gamesLost;
        uint gamesTied;
    }

    struct Game {
        uint numOfPlayers;
        address[] playerList;
        bool isFull;
    }

    mapping (address => UserAccount) accounts;
    mapping (uint => Game) games;

    uint gameIndex = 0;


    function Casino() {}

    function registerPlayer() payable {
        if (accounts[msg.sender].ID != address(0x0)) {
            accounts[msg.sender] = UserAccount(msg.value, msg.sender, 0,0,0);
        } else {
            throw;
        }
    }

    function createNewGame() payable {
        games[gameIndex] = Game(1, new address[](0), false);
        games[gameIndex].playerList.push(accounts[msg.sender].ID);
    }

    function joinGame(uint gameNum, address newAddress) payable {
        if (games[gameNum].isFull) {
            throw;
        }
        games[gameNum].playerList.push(newAddress);
        games[gameNum].numOfPlayers += 1;
        if (games[gameNum].numOfPlayers == 8) {
            games[gameNum].isFull = true;
        }
    }

    function leaveGame(uint gameNum, address removeAddress) payable {
        bool inGame = false;
        uint i;
        for (i = 0; i < games[gameNum].playerList.length; i++) {
            if (games[gameNum].playerList[i] == removeAddress) {
                inGame = true;
                break;
            }
        }
        
        if (inGame == false) {
            throw;
        }
        
        
        address[] temp = games[gameNum].playerList;
        games[gameNum].playerList = new address[](0);
        
        for (i = 0; i < temp.length; i++) {
            if (temp[i] != 0) {
                games[gameNum].playerList.push(temp[i]);
            }
        }
        
        games[gameNum].numOfPlayers -= 1;
        games[gameNum].isFull = false;
        
        if (games[gameNum].numOfPlayers == 0) {
            // closeGame
        }

        

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
