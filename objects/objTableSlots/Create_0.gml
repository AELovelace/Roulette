// This runs first for the Slots table object.
// event_inherited() executes the parent object's Create event so shared setup still happens.
event_inherited();

// Explicitly pin this object to Slots so the table cannot accidentally open another game.
selectedGame = GAME_SLOTS;
tableGameKey = "slots";
tableRoomLocked = true;
tableLobbyOpen = true;
statusText = "Pick a seat and spin the reels.";