pragma solidity ^0.4.9;

contract Blockjack {

    //Variables to keep track of game state.
    uint buyIn;
    uint numPlayers;
    uint[] cardsDrawn;
    uint timeLimit = 60 seconds;
    uint turn = 0;
    uint pot = 0;
    bool addPlayers = true;
    uint numPasses = 0;
    uint randNum;
    uint maxPlayers;
    address[] roundPlayers;
    address[] winners;

    //Player struct to keep track of player data.
    struct Player {
        uint balance;
            bool pass;
            uint randSeed;
            uint order;
            uint score;
            uint[] hand;
    }

    mapping (address => Player) players;

    //Creates a new BlockJack game, where the amount sent in
    //transaction is the minimum buy in.
    function BlockJack(uint randSeed, uint playerCap) payable {
            buyIn = msg.value;
            randNum = block.timestamp + randSeed;
            maxPlayers = playerCap;
            numPlayers += 1;
            constructPlayer(msg.sender, msg.value, randSeed);
    }

    function constructPlayer(address addr, uint balance, uint randSeed) {
        Player newPlayer = players[addr];
        newPlayer.balance = balance;
        newPlayer.pass = false;
        newPlayer.randSeed = randSeed;
        newPlayer.order = 0;
    }


    //Adds a player to the game, provided amount meets minimum buy in.
    function addPlayer(uint randSeed) payable {
            if (addPlayers && msg.value >= buyIn) {
                    randNum += randSeed;
                    constructPlayer(msg.sender, msg.value, randSeed);
                    numPlayers += 1;
                    if (numPlayers == maxPlayers) {
                            addPlayers = false;
                    }
            } else {
                    throw;
            }
    }

    function addFunds() payable {
        Player thisPlayer = players[msg.sender];
        thisPlayer.balance += msg.value;
    }

    function cashOut() returns (bool) {
        Player player = players[msg.sender];
        uint amount = player.balance;
        player.balance = 0;
        if (!msg.sender.send(amount)) {
            player.balance = amount;
            return false;
        }
        removePlayer(msg.sender);
        return true;
    }

    function removePlayer(address addr) private {
            Player player = players[addr];
            numPlayers -= 1;
            player.pass = false;
            player.order = 0;
            player.score = 0;
            player.randSeed = 0;
            delete player.hand;
    }

    //Allows players to place bet and participate in the next round.
    function ante(uint randSeed) {
        if (addPlayers) throw;
        Player player = players[msg.sender];
        if (player.balance < buyIn) throw;
        pot += buyIn;
        randNum += randSeed;
        player.balance -= buyIn;
        player.order = roundPlayers.length;
        player.randSeed = player.randSeed * randNum;
        roundPlayers.push(msg.sender);
    }

    function dealCards() {
        for (uint i = 0; i < roundPlayers.length * 2; i++) {
            Player player = players[roundPlayers[i % roundPlayers.length]];
            uint card = drawCard(player);
            cardsDrawn.push(card);
            player.hand.push(card);
        }
    }


    //Deals a player a random card.
    /* TODO: need to check for card collisions */
    function drawCard(Player player) private returns (uint) {
        uint card = (player.randSeed + block.number) % 416;
        player.randSeed += card;
        for (uint j = 0; j < cardsDrawn.length; j++) {
                /*if (cardsDrawn[j] == card) {
                        card = drawCard(player);
                }*/
        }
        randNum += card;
        return card;
    }



  /* TODO: Subtract balances from players. Kick out players that dont have enough money. */
    /*function startRound() {
            if (numPlayers < 2) {
                    throw;
            }
            if (cardsDrawn.length != numPlayers * 2) {
                    throw;
            }
            addPlayers = false;
            for (uint i = 0; i < numPlayers; i += 1) {
                    address addr = id[i];
                    Player otherPlayer = players[addr];
                    otherPlayer.pass = false;
            }
    }*/


    function play(bool hit, uint randSeed) {
        Player player = players[msg.sender];
        if (turn != player.order || player.pass || roundPlayers.length == numPasses) {
            throw;
        }
        if (hit) {
            uint card = drawCard(player);
            cardsDrawn.push(card);
            player.hand.push(card);
            player.score = calculateScore(player);
            if(player.score >= 21) {
                //Bust or 21
                player.pass == true;
                numPasses += 1;
            }
            
        } else {
            player.pass == true;
            numPasses += 1;
        }
        if (turn == roundPlayers.length) {
            turn = 0;
        } else {
            turn += 1;
        }
    }


    function determineWinner() {
        if (numPasses < roundPlayers.length) throw;
        uint maxScore = 0;
        for (uint i = 0; i < roundPlayers.length; i += 1) {
            Player player = players[roundPlayers[i]];
            player.score = calculateScore(player);
            if (player.score > maxScore) {
                maxScore = player.score;
            }
        }
        for (uint j = 0; j < roundPlayers.length; j++) {
            player = players[roundPlayers[j]];
            if (player.score == maxScore) {
                winners.push(roundPlayers[j]);
            }
        }
    }

    /*TODO: Add in blackjack rules for card values */
    function calculateScore(Player player) private returns (uint) {
        uint score = 0;
        for (uint i = 0; i < player.hand.length; i++) {
            uint card = (player.hand[i] % 52) % 13;
            score += card;
        }
        return score;
    }


    function payWinners(address[] addrs) {
        for (uint i = 0; i < addrs.length; i++) {
            Player winner = players[addrs[i]];
            uint amtToSend = pot/addrs.length;
            winner.balance += amtToSend;
            pot -= amtToSend;
        }
  }

    function clear() {
        addPlayers = true;
        numPasses = 0;
        for (uint i = 0; i < roundPlayers.length; i++) {
            Player player = players[roundPlayers[i]];
            player.pass = false;
            player.order = 0;
            player.score = 0;
            delete player.hand;
        }
        delete roundPlayers;
        delete cardsDrawn;
        delete winners;
    }
}