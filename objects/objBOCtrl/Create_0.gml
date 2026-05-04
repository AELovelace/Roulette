state = "START";
mode = "menu";
global.BOPScore = 0;
global.BOPLives = 3;
if (!variable_global_exists("highScore")) global.highScore = 0;
if (!variable_global_exists("sgcArcadeBalance")) global.sgcArcadeBalance = 500;

entryCost = 25;
scoreToSgcRate = 1;
level = 1;
runCharged = false;
payoutSettled = false;
lastRunPayout = 0;
runNet = -entryCost;
statusText = "Choose Solo or Showdown.";

soloStartPending = false;
soloSettlePending = false;
soloRequestedScore = 0;

hoverSolo = false;
hoverShowdown = false;
hoverCreate = false;
hoverJoin = false;
hoverStartRace = false;
hoverClaim = false;
hoverRematchYes = false;
hoverRematchNo = false;
hoverNextChallenger = false;
hoverBetP1 = false;
hoverBetP2 = false;
hoverBetSend = false;

breakoutBrokerHost = "wss://sadgirlsclub.wtf/ws";
breakoutBrokerPort = 443;
breakoutBrokerSocket = -1;
breakoutBrokerConnected = false;
breakoutBrokerStatus = "Connecting to broker...";
breakoutPlayerId = "";
breakoutPlayerName = variable_global_exists("sgcDisplayName") && global.sgcDisplayName != "" ? global.sgcDisplayName : "Player " + string(irandom_range(1000, 9999));

showdownGameKey = "breakout";
showdownLobbyList = [];
showdownSelectedLobbyId = "";
showdownCurrentLobbyId = "";
showdownCurrentLobbyName = "No lobby";
showdownRole = "spectator";
showdownState = "waiting";
showdownWinnerId = "";
showdownLoserId = "";
showdownPromptOpen = false;
showdownAllowBets = false;
showdownSummary = "Waiting for showdown lobby.";
showdownRematchVotes = {};
showdownParticipants = [];
showdownHostPlayerId = "";
showdownYouAreHost = false;

selectedBetTarget = 1;
selectedBetAmount = 10;
progressSendCooldown = 0;
localRaceSubmitted = false;

opponentName = "Waiting...";
opponentScore = 0;
opponentLevel = 1;
opponentLives = 3;
opponentDistance = 0;

gridCell = 32;
gridCols = 18;
gridRows = 6;
gridStartX = 32;
gridStartY = 32;
defaultGridRows = 6;
defaultGridStartY = 32;
showdownGridRows = 4;
showdownGridStartY = 236;

if (breakoutBrokerSocket < 0) {
	breakoutBrokerSocket = network_create_socket(network_socket_ws);
	if (breakoutBrokerSocket >= 0) {
		var connectState = network_connect_raw_async(breakoutBrokerSocket, breakoutBrokerHost, breakoutBrokerPort);
		if (connectState < 0) breakoutBrokerStatus = "Broker connect failed.";
	} else {
		breakoutBrokerStatus = "Socket creation failed.";
	}
}

breakoutHideBoard();