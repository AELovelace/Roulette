function drawTableButton(_button, _selected, _hovered) {
	var fill = _selected ? accentColor : buttonColor;
	if (_hovered) {
		fill = _selected ? accentHoverColor : buttonHoverColor;
	}
	draw_set_color(fill);
	draw_roundrect(_button.x, _button.y, _button.x + _button.w, _button.y + _button.h, false);
	draw_set_color(railColor);
	draw_roundrect(_button.x, _button.y, _button.x + _button.w, _button.y + _button.h, true);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(textColor);
	draw_text(_button.x + _button.w * 0.5, _button.y + _button.h * 0.5, _button.label);
}

function drawChip(_x, _y, _amount, _selected) {
	var radius = _selected ? 27 : 23;
	draw_set_color(_selected ? accentColor : make_color_rgb(38, 44, 48));
	draw_circle(_x, _y, radius, false);
	draw_set_color(railColor);
	draw_circle(_x, _y, radius, true);
	draw_circle(_x, _y, radius - 8, true);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(textColor);
	draw_text(_x, _y, string(_amount));
}

function cardText(_card) {
	return _card.rank + _card.suit;
}

function drawPlayingCard(_x, _y, _card, _hidden) {
	draw_set_color(_hidden ? make_color_rgb(67, 31, 41) : make_color_rgb(238, 236, 225));
	draw_roundrect(_x, _y, _x + 66, _y + 92, false);
	draw_set_color(_hidden ? make_color_rgb(228, 166, 83) : c_black);
	draw_roundrect(_x, _y, _x + 66, _y + 92, true);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	if (_hidden) {
		draw_set_color(make_color_rgb(245, 206, 132));
		draw_text(_x + 33, _y + 46, "??");
	} else {
		var redSuit = (_card.suit == "H" || _card.suit == "D");
		draw_set_color(redSuit ? make_color_rgb(180, 38, 50) : c_black);
		draw_text(_x + 33, _y + 46, cardText(_card));
	}
}

function drawCardRow(_x, _y, _cards, _hiddenFromIndex) {
	for (var i = 0; i < array_length(_cards); i += 1) {
		drawPlayingCard(_x + i * 76, _y, _cards[i], i >= _hiddenFromIndex && _hiddenFromIndex >= 0);
	}
}

function drawGameShell(_title, _message) {
	draw_set_color(panelColor);
	draw_roundrect(34, 144, room_width - 34, 618, false);
	draw_set_color(railColor);
	draw_roundrect(34, 144, room_width - 34, 618, true);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(textColor);
	draw_text(58, 164, _title);
	draw_set_color(mutedTextColor);
	draw_text(58, 198, _message);
}

function drawLocalGameLobby() {
	draw_set_color(panelColor);
	draw_roundrect(210, 178, room_width - 210, 594, false);
	draw_set_color(railColor);
	draw_roundrect(210, 178, room_width - 210, 594, true);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(textColor);
	draw_text(room_width * 0.5, 250, gameNames[selectedGame] + " Lobby");
	draw_set_color(mutedTextColor);
	draw_text(room_width * 0.5, 304, "> LOCAL TABLE LOBBY // SGC.WTF");
	draw_text(room_width * 0.5, 346, "Balance: " + string(balance) + " chips  |  Bet: " + string(currentBet()) + " chips");
	if (selectedGame == GAME_SLOTS || selectedGame == GAME_PACHINKO) {
		draw_text(room_width * 0.5, 386, "Up to 3 players share this lobby; every board stays visible while play resolves.");
		for (var seatIndex = 0; seatIndex < 3; seatIndex += 1) {
			var seatLeft = room_width * 0.5 - 306 + seatIndex * 204;
			var seatTop = 426;
			var seatName = "Open Seat";
			if (selectedGame == GAME_SLOTS) seatName = slotSeats[seatIndex].name;
			if (selectedGame == GAME_PACHINKO) seatName = pachinkoSeats[seatIndex].name;
			draw_set_color(seatIndex == 0 ? make_color_rgb(35, 22, 44) : make_color_rgb(17, 22, 32));
			draw_roundrect(seatLeft, seatTop, seatLeft + 184, seatTop + 48, false);
			draw_set_color(seatIndex == 0 ? accentHoverColor : railColor);
			draw_roundrect(seatLeft, seatTop, seatLeft + 184, seatTop + 48, true);
			draw_set_halign(fa_center);
			draw_set_valign(fa_middle);
			draw_set_color(textColor);
			draw_text(seatLeft + 92, seatTop + 24, seatName);
		}
	} else {
		draw_text(room_width * 0.5, 394, "Enter when you are ready to sit at this table.");
	}
	var joinTableButton = { x: room_width * 0.5 - 135, y: 508, w: 270, h: 60, label: "Join Table" };
	drawTableButton(joinTableButton, true, hoveredControl == "join_table");
}

