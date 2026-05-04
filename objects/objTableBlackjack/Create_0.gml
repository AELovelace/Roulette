// This child object represents only the Blackjack table.
// event_inherited() is important in GML inheritance: it runs the parent Create code first.
event_inherited();

// Lock game selection to Blackjack for this room.
selectedGame = GAME_BLACKJACK;
tableGameKey = "blackjack";
tableRoomLocked = true;
tableLobbyOpen = true;
statusText = "Deal a hand, then choose hit or stay.";