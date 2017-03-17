pragma solidity ^0.4.9;

contract Casino {
    struct Player {
        uint256 balance;
        address addr;
        uint currLobby;
    }

    struct Lobby {
        uint numOfPlayers;
        Player[] playerList;
        uint num;
        uint insertIndex;
        boolean isFull;
    }

    mapping (address => Player) accounts;
    mapping (uint => Lobby) lobbyList;
    // 8 players, first number is index to insert into lobby
    function registerPlayer() payable {
        if (accounts[msg.sender].ID != address(0x0)) {
            accounts[msg.sender] = Player(msg.value, msg.sender, -1);
        } else {
            throw;
        }
    }

    function addPlayer(Player player, uint amount, uint lobbyNum)  private {
        if (player.currLobby != -1) {
            //already joined a lobby
            return;
        }

        if (lobbyList[lobbyNum].isFull) {
            return;
        }

        //once game starts, no one can join lobby
        player.currLobby = lobbyNum;
        index = lobbyList[lobbyNum].insertIndex;
        lobbyList[lobbyNum][index] = player.addr;
        lobbyList[lobbyNum].insertIndex += 1;
        if (lobbyList[lobbyNum].insertIndex == 8) {
            lobbyList[lobbyNum].isFull = true;
        }
    }

    function leaveLobby(Player player) {
        if (player.currLobby == -1) {
        //not in lobby
            return; 
        }

        lob = lobbyList[player.currLobby];
        for (uint i = 0; i < 8; i++) {
            if (lob.playerList[i].addr == player.addr) {
                lob.playerList[i] = null;
                lob.isFull = false;
                //once game starts, no one can join lobby
            }
        }
    }

    function updateFunds(Player player, uint moneyWon) private {
        player.balance += moneyWon;
    }


    function blackJack(uint buyin, uint lobbyNum) payable {
        if (buyin > msg.balance) {
            return;
        }
        lob = lobbyList[lobbyNum];
        for (uint i = 1; i < 8; i++) {
            if (lob.playerList[i] != null) {
                lob.playerList[i].balance -= buyin;
            }
        }

    }


    function poker(uint buyin, uint lobbyNum) payable {
        if (buyin > msg.balance) { //msg.balance???
            return;
        }

        lob = lobbyList[lobbyNum];
        for (uint i = 1; i < 8; i++) {
            if (lob.playerList[i] != null) {
                lob.playerList[i].balance -= buyin;
            }
        }

    }