function drawSlotsGame() {
	drawGameShell("SadGirl Slots // 3-seat lobby", slotMessage);
	for (var seatIndex = 0; seatIndex < array_length(slotSeats); seatIndex += 1) {
		var seat = slotSeats[seatIndex];
		var panelLeft = 70 + seatIndex * 410;
		var panelTop = 244;
		var panelW = 360;
		var panelH = 276;
		draw_set_color(seat.isHuman ? make_color_rgb(35, 22, 44) : make_color_rgb(17, 22, 32));
		draw_roundrect(panelLeft, panelTop, panelLeft + panelW, panelTop + panelH, false);
		draw_set_color(seat.spinTimer > 0 ? accentHoverColor : railColor);
		draw_roundrect(panelLeft, panelTop, panelLeft + panelW, panelTop + panelH, true);
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
		draw_set_color(textColor);
		draw_text(panelLeft + 18, panelTop + 14, (seat.isHuman ? "> " : "// ") + seat.name);
		draw_set_color(mutedTextColor);
		draw_text(panelLeft + 18, panelTop + 38, "bet " + string(seat.bet) + " | bal " + string(seat.balance));
		var cell = 62;
		var startLeft = panelLeft + 26;
		var startTop = panelTop + 74;
		for (var rowIndex = 0; rowIndex < 3; rowIndex += 1) {
			for (var colIndex = 0; colIndex < 3; colIndex += 1) {
				var idx = rowIndex * 3 + colIndex;
				var symbol = seat.grid[idx];
				var cellLeft = startLeft + colIndex * (cell + 13);
				var cellTop = startTop + rowIndex * (cell + 10);
				draw_set_color(make_color_rgb(9, 10, 18));
				draw_roundrect(cellLeft, cellTop, cellLeft + cell, cellTop + cell, false);
				draw_set_color(slotColors[symbol]);
				draw_circle(cellLeft + cell * 0.5, cellTop + 22, 14, false);
				draw_set_color(railColor);
				draw_roundrect(cellLeft, cellTop, cellLeft + cell, cellTop + cell, true);
				draw_set_halign(fa_center);
				draw_set_valign(fa_middle);
				draw_set_color(textColor);
				draw_text(cellLeft + cell * 0.5, cellTop + 46, string_copy(slotNames[symbol], 1, 5));
			}
		}
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
		draw_set_color(seat.spinTimer > 0 ? accentHoverColor : mutedTextColor);
		draw_text(panelLeft + 18, panelTop + panelH - 34, seat.status);
	}
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(mutedTextColor);
	draw_text(74, 542, "Every occupied seat has an independent reel state; remote seats keep animating while you play.");
	draw_text(74, 566, "Rows and diagonals pay. Bell completes a pair as wild.");
}

