// Arcade lobby setup.
// Mirrors table-lobby layout/style, scoped to arcade minigames.
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
selectedArcade = 0;
hoveredButton = "";
statusText = "[SYS] choose an arcade node.";

arcadeNames = ["Breakout", "Neon Runner", "Asteroid Sweep", "Snake Grid"];
arcadeDescriptions = [
	"25 SGC buy-in. Multiplayer showdown.",
	"Endless lane dash with traps. (Coming soon)",
	"Arcade asteroid blaster. (Coming soon)",
	"Classic snake with wager rounds. (Coming soon)"
];
arcadeRooms = [
	asset_get_index("rmBreakout"),
	asset_get_index("RoomArcadeNeonRunner"),
	asset_get_index("RoomArcadeAsteroidSweep"),
	asset_get_index("RoomArcadeSnakeGrid")
];

function arcadeIsAvailable(_index) {
	if (_index < 0 || _index >= array_length(arcadeRooms)) return false;
	return arcadeRooms[_index] != -1;
}

function arcadeStatusFor(_index) {
	if (_index < 0 || _index >= array_length(arcadeNames)) return "[SYS] choose an arcade node.";
	if (arcadeIsAvailable(_index)) return "[SYS] ready: " + arcadeNames[_index] + ".";
	return "[SYS] " + arcadeNames[_index] + " is coming soon.";
}

function arcadeLobbyButton(_index) {
	var columns = min(3, array_length(arcadeNames));
	var cardW = 388;
	var cardH = 132;
	var gapX = 34;
	var gapY = 28;
	var rows = ceil(array_length(arcadeNames) / columns);
	var gridW = columns * cardW + (columns - 1) * gapX;
	var gridH = rows * cardH + (rows - 1) * gapY;
	var originX = max(24, (VIEW_W - gridW) * 0.5);
	var originY = max(140, (VIEW_H - gridH) * 0.5);
	var buttonX = originX + (_index mod columns) * (cardW + gapX);
	var buttonY = originY + (_index div columns) * (cardH + gapY);
	return { x: buttonX, y: buttonY, w: cardW, h: cardH, label: arcadeNames[_index] };
}

function pointInArcadeLobbyButton(_button, _mx, _my) {
	return point_in_rectangle(_mx, _my, _button.x, _button.y, _button.x + _button.w, _button.y + _button.h);
}

function enterSelectedArcade() {
	if (arcadeIsAvailable(selectedArcade)) {
		room_goto(arcadeRooms[selectedArcade]);
	} else {
		statusText = arcadeStatusFor(selectedArcade);
	}
}
