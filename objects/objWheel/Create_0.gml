// Roulette table setup and constants.
// Micro-adjust here: spin physics defaults, board dimensions, UI colors, and broker connection defaults.
//table vars
rotation = 0;
target = 0;
spinTimer = 120;
spinActive = false;
spinSpeed = 20;
decel = .98
minSpeed = 0.05
fullSpeedTimer = 0;  // counts down before decel starts
markerAngle = 0; // not used for steering anymore — ball stops freely
segmentAngle = 0;
wheelAngle = 0;
wheelOrder = [ 
	0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23,
    10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26
];

segmentAngle = 360 / array_length(wheelOrder);

//ball vars
ballAngle = markerAngle;
ballSpeed = 0; 
ballDecel = 0.985;
ballMinSpeed = 0.1;
ballSettleRate = 0.18;
ballRadius = 325;
ballState = 0;
resultLocked = false;
betsResolved = true;
winningNumber = -1;
finalBallAngle = 0;
zeroOffset = 90; // green (0 pocket) sits at 90 degrees when rotation=0

//table UI vars
feltColor = make_color_rgb(18, 72, 58);
feltDarkColor = make_color_rgb(9, 20, 26);
lineColor = make_color_rgb(93, 228, 207);
panelColor = make_color_rgb(16, 15, 25);
chipColor = make_color_rgb(213, 43, 102);
chipShadowColor = make_color_rgb(74, 17, 45);
ownChipColor = make_color_rgb(194, 45, 54);
ownChipShadowColor = make_color_rgb(101, 22, 29);
otherChipColor = make_color_rgb(26, 29, 34);
otherChipShadowColor = make_color_rgb(8, 9, 11);
redCellColor = make_color_rgb(190, 34, 76);
blackCellColor = make_color_rgb(16, 15, 25);
greenCellColor = make_color_rgb(28, 126, 98);
bankroll = 1000;
currentChip = 10;
chipOptions = [1, 5, 10, 25, 100];
lastWager = 0;
lastPayout = 0;
lastSpinSummary = "Place bets, then click SPIN.";
hoverBetIndex = -1;
multiplayerEnabled = true;
brokerHost = "wss://sadgirlsclub.wtf/ws";
brokerPort = 443;
brokerSocket = -1;
brokerConnected = false;
brokerStatus = "Connecting to broker...";
brokerPlayerId = "";
brokerPlayerCount = 1;
brokerPhase = "local";
currentLobbyId = "";
currentLobbyName = "No lobby";
lobbyList = [];
activePlayers = [];
selectedLobbyId = "";
rouletteLobbyOpen = multiplayerEnabled;
playerName = "Player " + string(irandom_range(1000, 9999));
pendingSpinPlan = undefined;
activeSpinId = -1;

tableX = VIEW_W * 0.1;
tableY = VIEW_H * 0.2;
zeroW = 54;
cellW = 38;
cellH = cellW;
colW = 52;
outsideH = 32;
tableW = zeroW + (cellW * 12) + colW;
tableH = (cellH * 3) + (outsideH * 2);
feltPadX = 14;
feltPadTop = 54;
feltPadBottom = 28;

//panelX = tableX + tableW + 24;
panelX = VIEW_W * 0.1;
panelY = VIEW_H * 0.4;
spinButton = { x: panelX, y: panelY, w: 150, h: 40 };
clearButton = { x: panelX, y: panelY + 48, w: 150, h: 34 };
lobbyButton = { x: VIEW_W - 360, y: 20, w: 140, h: 34 };
menuButton = { x: VIEW_W - 200, y: 20, w: 170, h: 34 };
chipButtons = [];
betAreas = [];
lobbyPanel = {
	x1: VIEW_W * 0.5 - 300,
	y1: 95,
	x2: VIEW_W * 0.5 + 300,
	y2: 520
};
createLobbyButton = { x: VIEW_W * 0.5 - 276, y: 508, w: 170, h: 52 };
joinLobbyButton = { x: VIEW_W * 0.5 - 86, y: 508, w: 170, h: 52 };
leaveLobbyButton = { x: VIEW_W * 0.5 + 104, y: 508, w: 170, h: 52 };
enterLobbyButton = { x: VIEW_W * 0.5 - 135, y: 570, w: 270, h: 48 };

function addBetArea(_key, _label, _x, _y, _w, _h, _covered, _payout, _baseColor, _textColor) {
	array_push(betAreas, {
		key: _key,
		label: _label,
		x: _x,
		y: _y,
		w: _w,
		h: _h,
		covered: _covered,
		payout: _payout,
		amount: 0,
		totalAmount: 0,
		baseColor: _baseColor,
		textColor: _textColor
	});
}

