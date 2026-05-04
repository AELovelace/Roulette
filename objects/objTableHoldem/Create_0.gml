// This object is dedicated to Hold'em gameplay in its own room.
// The parent has shared table logic, so we call event_inherited() before overriding values.
event_inherited();

// Keep this table permanently mapped to Hold'em.
selectedGame = GAME_HOLDEM;
tableGameKey = "holdem";
tableRoomLocked = true;
tableLobbyOpen = true;
statusText = "Deal cards and play each betting round.";