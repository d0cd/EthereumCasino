pragma solidity ^0.4.8;


contract BlockJack {

		enum Stages {
			AddPlayers,
			AnteUp,
			Deal,
			Play
		}

    //Variables to keep track of game state.
    uint public buyIn;
    uint public numPlayers;
    uint[] public cardsDrawn;
    uint timeLimit = 2 minutes;
    uint turn = 0;
    uint public pot = 0;
    uint numPasses = 0;
    uint randNum;
    uint maxPlayers;
    address[] roundPlayers;
		address[] allPlayers;
    address[] winners;
		bool deal;
		uint private gameIndex;
		uint timer;

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
		mapping (uint => Player) orders;

		Stages public stage = Stages.AddPlayers;
    uint public time = now;
		modifier atStage(Stages _stage) {
				if (stage != _stage) throw;
				_;
		}


		function nextStage() internal {
				stage = Stages(uint(stage) + 1);
				if (stage == Stages.Play) {
					timer = now;
				}
		}

		//TODO: Destroy game if no one is resonding
		modifier timedTransitions() {
			if (stage == Stages.AddPlayers && now >= time + 5 minutes && numPlayers > 1) {
				nextStage();
			}
			if (stage == Stages.AnteUp && roundPlayers.length > 1) {
				nextStage();
			}
			_;
		}
    //Creates a new BlockJack game, where the amount sent in
    //transaction is the minimum buy in.
    function BlockJack(uint randSeed, uint playerCap, uint bet, uint index) {
          buyIn = bet;
          randNum = block.timestamp + randSeed;
          maxPlayers = playerCap;
					deal = true;
					numPlayers = 0;
					gameIndex = index;
    }

    function constructPlayer(address addr, uint balance, uint randSeed) private {
        Player newPlayer = players[addr];
        newPlayer.balance = balance;
        newPlayer.pass = false;
        newPlayer.randSeed = randSeed;
        newPlayer.order = 0;
    }


    //Adds a player to the game, provided amount meets minimum buy in.
    function addPlayerFromCasino(uint randSeed, address addr)
				payable
				timedTransitions
				atStage(Stages.AddPlayers)
				returns (uint) {
	      if (msg.value >= buyIn) {
	              randNum += randSeed;
	              constructPlayer(addr, msg.value, randSeed);
	              numPlayers += 1;
	              if (numPlayers == maxPlayers) {
										nextStage();
	              }
								return numPlayers;
	      } else {
	              throw;

	      	}
  	}

		function addPlayer(uint randSeed)
			payable
			timedTransitions
			atStage(Stages.AddPlayers) {
			if (msg.value >= buyIn) {
							randNum += randSeed;
							constructPlayer(msg.sender, msg.value, randSeed);
							numPlayers += 1;
							if (numPlayers == maxPlayers) {
									nextStage();
							}
			} else {
							throw;
				}
		}

    function addFunds() payable {
        Player thisPlayer = players[msg.sender];
        thisPlayer.balance += msg.value;
    }

		function removePlayer() {
			for (uint i = 0; i < roundPlayers.length; i++) {
				if (roundPlayers[i] == msg.sender) throw;
			}
			if (numPlayers <= 2) {
				for (i = 0; i < allPlayers.length; i++) {
					cashOut(allPlayers[i]);
				}
			} else {
					cashOut(msg.sender);
			}
		}

    function cashOut(address addr) private {
        Player player = players[addr];
        uint amount = player.balance;
				if (player.balance == 0) throw;
        player.balance = 0;
        if (!addr.send(amount)) {
            player.balance = amount;
        } else {
        		remove(addr);
				}
    }

    function remove(address addr) private {
            Player player = players[addr];
            numPlayers -= 1;
            player.pass = false;
            player.order = 0;
            player.score = 0;
            player.randSeed = 0;
            delete player.hand;
    }

    //Allows players to place bet and participate in the next round.
    function ante(uint randSeed)
				timedTransitions
				atStage(Stages.AnteUp) {
        Player player = players[msg.sender];
        if (player.balance < buyIn) throw;
				player.balance -= buyIn;
				pot += buyIn;
        randNum += randSeed;
        player.order = roundPlayers.length;
				orders[player.order] = player;
        player.randSeed = player.randSeed * randNum;
        roundPlayers.push(msg.sender);
				if (roundPlayers.length == allPlayers.length) {
					nextStage();
				}
    }


    function dealCards()
				timedTransitions
				atStage(Stages.Deal)
				{
				if (!deal) {
					throw;
				}

        for (uint i = 0; i < roundPlayers.length * 2; i++) {
            Player player = players[roundPlayers[i % roundPlayers.length]];
            uint card = drawCard(player);
            cardsDrawn.push(card);
            player.hand.push(card);
						randNum = randNum * card;
        }
				for (uint j = 0; j < roundPlayers.length; j++) {
					player = players[roundPlayers[j]];
					player.score = calculateScore(player);
				}
				deal = false;
				nextStage();
    }


    //Deals a player a random card.
    /* TODO: need to check for card collisions */
    function drawCard(Player player)
				private
				timedTransitions
				atStage(Stages.Play)
				returns (uint) {
        uint card = (player.randSeed * randNum + block.timestamp) % 416;
				bool loop = true;
				player.randSeed += card;
				while (loop) {
					for (uint j = 0; j < cardsDrawn.length; j++) {
						if (cardsDrawn[j] == card) {
							card = (player.randSeed + block.timestamp) % 416;
							break;
						}
					}
					loop = false;
				}
        return card;
    }

    function hit (uint randSeed)
				timedTransitions
				atStage(Stages.Play)
				{
        Player player = players[msg.sender];
				if (now > timer + timeLimit) {
					orders[turn].pass = true;
				}
        else if (turn != player.order || player.pass || roundPlayers.length == numPasses) {
            throw;
        }
        else {
            uint card = drawCard(player);
            cardsDrawn.push(card);
            player.hand.push(card);
            player.score = calculateScore(player);
            if(player.score >= 21) {
                //Bust or 21
                player.pass == true;
                numPasses += 1;
            }
        }
        if (turn == roundPlayers.length) {
            turn = 0;
        } else {
            turn += 1;
        }
    }

		function surrender()
				timedTransitions
				atStage(Stages.Play)
				{
				Player player = players[msg.sender];
				if (now > timer + timeLimit) {
					orders[turn].pass = true;
				}
        else if (turn != player.order || player.pass || roundPlayers.length == numPasses) {
            throw;
				} else {
						if (player.hand.length == 2) {
								player.score = 100;
								player.balance += buyIn / 2;
								pot -= buyIn / 2;
						} else {
							throw;
						}
				}
				if (turn == roundPlayers.length) {
						turn = 0;
				} else {
						turn += 1;
				}
		}

		function pass()
				timedTransitions
				atStage(Stages.Play)
				{
				Player player = players[msg.sender];
				if (now > timer + timeLimit) {
					orders[turn].pass = true;
				}
				else if (turn != player.order || player.pass || roundPlayers.length == numPasses) {
						throw;
				} else {
					player.pass = true;
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
				uint numAces = 0;
        for (uint i = 0; i < player.hand.length; i++) {
            uint card = player.hand[i] % 52 % 13;
						if (card > 10) {
							card = 10;
						}
						if (card == 0) {
							numAces += 1;
						}
            score += card;
        }
				for (uint j = 0; j < numAces; j++) {
					if (score + 11 > 21) {
						score += 1;
					} else {
						score += 11;
					}
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

		function getBuyIn() returns (uint) {
			return buyIn;
		}

		function isFull() returns (bool) {
			return numPlayers == maxPlayers;
		}

		function getNumPlayers() returns (uint res) {
			return numPlayers;
		}

		function getPot() returns (uint) {
			return pot;
		}

		function getCards(address addr) returns (uint[]) {
			return players[addr].hand;
		}

		function getFirstCard() returns (uint) {
			return cardsDrawn[0];
		}

		function getAllCards() returns (uint[]) {
			return cardsDrawn;
		}

		function getBalance() returns (uint) {
			return players[msg.sender].balance;
		}

		function getScore() returns (uint) {
			return players[msg.sender].score;
		}

		function getAddr() returns (address) {
			return this;
		}

}
