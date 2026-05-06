// Table lobby setup.
// Micro-adjust here: table metadata, card sizing grid, and default copy for the selection screen.
backgroundTop = make_color_rgb(5, 6, 10);
backgroundBottom = make_color_rgb(34, 15, 38);
panelColor = make_color_rgb(16, 15, 25);
railColor = make_color_rgb(93, 228, 207);
buttonColor = make_color_rgb(30, 24, 43);
buttonHoverColor = make_color_rgb(42, 64, 72);
accentColor = make_color_rgb(213, 43, 102);
accentHoverColor = make_color_rgb(246, 94, 137);
textColor = c_white;
mutedTextColor = make_color_rgb(204, 195, 214);
selectedTable = 0;
hoveredButton = "";
statusText = "[SYS] choose a LumiGames table node.";

tableNames = ["Roulette", "Slots", "Pachinko", "Blackjack", "Hold'em", "Horse Race"];
tableDescriptions = [
	"Single-zero wheel with synced lobbies",
	"Three Seat Lobby",
	"Three Seat Lobby",
	"Six-seat dealer blackjack",
	"Eight-seat Hold'em",
	"Twenty-seat races"
];
tableRooms = [RoomRoulette, RoomSlots, RoomPachinko, RoomBlackjack, RoomHoldem, RoomHorseRace];

function lobbyButton(_index) {
	var columns = 3;
	var cardW = 388;
	var cardH = 132;
	var gapX = 34;
	var gapY = 28;
	var rows = ceil(array_length(tableNames) / columns);
	var gridW = columns * cardW + (columns - 1) * gapX;
	var gridH = rows * cardH + (rows - 1) * gapY;
	var originX = max(24, (VIEW_W - gridW) * 0.5);
	var originY = max(140, (VIEW_H - gridH) * 0.5);
	var buttonX = originX + (_index mod columns) * (cardW + gapX);
	var buttonY = originY + (_index div columns) * (cardH + gapY);
	return { x: buttonX, y: buttonY, w: cardW, h: cardH, label: tableNames[_index] };
}

function pointInLobbyButton(_button, _mx, _my) {
	return point_in_rectangle(_mx, _my, _button.x, _button.y, _button.x + _button.w, _button.y + _button.h);
}

function enterSelectedTable() {
	room_goto(tableRooms[selectedTable]);
}