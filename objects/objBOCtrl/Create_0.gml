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
hoverTabLobbies = false;
hoverTabMatch = false;
hoverCreate = false;
hoverJoin = false;
hoverLeave = false;
hoverStartRace = false;
hoverClaim = false;
hoverRematchYes = false;
hoverRematchNo = false;
hoverNextChallenger = false;
hoverBetP1 = false;
hoverBetP2 = false;
hoverBetSend = false;
hoverBet1 = false;
hoverBet5 = false;
hoverBet10 = false;
hoverBet25 = false;
hoverBet100 = false;

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
showdownMenuTab = "lobbies";
showdownCurrentLobbyId = "";
showdownCurrentLobbyName = "No lobby";
showdownRole = "spectator";
showdownState = "waiting";
showdownRaceSeed = 0;
localRaceSeedStarted = 0;
showdownWinnerId = "";
showdownLoserId = "";
showdownPromptOpen = false;
showdownAllowBets = false;
showdownSummary = "Waiting for showdown lobby.";
showdownRematchVotes = {};
showdownParticipants = [];
showdownHostPlayerId = "";
showdownYouAreHost = false;
showdownBreakoutBets = [];

selectedBetTarget = 1;
selectedBetAmount = 10;
progressSendCooldown = 0;
localRaceSubmitted = false;
showdownLocalFinished = false;

opponentName = "Waiting...";
opponentScore = 0;
opponentLevel = 1;
opponentLives = 3;
opponentDistance = 0;
opponentBatNorm = 0.5;
opponentBallXNorm = 0.5;
opponentBallYNorm = 0.85;
opponentBrickCount = 0;

showdownPlayer1Id = "";
showdownPlayer2Id = "";
showdownP1Name = "Player 1";
showdownP2Name = "Player 2";
showdownP1Breakout = { score: 0, level: 1, lives: 3, distance: 0, batNorm: 0.5, ballXNorm: 0.5, ballYNorm: 0.85, brickCount: 0, brickMask: "", brickColorMask: "" };
showdownP2Breakout = { score: 0, level: 1, lives: 3, distance: 0, batNorm: 0.5, ballXNorm: 0.5, ballYNorm: 0.85, brickCount: 0, brickMask: "", brickColorMask: "" };
showdownP1BallXDraw = 0.5;
showdownP1BallYDraw = 0.85;
showdownP2BallXDraw = 0.5;
showdownP2BallYDraw = 0.85;
showdownP1BatDraw = 0.5;
showdownP2BatDraw = 0.5;

arenaW = 640;
arenaH = 480;
soloArenaX = floor((room_width - arenaW) * 0.5);
soloArenaY = floor((room_height - arenaH) * 0.5);
showdownArenaLeftX = 20;
showdownArenaRightX = room_width - 20 - arenaW;
showdownArenaY = floor((room_height - arenaH) * 0.5);
currentArenaX = soloArenaX;
currentArenaY = soloArenaY;

gridCell = 32;
gridCols = 18;
gridRows = 6;
gridStartX = currentArenaX + 32;
gridStartY = currentArenaY + 32;
defaultGridRows = 6;
defaultGridStartY = currentArenaY + 32;
showdownGridRows = 6;
showdownGridStartY = showdownArenaY + 32;

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