// This object is the Pachinko table controller for its room.
// Calling event_inherited() keeps all shared systems (UI, networking, helper functions) active.
event_inherited();

// Force this child object to Pachinko-specific state.
selectedGame = GAME_PACHINKO;
tableGameKey = "pachinko";
tableRoomLocked = true;
tableLobbyOpen = true;
statusText = "Set your peg and drop the ball.";