function buildRange(_startValue, _endValue) {
	var values = [];
	for (var n = _startValue; n <= _endValue; n++) {
		array_push(values, n);
	}
	return values;
}

function buildColumn(_modValue) {
	var rowIndex = 3 - _modValue;
	var startValue = (rowIndex * 12) + 1;
	return buildRange(startValue, startValue + 11);
}

function buildEvenMoney(_kind) {
	var values = [];
	for (var n = 1; n <= 36; n++) {
		var include = false;
		switch (_kind) {
			case "low": include = n <= 18; break;
			case "high": include = n >= 19; break;
			case "even": include = (n mod 2) == 0; break;
			case "odd": include = (n mod 2) == 1; break;
			case "red": include = rouletteIsRed(n); break;
			case "black": include = !rouletteIsRed(n); break;
		}

		if (include) {
			array_push(values, n);
		}
	}
	return values;
}

addBetArea("n_0", "0", tableX, tableY, zeroW, cellH * 3, [0], 35, greenCellColor, c_white);

for (var street = 0; street < 12; street++) {
	var xCell = tableX + zeroW + (street * cellW);

	for (var row = 0; row < 3; row++) {
		var number = (row * 12) + street + 1;
		var yCell = tableY + (row * cellH);
		var cellColor = rouletteIsRed(number) ? redCellColor : blackCellColor;
		addBetArea("n_" + string(number), string(number), xCell, yCell, cellW, cellH, [number], 35, cellColor, c_white);
	}
}

var columnX = tableX + zeroW + (cellW * 12);
addBetArea("col_3", "2:1", columnX, tableY, colW, cellH, buildColumn(3), 2, feltDarkColor, lineColor);
addBetArea("col_2", "2:1", columnX, tableY + cellH, colW, cellH, buildColumn(2), 2, feltDarkColor, lineColor);
addBetArea("col_1", "2:1", columnX, tableY + (cellH * 2), colW, cellH, buildColumn(1), 2, feltDarkColor, lineColor);

var dozenY = tableY + (cellH * 3);
addBetArea("dozen_1", "1st 12", tableX + zeroW, dozenY, cellW * 4, outsideH, buildRange(1, 12), 2, feltDarkColor, lineColor);
addBetArea("dozen_2", "2nd 12", tableX + zeroW + (cellW * 4), dozenY, cellW * 4, outsideH, buildRange(13, 24), 2, feltDarkColor, lineColor);
addBetArea("dozen_3", "3rd 12", tableX + zeroW + (cellW * 8), dozenY, cellW * 4, outsideH, buildRange(25, 36), 2, feltDarkColor, lineColor);

var evenY = dozenY + outsideH;
addBetArea("low", "1-18", tableX + zeroW, evenY, cellW * 2, outsideH, buildEvenMoney("low"), 1, feltDarkColor, lineColor);
addBetArea("even", "EVEN", tableX + zeroW + (cellW * 2), evenY, cellW * 2, outsideH, buildEvenMoney("even"), 1, feltDarkColor, lineColor);
addBetArea("red", "RED", tableX + zeroW + (cellW * 4), evenY, cellW * 2, outsideH, buildEvenMoney("red"), 1, redCellColor, c_white);
addBetArea("black", "BLACK", tableX + zeroW + (cellW * 6), evenY, cellW * 2, outsideH, buildEvenMoney("black"), 1, blackCellColor, c_white);
addBetArea("odd", "ODD", tableX + zeroW + (cellW * 8), evenY, cellW * 2, outsideH, buildEvenMoney("odd"), 1, feltDarkColor, lineColor);
addBetArea("high", "19-36", tableX + zeroW + (cellW * 10), evenY, cellW * 2, outsideH, buildEvenMoney("high"), 1, feltDarkColor, lineColor);

for (var chipIndex = 0; chipIndex < array_length(chipOptions); chipIndex++) {
	array_push(chipButtons, {
		x: panelX + ((chipIndex mod 2) * 76),
		y: panelY + 116 + (floor(chipIndex / 2) * 42),
		w: 66,
		h: 32,
		value: chipOptions[chipIndex]
	});
}

if (multiplayerEnabled) {
	brokerSocket = network_create_socket(network_socket_ws);
	if (brokerSocket >= 0) {
		var connectState = network_connect_raw_async(brokerSocket, brokerHost, brokerPort);
		if (connectState < 0) {
			brokerStatus = "Broker connect failed.";
		}
	} else {
		brokerStatus = "Socket creation failed.";
	}
}

display_reset(0, true);