function drawPachinkoGame() {
	drawGameShell("Pachinko Drop // 3-seat lobby", pachinkoMessage);
	for (var seatIndex = 0; seatIndex < array_length(pachinkoSeats); seatIndex += 1) {
		var seat = pachinkoSeats[seatIndex];
		var panelLeft = 70 + seatIndex * 410;
		var panelTop = 238;
		var panelW = 360;
		var panelH = 306;
		draw_set_color(seat.isHuman ? make_color_rgb(35, 22, 44) : make_color_rgb(17, 22, 32));
		draw_roundrect(panelLeft, panelTop, panelLeft + panelW, panelTop + panelH, false);
		draw_set_color(seat.running ? accentHoverColor : railColor);
		draw_roundrect(panelLeft, panelTop, panelLeft + panelW, panelTop + panelH, true);
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
		draw_set_color(textColor);
		draw_text(panelLeft + 18, panelTop + 14, (seat.isHuman ? "> " : "// ") + seat.name);
		draw_set_color(mutedTextColor);
		draw_text(panelLeft + 18, panelTop + 38, "peg " + string(seat.guess) + " | bet " + string(seat.bet) + " | bal " + string(seat.balance));
		var boardLeft = panelLeft + 36;
		var boardTop = panelTop + 80;
		var gapX = 26;
		var gapY = 20;
		for (var rowIndex = 0; rowIndex < pachinkoRows; rowIndex += 1) {
			for (var colIndex = 0; colIndex < pachinkoWidth; colIndex += 1) {
				var pegLeft = boardLeft + colIndex * gapX + ((rowIndex mod 2) * gapX * 0.5);
				var pegTop = boardTop + rowIndex * gapY;
				draw_set_color(make_color_rgb(93, 228, 207));
				draw_circle(pegLeft, pegTop, 3, false);
			}
		}
		if (array_length(seat.path) > 0) {
			for (var visibleRow = 0; visibleRow < seat.visibleRows; visibleRow += 1) {
				var pathPos = seat.path[visibleRow];
				var ballLeft = boardLeft + pathPos * gapX + ((visibleRow mod 2) * gapX * 0.5);
				var ballTop = boardTop + visibleRow * gapY;
				draw_set_color(accentHoverColor);
				draw_circle(ballLeft, ballTop, 8, false);
				draw_set_color(c_white);
				draw_circle(ballLeft - 3, ballTop - 3, 2, false);
			}
		}
		for (var footer = 0; footer < pachinkoWidth; footer += 1) {
			var labelLeft = boardLeft + footer * gapX;
			var labelTop = boardTop + pachinkoRows * gapY + 24;
			draw_set_color((footer + 1 == seat.guess) ? accentColor : make_color_rgb(25, 27, 42));
			draw_circle(labelLeft, labelTop, 10, false);
			draw_set_color(railColor);
			draw_circle(labelLeft, labelTop, 10, true);
			draw_set_halign(fa_center);
			draw_set_valign(fa_middle);
			draw_set_color(textColor);
			draw_text(labelLeft, labelTop, string((footer + 1) mod 10));
		}
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
		draw_set_color(seat.running ? accentHoverColor : mutedTextColor);
		draw_text(panelLeft + 18, panelTop + panelH - 34, seat.status);
	}
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(mutedTextColor);
	draw_text(74, 566, "Exact pays 2x, one off pays 1.5x, two off returns the bet. All seats animate independently.");
}

function drawBlackjackGame() {
	drawGameShell("Blackjack", bjMessage);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(mutedTextColor);
	draw_text(90, 244, "Dealer " + ((bjPhase == "playing") ? "(?)" : "(" + string(blackjackHandValue(bjDealerHand)) + ")"));
	drawCardRow(90, 276, bjDealerHand, (bjPhase == "playing") ? 1 : -1);
	draw_text(90, 416, "Player (" + string(blackjackHandValue(bjPlayerHand)) + ")");
	drawCardRow(90, 448, bjPlayerHand, -1);
	draw_set_color(make_color_rgb(25, 48, 44));
	draw_roundrect(760, 270, 1128, 484, false);
	draw_set_color(railColor);
	draw_roundrect(760, 270, 1128, 484, true);
	draw_set_color(textColor);
	draw_text(790, 302, "Controls");
	draw_set_color(mutedTextColor);
	draw_text(790, 344, "Deal starts a new hand.");
	draw_text(790, 374, "Hit draws a card.");
	draw_text(790, 404, "Stay lets the dealer play.");
}

