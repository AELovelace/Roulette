state = "START";
mode = "menu";

if (!variable_global_exists("sgcArcadeBalance")) global.sgcArcadeBalance = 500;
if (!variable_global_exists("snakeHighScore")) global.snakeHighScore = 0;

entryCost = 25;
scoreToSgcRate = 1;
runCharged = false;
payoutSettled = false;
lastRunPayout = 0;
runNet = -entryCost;
statusText = "Choose Solo or Showdown.";

soloStartPending = false;
soloSettlePending = false;

hoverSolo = false;
hoverShowdown = false;
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
hoverBet1 = false;
hoverBet5 = false;
hoverBet10 = false;
hoverBet25 = false;
hoverBet100 = false;

snakeBrokerHost = "wss://sadgirlsclub.wtf/ws";
snakeBrokerPort = 443;
snakeBrokerSocket = -1;
snakeBrokerConnected = false;
snakeBrokerStatus = "Connecting to broker...";
snakePlayerId = "";
snakePlayerName = variable_global_exists("sgcDisplayName") && global.sgcDisplayName != "" ? global.sgcDisplayName : "Player " + string(irandom_range(1000, 9999));

showdownGameKey = "snake";
showdownLobbyList = [];
showdownSelectedLobbyId = "";
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
showdownSnakeBets = [];
showdownPlayer1Id = "";
showdownPlayer2Id = "";
showdownP1Name = "Player 1";
showdownP2Name = "Player 2";
showdownP1Snake = { score: 0, length: 3, distance: 0, headXNorm: 0.5, headYNorm: 0.5, alive: true, segmentPoints: [] };
showdownP2Snake = { score: 0, length: 3, distance: 0, headXNorm: 0.5, headYNorm: 0.5, alive: true, segmentPoints: [] };

selectedBetTarget = 1;
selectedBetAmount = 10;
progressSendCooldown = 0;
localRaceSubmitted = false;
showdownLocalFinished = false;

gridW = 20;
gridH = 15;
cellSize = 32;
boardW = gridW * cellSize;
boardH = gridH * cellSize;
boardX = floor((room_width - boardW) * 0.5);
boardY = floor((room_height - boardH) * 0.5);

gameBoard = ds_grid_create(gridW, gridH);
snakeX = [];
snakeY = [];
snakeDirX = 1;
snakeDirY = 0;
snakeNextDirX = 1;
snakeNextDirY = 0;
moveDelay = 8;
moveTimer = 0;
snakeScore = 0;
snakeAlive = true;
snakeStarted = false;
snakeLength = 3;
snakeFoodSpawnIndex = 0;
snakeRaceSeedActive = 0;

function snakeDistance(_ctrl) {
	return max(0, _ctrl.snakeScore) + max(0, _ctrl.snakeLength - 3) * 5;
}

function snakeSeedValue(_seed, _index, _salt) {
	var baseSeed = max(1, floor(abs(_seed)));
	var baseIndex = max(0, floor(_index));
	var salt = max(1, floor(abs(_salt)));
	var mix = (baseSeed * 1664525 + (baseIndex + 1) * 1013904223 + salt * 69069) mod 2147483647;
	if (mix <= 0) mix += 2147483646;
	return mix;
}

