pragma solidity ^0.4.9;

contract Blockjack {

		enum Stages {
			AddPlayers,
			AnteUp,
			Play
		}

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
		address[] allPlayers;
    address[] winners;
		bool lock;
		bool deal;

    //Player struct to keep track of player data.
    struct Player {
        uint balance;
            bool pass;
            uint randSeed;
            uint order;
            uint score;
            uint[] hand;
						bytes32 pubKey;
    }

    mapping (address => Player) players;

		Stages public stage = Stages.AddPlayers;
    uint public time = now;
		modifier atStage(Stages _stage) {
				if (stage != _stage) throw;
				_;
		}

		function nextStage() internal {
				stage = Stages(uint(stage) + 1);
		}

		//TODO: Destroy game if no one is resonding
		modifier timedTransitions() {
			if (stage == Stages.AddPlayers && now >= time + 5 minutes && numPlayers > 1) {
				nextStage();
			}
			if (stage == Stages.AnteUp && now >= time + 5 minutes) {
				if (roundPlayers.length > 1) {
					nextStage();
				} else {
					delete roundPlayers;
					for (uint i = 0; i < allPlayers.length; i++) {
						removePlayer(allPlayers[i]);
					}
				}
			}
			_;
		}
    //Creates a new BlockJack game, where the amount sent in
    //transaction is the minimum buy in.
    function BlockJack(uint randSeed, uint playerCap, bytes32 key) payable {
            buyIn = msg.value;
            randNum = block.timestamp + randSeed;
            maxPlayers = playerCap;
            numPlayers += 1;
						lock = false;
						deal = true;
            constructPlayer(msg.sender, msg.value, randSeed, key);
    }

    function constructPlayer(address addr, uint balance, uint randSeed, bytes32 key) {
        Player newPlayer = players[addr];
        newPlayer.balance = balance;
        newPlayer.pass = false;
        newPlayer.randSeed = randSeed;
        newPlayer.order = 0;
				newPlayer.pubKey = key;
    }


    //Adds a player to the game, provided amount meets minimum buy in.
    function addPlayer(bytes32 key, uint randSeed)
				payable
				timedTransitions
				atStage(Stages.AddPlayers) {
	      if (addPlayers && msg.value >= buyIn) {
	              randNum += randSeed;
	              constructPlayer(msg.sender, msg.value, randSeed, key);
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

		function removePlayer(address addr) private {
			cashOut(addr);
		}

    function cashOut(address addr) returns (bool) {
				if (addr != msg.sender) throw;
				for (uint i = 0; i < roundPlayers.length; i++) {
					if (roundPlayers[i] == msg.sender) throw;
				}
        Player player = players[msg.sender];
        uint amount = player.balance;
				if (player.balance == 0) throw;
        player.balance = 0;
        if (!msg.sender.send(amount)) {
            player.balance = amount;
            return false;
        }
        remove(msg.sender);
        return true;
    }

    function remove(address addr) private {
            Player player = players[addr];
            numPlayers -= 1;
            player.pass = false;
            player.order = 0;
            player.score = 0;
            player.randSeed = 0;
						player.pubKey = 0;
            delete player.hand;
    }

    //Allows players to place bet and participate in the next round.
    function ante(uint randSeed)
				timedTransitions
				atStage(Stages.AnteUp) {
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


    function dealCards()
				timedTransitions
				atStage(Stages.Play)
				{
				if (!deal) {
					throw;
				}

        for (uint i = 0; i < roundPlayers.length * 2; i++) {
            Player player = players[roundPlayers[i % roundPlayers.length]];
            uint card = drawCard(player);
            cardsDrawn.push(card);
            player.hand.push(card);
        }
				deal = false;
    }


    //Deals a player a random card.
    /* TODO: need to check for card collisions */
    function drawCard(Player player)
				private
				timedTransitions
				atStage(Stages.Play)
				returns (uint) {
        uint card = (player.randSeed + block.number) % 416;
				bool loop = true;
				player.randSeed += card;
				while (loop) {
					for (uint j = 0; j < cardsDrawn.length; j++) {
						if (cardsDrawn[j] == card) {
							card = (player.randSeed + block.number) % 416;
							break;
						}
					}
					loop = false;
				}
        return card;
    }

    function play(bool hit, uint randSeed)
				timedTransitions
				atStage(Stages.Play)
				{
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


    function determineWinner()
				timedTransitions
				atStage(Stages.Play)
				{
        if (numPasses < roundPlayers.length) throw;
        uint maxScore = 0;
        for (uint i = 0; i < roundPlayers.length; i += 1) {
            Player player = players[roundPlayers[i]];
            player.score = calculateScore(player);
            if (player.score > maxScore && player.score <= 21) {
                maxScore = player.score;
            }
        }
        for (uint j = 0; j < roundPlayers.length; j++) {
            player = players[roundPlayers[j]];
            if (player.score == maxScore) {
                winners.push(roundPlayers[j]);
            }
        }
				payWinners(winners);
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


    function payWinners(address[] addrs) private {
        for (uint i = 0; i < addrs.length; i++) {
            Player winner = players[addrs[i]];
            uint amtToSend = pot/addrs.length;
            winner.balance += amtToSend;
            pot -= amtToSend;
        }
				clear();
  	}

    function clear() private {
        addPlayers = true;
        numPasses = 0;
				deal = true;
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
				stage = Stages.AddPlayers;
    }
}