function drawHoldemGame() {
	drawGameShell("Texas Hold'em", holdemMessage);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(mutedTextColor);
	draw_text(90, 234, "CPU");
	drawCardRow(90, 266, holdemCpu, holdemRevealCpu ? -1 : 0);
	draw_text(90, 392, "You");
	drawCardRow(90, 424, holdemPlayer, -1);
	draw_text(496, 294, "Community");
	for (var i = 0; i < 5; i += 1) {
		if (i < array_length(holdemCommunity)) {
			drawPlayingCard(496 + i * 76, 326, holdemCommunity[i], false);
		} else {
			draw_set_color(make_color_rgb(28, 42, 43));
			draw_roundrect(496 + i * 76, 326, 496 + i * 76 + 66, 418, false);
			draw_set_color(make_color_rgb(82, 101, 91));
			draw_roundrect(496 + i * 76, 326, 496 + i * 76 + 66, 418, true);
		}
	}
	draw_set_color(make_color_rgb(25, 48, 44));
	draw_roundrect(930, 276, 1172, 448, false);
	draw_set_color(railColor);
	draw_roundrect(930, 276, 1172, 448, true);
	draw_set_color(textColor);
	draw_text(960, 306, "Pot: " + string(holdemPot));
	draw_set_color(mutedTextColor);
	draw_text(960, 344, "Phase: " + holdemPhase);
	draw_text(960, 374, holdemRaised ? "Raise used" : "Raise available");
}

function drawHorseGame() {
	drawGameShell("Horse Racing", horseMessage);
	var trackX = 120;
	var trackY = 252;
	var trackW = 840;
	var rowH = 66;
	var underdog = horseUnderdog();
	for (var horse = 0; horse < 4; horse += 1) {
		var laneY = trackY + horse * rowH;
		draw_set_color(make_color_rgb(22, 44, 38));
		draw_rectangle(trackX, laneY, trackX + trackW, laneY + 42, false);
		draw_set_color(railColor);
		draw_rectangle(trackX, laneY, trackX + trackW, laneY + 42, true);
		var runnerX = trackX + (trackW - 44) * clamp(horsePositions[horse] / horseFinish, 0, 1);
		draw_set_color(horseColors[horse]);
		draw_roundrect(runnerX, laneY + 6, runnerX + 44, laneY + 36, false);
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_set_color(textColor);
		draw_text(runnerX + 22, laneY + 21, horseNames[horse]);
		draw_set_halign(fa_left);
		draw_set_valign(fa_middle);
		draw_set_color((horse == horseChoice) ? textColor : mutedTextColor);
		draw_text(70, laneY + 22, horseNames[horse]);
		if (horse == underdog) {
			draw_set_color(make_color_rgb(235, 199, 85));
			draw_text(trackX + trackW + 26, laneY + 22, "underdog");
		}
	}
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(mutedTextColor);
	draw_text(1012, 278, "Wins");
	for (var w = 0; w < 4; w += 1) {
		draw_set_color(horseColors[w]);
		draw_text(1012, 316 + w * 30, "Horse " + horseNames[w] + ": " + string(horseWins[w]));
	}
}

draw_clear_alpha(backgroundTop, 1);
for (var stripe = 0; stripe < room_height; stripe += 6) {
	var blend = stripe / room_height;
	draw_set_color(merge_color(backgroundTop, backgroundBottom, blend));
	draw_rectangle(0, stripe, room_width, stripe + 6, false);
}

draw_set_color(blackFeltColor);
draw_rectangle(0, 0, room_width, 68, false);
draw_set_color(railColor);
draw_line(0, 68, room_width, 68);

draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_color(textColor);
var headerTitle = tableRoomLocked ? gameNames[selectedGame] + " // TABLE NODE" : "DollOS Casino Tables";
draw_text(24, 34, headerTitle);
draw_set_color(mutedTextColor);
draw_text(318, 34, "[SGC] balance: " + string(balance) + " chips");

