// This child object controls only the Horse Race table.
// event_inherited() runs common setup first so we only override game-specific routing here.
event_inherited();

// Lock this instance to the horse game mode.
selectedGame = GAME_HORSE;
tableGameKey = "horse";
tableRoomLocked = true;
tableLobbyOpen = true;
statusText = "Pick a horse, then start the race.";