function snakeSpawnFood(_ctrl) {
	var emptyCells = [];
	for (var xx = 0; xx < _ctrl.gridW; xx++) {
		for (var yy = 0; yy < _ctrl.gridH; yy++) {
			if (_ctrl.gameBoard[# xx, yy] == 0) {
				array_push(emptyCells, [xx, yy]);
			}
		}
	}

	if (array_length(emptyCells) <= 0) {
		return false;
	}

	var spawnIndex = _ctrl.snakeFoodSpawnIndex;
	var chosenIndex;
	var roll;
	if (_ctrl.mode == "showdown" && _ctrl.snakeRaceSeedActive > 0) {
		var positionSeed = snakeSeedValue(_ctrl.snakeRaceSeedActive, spawnIndex, 17);
		var valueSeed = snakeSeedValue(_ctrl.snakeRaceSeedActive, spawnIndex, 53);
		chosenIndex = positionSeed mod array_length(emptyCells);
		roll = valueSeed mod 100;
	} else {
		chosenIndex = irandom(array_length(emptyCells) - 1);
		roll = irandom(99);
	}

	var chosen = emptyCells[chosenIndex];
	var fx = chosen[0];
	var fy = chosen[1];
	if (roll < 70) {
		_ctrl.gameBoard[# fx, fy] = 2;
	} else if (roll < 92) {
		_ctrl.gameBoard[# fx, fy] = 3;
	} else {
		_ctrl.gameBoard[# fx, fy] = 4;
	}

	_ctrl.snakeFoodSpawnIndex += 1;
	return true;
}

function snakeResetBoard(_ctrl) {
	ds_grid_clear(_ctrl.gameBoard, 0);
	_ctrl.snakeX = [10, 9, 8];
	_ctrl.snakeY = [7, 7, 7];
	_ctrl.snakeDirX = 1;
	_ctrl.snakeDirY = 0;
	_ctrl.snakeNextDirX = 1;
	_ctrl.snakeNextDirY = 0;
	_ctrl.snakeScore = 0;
	_ctrl.snakeAlive = true;
	_ctrl.snakeStarted = false;
	_ctrl.moveTimer = 0;
	_ctrl.snakeFoodSpawnIndex = 0;
	for (var i = 0; i < array_length(_ctrl.snakeX); i++) {
		_ctrl.gameBoard[# _ctrl.snakeX[i], _ctrl.snakeY[i]] = 1;
	}
	if (!snakeSpawnFood(_ctrl)) {
		_ctrl.snakeAlive = false;
	}
	_ctrl.snakeLength = array_length(_ctrl.snakeX);
}

function snakeReadTelemetry(_ctrl) {
	var headX = _ctrl.snakeX[0];
	var headY = _ctrl.snakeY[0];
	var segmentPoints = [];
	for (var i = 0; i < array_length(_ctrl.snakeX); i++) {
		array_push(segmentPoints, clamp((_ctrl.snakeX[i] + 0.5) / max(1, _ctrl.gridW), 0, 1));
		array_push(segmentPoints, clamp((_ctrl.snakeY[i] + 0.5) / max(1, _ctrl.gridH), 0, 1));
	}
	return {
		score: _ctrl.snakeScore,
		length: array_length(_ctrl.snakeX),
		distance: snakeDistance(_ctrl),
		headXNorm: clamp((headX + 0.5) / max(1, _ctrl.gridW), 0, 1),
		headYNorm: clamp((headY + 0.5) / max(1, _ctrl.gridH), 0, 1),
		alive: _ctrl.snakeAlive,
		segmentPoints: segmentPoints
	};
}

function snakeBeginRun(_ctrl) {
	_ctrl.payoutSettled = false;
	_ctrl.lastRunPayout = 0;
	_ctrl.runNet = -_ctrl.entryCost;
	_ctrl.localRaceSubmitted = false;
	_ctrl.showdownLocalFinished = false;
	if (_ctrl.mode == "showdown") {
		_ctrl.localRaceSeedStarted = _ctrl.showdownRaceSeed;
		_ctrl.snakeRaceSeedActive = max(1, floor(abs(_ctrl.showdownRaceSeed)));
	} else {
		_ctrl.snakeRaceSeedActive = 0;
	}
	snakeResetBoard(_ctrl);
	_ctrl.state = "PLAYING";
	_ctrl.statusText = _ctrl.mode == "showdown" ? "Snake showdown ready. Press Space to start." : "[SGC] Snake run ready. Press Space to start.";
}

function snakeRequestSoloStart(_ctrl) {
	_ctrl.mode = "solo";
	if (_ctrl.snakeBrokerConnected) {
		_ctrl.soloStartPending = true;
		_ctrl.statusText = "[SGC] Requesting 25-coin deposit...";
		rouletteSendJson(_ctrl.snakeBrokerSocket, { type: "snake_single_start" });
	} else {
		if (global.sgcArcadeBalance < _ctrl.entryCost) {
			_ctrl.statusText = "[SGC] Need " + string(_ctrl.entryCost) + " coins to start.";
			return;
		}
		global.sgcArcadeBalance -= _ctrl.entryCost;
		_ctrl.runCharged = true;
		snakeBeginRun(_ctrl);
	}
}

function snakeRequestShowdownWatch(_ctrl) {
	_ctrl.mode = "showdown";
	_ctrl.state = "SHOWDOWN_LOBBY";
	_ctrl.statusText = "Joining Snake showdown...";
	if (_ctrl.snakeBrokerConnected) {
		rouletteSendJson(_ctrl.snakeBrokerSocket, { type: "table_watch", game: _ctrl.showdownGameKey });
	}
}

if (snakeBrokerSocket < 0) {
	snakeBrokerSocket = network_create_socket(network_socket_ws);
	if (snakeBrokerSocket >= 0) {
		var connectState = network_connect_raw_async(snakeBrokerSocket, snakeBrokerHost, snakeBrokerPort);
		if (connectState < 0) snakeBrokerStatus = "Broker connect failed.";
	} else {
		snakeBrokerStatus = "Socket creation failed.";
	}
}