var backButton = { x: room_width - 158, y: 20, w: 128, h: 42, label: tableRoomLocked ? "Lobby" : "Menu" };
drawTableButton(backButton, false, hoveredControl == "back");

if (!tableRoomLocked) {
	for (var tab = 0; tab < array_length(gameNames); tab += 1) {
		var tabButton = { x: 24 + tab * 158, y: 78, w: 148, h: 48, label: gameNames[tab] };
		drawTableButton(tabButton, selectedGame == tab, hoveredControl == "tab_" + string(tab));
	}
}

if (tableLobbyOpen) {
	drawLocalGameLobby();
	draw_set_halign(fa_left);
	draw_set_valign(fa_middle);
	draw_set_color(railColor);
	draw_text(24, room_height - 26, statusText);
	draw_set_halign(fa_right);
	draw_set_color(mutedTextColor);
	draw_text(room_width - 24, room_height - 26, "Esc: table lobby  |  Enter: join table");
	exit;
}

if (selectedGame == GAME_SLOTS) drawSlotsGame();
if (selectedGame == GAME_PACHINKO) drawPachinkoGame();
if (selectedGame == GAME_BLACKJACK) drawBlackjackGame();
if (selectedGame == GAME_HOLDEM) drawHoldemGame();
if (selectedGame == GAME_HORSE) drawHorseGame();

var actionButtons = [];
if (selectedGame == GAME_SLOTS) actionButtons = [{ x: 90, y: 636, w: 190, h: 56, label: "Spin" }];
if (selectedGame == GAME_PACHINKO) actionButtons = [{ x: 88, y: 636, w: 190, h: 56, label: "Drop" }, { x: 318, y: 636, w: 52, h: 56, label: "-" }, { x: 486, y: 636, w: 52, h: 56, label: "+" }];
if (selectedGame == GAME_BLACKJACK) actionButtons = [{ x: 82, y: 636, w: 142, h: 56, label: "Deal" }, { x: 242, y: 636, w: 142, h: 56, label: "Hit" }, { x: 402, y: 636, w: 142, h: 56, label: "Stay" }];
if (selectedGame == GAME_HOLDEM) actionButtons = [{ x: 82, y: 636, w: 130, h: 56, label: "Deal" }, { x: 228, y: 636, w: 130, h: 56, label: "Check" }, { x: 374, y: 636, w: 130, h: 56, label: "Raise" }, { x: 520, y: 636, w: 130, h: 56, label: "Fold" }];
if (selectedGame == GAME_HORSE) {
	actionButtons = [{ x: 84, y: 636, w: 190, h: 56, label: "Start Race" }];
	for (var hb = 0; hb < 4; hb += 1) {
		array_push(actionButtons, { x: 340 + hb * 88, y: 636, w: 68, h: 56, label: horseNames[hb] });
	}
}

for (var buttonIndex = 0; buttonIndex < array_length(actionButtons); buttonIndex += 1) {
	var button = actionButtons[buttonIndex];
	var hover = point_in_rectangle(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), button.x, button.y, button.x + button.w, button.y + button.h);
	var selected = false;
	if (selectedGame == GAME_HORSE && buttonIndex > 0) selected = horseChoice == buttonIndex - 1;
	drawTableButton(button, selected, hover);
}

draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_color(mutedTextColor);
draw_text(704, 676, "Bet");
for (var betIndex = 0; betIndex < array_length(betOptions); betIndex += 1) {
	drawChip(836 + betIndex * 82, 677, betOptions[betIndex], selectedBetIndex == betIndex);
}

draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_color(railColor);
draw_text(24, room_height - 26, statusText);
draw_set_halign(fa_right);
draw_set_color(mutedTextColor);
draw_text(room_width - 24, room_height - 26, tableRoomLocked ? "Esc: lobby  |  Space/Enter: common actions" : "Esc: menu  |  1-5: tables  |  Space/Enter: common actions");