contract Blackjack {
	
	struct Player{
	    address player;
	    uint amount;
	}
	struct Game{
	    uint min_buy_in;
	    uint time_per_turn;
	    uint seats
	}
	struct Deck{

	}
	mapping (uint => Game) Games;
	mapping (uint => Player) Players;
	uint numGames;
	uint numPlayers;
	function newGame(uint min_buy_in){
            Game a = Games[numGames++];
            a.timer_per_turn = block.number + 60 seconds; //changing time later
            a.min_buy_in = min_buy_in;
            a.seats = 8;
	}
	function newPlayer(uint numGames){
	    Game a = Games[numGame]
	    if(a.seats = 0) || (amount < a.min_buy_in){
	        throw;
	    }
	    else{
	    Player c = Players[numPlayers++];
            c.player = msg.sender;
            c.amount = msg.value;
            a.seats -= 1;
	    }
	function play(uint numGames, uint numPlayers,)
	}
	}
}
