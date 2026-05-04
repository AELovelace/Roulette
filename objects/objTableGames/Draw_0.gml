// Shared table-games renderer.
// Micro-adjust here: button/chip/card visual hierarchy and per-game panel density.
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

function drawVolumeSlider(_hovered) {
	var slider = { x: VIEW_W - 236, y: VIEW_H - 56, w: 170, h: 14 };
	var value = rouletteGetSfxVolume();
	var knobX = slider.x + slider.w * value;

	draw_set_halign(fa_left);
	draw_set_valign(fa_middle);
	draw_set_color(mutedTextColor);
	draw_text(slider.x - 58, slider.y + 7, "VOL");

	draw_set_color(make_color_rgb(23, 26, 35));
	draw_roundrect(slider.x, slider.y, slider.x + slider.w, slider.y + slider.h, false);
	draw_set_color(_hovered ? accentHoverColor : railColor);
	draw_roundrect(slider.x, slider.y, slider.x + slider.w, slider.y + slider.h, true);

	draw_set_color(_hovered ? accentHoverColor : accentColor);
	draw_circle(knobX, slider.y + slider.h * 0.5, 8, false);
	draw_set_color(textColor);
	draw_circle(knobX, slider.y + slider.h * 0.5, 8, true);
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

function drawMaybeCard(_x, _y, _card) {
	drawPlayingCard(_x, _y, _card, !is_struct(_card));
}

function drawCardRow(_x, _y, _cards, _hiddenFromIndex) {
	for (var i = 0; i < array_length(_cards); i += 1) {
		drawPlayingCard(_x + i * 76, _y, _cards[i], i >= _hiddenFromIndex && _hiddenFromIndex >= 0);
	}
}

function drawMaybeCardRow(_x, _y, _cards) {
	for (var i = 0; i < array_length(_cards); i += 1) {
		drawMaybeCard(_x + i * 72, _y, _cards[i]);
	}
}

function drawCardParticipants(_x, _y, _columns) {
	for (var participantIndex = 0; participantIndex < tableMaxPlayers; participantIndex += 1) {
		var column = participantIndex mod _columns;
		var row = participantIndex div _columns;
		var panelLeft = _x + column * 290;
		var panelTop = _y + row * 124;
		var participant = participantIndex < array_length(tableParticipants) ? tableParticipants[participantIndex] : undefined;
		var occupied = is_struct(participant);
		draw_set_color(occupied ? (rouletteStructGet(participant, "isTurn", false) ? make_color_rgb(46, 33, 58) : make_color_rgb(17, 22, 32)) : make_color_rgb(10, 12, 20));
		draw_roundrect(panelLeft, panelTop, panelLeft + 268, panelTop + 104, false);
		draw_set_color(occupied && rouletteStructGet(participant, "playerId", "") == tablePlayerId ? accentHoverColor : railColor);
		draw_roundrect(panelLeft, panelTop, panelLeft + 268, panelTop + 104, true);
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
		if (!occupied) {
			draw_set_color(mutedTextColor);
			draw_text(panelLeft + 16, panelTop + 18, "OPEN SEAT");
			continue;
		}
		var prefix = rouletteStructGet(participant, "isTurn", false) ? "> " : "// ";
		draw_set_color(textColor);
		draw_text(panelLeft + 14, panelTop + 12, prefix + rouletteStructGet(participant, "name", "Player"));
		draw_set_color(mutedTextColor);
		var totalText = rouletteStructGet(participant, "total", 0) > 0 ? (" | total " + string(rouletteStructGet(participant, "total", 0))) : "";
		draw_text(panelLeft + 14, panelTop + 34, "bet " + string(rouletteStructGet(participant, "bet", 0)) + " | bal " + string(rouletteStructGet(participant, "balance", 0)) + totalText);
		draw_text(panelLeft + 14, panelTop + 56, rouletteStructGet(participant, "status", "Ready"));
		var hand = rouletteStructGet(participant, "hand", []);
		for (var cardIndex = 0; cardIndex < min(3, array_length(hand)); cardIndex += 1) {
			drawMaybeCard(panelLeft + 150 + cardIndex * 38, panelTop + 10, hand[cardIndex]);
		}
	}
}

function drawBlackjackParticipants(_x, _y) {
	var seatCount = min(6, tableMaxPlayers);
	var columns = 2;
	var panelW = 438;
	var panelH = 114;
	var gapX = 24;
	var gapY = 16;
	for (var participantIndex = 0; participantIndex < seatCount; participantIndex += 1) {
		var column = participantIndex mod columns;
		var row = participantIndex div columns;
		var panelLeft = _x + column * (panelW + gapX);
		var panelTop = _y + row * (panelH + gapY);
		var participant = participantIndex < array_length(tableParticipants) ? tableParticipants[participantIndex] : undefined;
		var occupied = is_struct(participant);
		draw_set_color(occupied ? (rouletteStructGet(participant, "isTurn", false) ? make_color_rgb(46, 33, 58) : make_color_rgb(17, 22, 32)) : make_color_rgb(10, 12, 20));
		draw_roundrect(panelLeft, panelTop, panelLeft + panelW, panelTop + panelH, false);
		draw_set_color(occupied && rouletteStructGet(participant, "playerId", "") == tablePlayerId ? accentHoverColor : railColor);
		draw_roundrect(panelLeft, panelTop, panelLeft + panelW, panelTop + panelH, true);
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
		if (!occupied) {
			draw_set_color(mutedTextColor);
			draw_text(panelLeft + 16, panelTop + 18, "OPEN SEAT");
			continue;
		}
		var prefix = rouletteStructGet(participant, "isTurn", false) ? "> " : "// ";
		draw_set_color(textColor);
		draw_text(panelLeft + 14, panelTop + 10, prefix + rouletteStructGet(participant, "name", "Player"));
		draw_set_color(mutedTextColor);
		var totalText = rouletteStructGet(participant, "total", 0) > 0 ? (" | total " + string(rouletteStructGet(participant, "total", 0))) : "";
		draw_text(panelLeft + 14, panelTop + 30, "bet " + string(rouletteStructGet(participant, "bet", 0)) + " | bal " + string(rouletteStructGet(participant, "balance", 0)) + totalText);
		draw_text(panelLeft + 14, panelTop + 50, rouletteStructGet(participant, "status", "Ready"));
		var hand = rouletteStructGet(participant, "hand", []);
		var drawCount = min(5, array_length(hand));
		for (var cardIndex = 0; cardIndex < drawCount; cardIndex += 1) {
			drawMaybeCard(panelLeft + 146 + cardIndex * 56, panelTop + 10, hand[cardIndex]);
		}
	}
}

function drawGameShell(_title, _message) {
	draw_set_color(panelColor);
	draw_roundrect(34, 144, VIEW_W - 34, 618, false);
	draw_set_color(railColor);
	draw_roundrect(34, 144, VIEW_W - 34, 618, true);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(textColor);
	draw_text(58, 164, _title);
	draw_set_color(mutedTextColor);
	draw_text(58, 198, _message);
}

function drawLocalGameLobby() {
	draw_set_color(panelColor);
	draw_roundrect(210, 178, VIEW_W - 210, 594, false);
	draw_set_color(railColor);
	draw_roundrect(210, 178, VIEW_W - 210, 594, true);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(textColor);
	draw_text(VIEW_W * 0.5, 250, gameNames[selectedGame] + " Lobby");
	draw_set_color(mutedTextColor);
	draw_text(VIEW_W * 0.5, 304, "> TABLE LOBBY // SGC.WTF");
	draw_text(VIEW_W * 0.5, 346, "Balance: " + string(balance) + " chips  |  Bet: " + string(currentBet()) + " chips");
	if (tableMultiplayerEnabled) {
		draw_text(VIEW_W * 0.5, 386, "Broker: " + tableBrokerStatus + "  |  Lobby: " + tableCurrentLobbyName);
		var listLeft = VIEW_W * 0.5 - 300;
		var listTop = 338;
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
		if (tableCurrentLobbyId == "") {
			draw_set_color(mutedTextColor);
			draw_text(listLeft, listTop - 26, "> AVAILABLE LOBBIES");
			for (var lobbyIndex = 0; lobbyIndex < min(4, array_length(tableLobbyList)); lobbyIndex += 1) {
				var lobbyEntry = tableLobbyList[lobbyIndex];
				var rowTop = listTop + lobbyIndex * 34;
				var lobbyId = rouletteStructGet(lobbyEntry, "id", "");
				var rowSelected = lobbyId == tableSelectedLobbyId;
				draw_set_color(rowSelected ? make_color_rgb(46, 33, 58) : make_color_rgb(12, 14, 24));
				draw_rectangle(listLeft, rowTop, listLeft + 600, rowTop + 28, false);
				draw_set_color(rowSelected ? accentHoverColor : railColor);
				draw_rectangle(listLeft, rowTop, listLeft + 600, rowTop + 28, true);
				draw_set_color(textColor);
				draw_text(listLeft + 12, rowTop + 7, rouletteStructGet(lobbyEntry, "name", "Lobby"));
				draw_set_color(mutedTextColor);
				draw_text(listLeft + 390, rowTop + 7, "Seats " + string(rouletteStructGet(lobbyEntry, "playerCount", 0)) + "/" + string(rouletteStructGet(lobbyEntry, "maxPlayers", tableMaxPlayers)));
			}
			if (array_length(tableLobbyList) == 0) {
				draw_set_color(mutedTextColor);
				draw_text(listLeft, listTop + 8, "No lobbies yet. Create one to open seats.");
			}
		} else {
			draw_set_halign(fa_center);
			draw_set_color(mutedTextColor);
			draw_text(VIEW_W * 0.5, 416, "You are seated. Enter the table to play; leave only while your game is idle.");
		}
		var createTableLobbyButton = { x: VIEW_W * 0.5 - 276, y: 508, w: 170, h: 52, label: "Create Lobby" };
		var joinTableLobbyButton = { x: VIEW_W * 0.5 - 86, y: 508, w: 170, h: 52, label: "Join Lobby" };
		var leaveTableLobbyButton = { x: VIEW_W * 0.5 + 104, y: 508, w: 170, h: 52, label: "Leave Lobby" };
		drawTableButton(createTableLobbyButton, false, hoveredControl == "create_table_lobby");
		drawTableButton(joinTableLobbyButton, false, hoveredControl == "join_table_lobby");
		drawTableButton(leaveTableLobbyButton, false, hoveredControl == "leave_table_lobby");
		if (tableCurrentLobbyId != "") {
			var joinTableButton = { x: VIEW_W * 0.5 - 135, y: 570, w: 270, h: 48, label: "Enter Table" };
			drawTableButton(joinTableButton, true, hoveredControl == "join_table");
		}
	} else if (selectedGame == GAME_SLOTS || selectedGame == GAME_PACHINKO) {
		draw_text(VIEW_W * 0.5, 386, "Up to 3 players.");
		for (var seatIndex = 0; seatIndex < 3; seatIndex += 1) {
			var seatLeft = VIEW_W * 0.5 - 306 + seatIndex * 204;
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
		draw_text(VIEW_W * 0.5, 394, "Enter when you are ready to Play.");
	}
	if (!tableMultiplayerEnabled) {
		var joinTableButton = { x: VIEW_W * 0.5 - 135, y: 508, w: 270, h: 60, label: "Join Table" };
		drawTableButton(joinTableButton, true, hoveredControl == "join_table");
	}
}

function drawSlotsGame() {
	drawGameShell("SadGirl Slots // 3-seat lobby", slotMessage);
	for (var seatIndex = 0; seatIndex < array_length(slotSeats); seatIndex += 1) {
		var seat = slotSeats[seatIndex];
		var panelLeft = 70 + seatIndex * 410;
		var panelTop = 244;
		var panelW = 360;
		var panelH = 276;
		if (!seat.active) {
			draw_set_color(make_color_rgb(10, 12, 20));
			draw_roundrect(panelLeft, panelTop, panelLeft + panelW, panelTop + panelH, false);
			draw_set_color(make_color_rgb(55, 66, 79));
			draw_roundrect(panelLeft, panelTop, panelLeft + panelW, panelTop + panelH, true);
			draw_set_halign(fa_center);
			draw_set_valign(fa_middle);
			draw_set_color(mutedTextColor);
			draw_text(panelLeft + panelW * 0.5, panelTop + panelH * 0.5, "OPEN SEAT");
			continue;
		}
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
	draw_text(74, 542, "Real-Time Multiplayer Slots");
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
		if (!seat.active) {
			draw_set_color(make_color_rgb(10, 12, 20));
			draw_roundrect(panelLeft, panelTop, panelLeft + panelW, panelTop + panelH, false);
			draw_set_color(make_color_rgb(55, 66, 79));
			draw_roundrect(panelLeft, panelTop, panelLeft + panelW, panelTop + panelH, true);
			draw_set_halign(fa_center);
			draw_set_valign(fa_middle);
			draw_set_color(mutedTextColor);
			draw_text(panelLeft + panelW * 0.5, panelTop + panelH * 0.5, "OPEN SEAT");
			continue;
		}
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
				var pegLeft = boardLeft + colIndex * gapX;
				var pegTop = boardTop + rowIndex * gapY;
				draw_set_color(make_color_rgb(93, 228, 207));
				draw_circle(pegLeft, pegTop, 3, false);
			}
		}
		if (array_length(seat.path) > 0) {
			var stepFrames = 10;
			draw_set_alpha(0.95);
			draw_set_color(make_color_rgb(128, 255, 0));
			for (var lineRow = 1; lineRow < seat.visibleRows; lineRow += 1) {
				var prevPos = seat.path[lineRow - 1];
				var nextPos = seat.path[lineRow];
				var lineX1 = boardLeft + prevPos * gapX;
				var lineY1 = boardTop + (lineRow - 1) * gapY;
				var lineX2 = boardLeft + nextPos * gapX;
				var lineY2 = boardTop + lineRow * gapY;
				draw_line_width(lineX1, lineY1, lineX2, lineY2, 2);
			}

			var currentRow = clamp(seat.visibleRows - 1, 0, array_length(seat.path) - 1);
			var currentPos = seat.path[currentRow];
			var currentX = boardLeft + currentPos * gapX;
			var currentY = boardTop + currentRow * gapY;
			var ballRadius = 8;
			if (seat.running && currentRow < array_length(seat.path) - 1) {
				var nextPosStep = seat.path[currentRow + 1];
				var nextX = boardLeft + nextPosStep * gapX;
				var nextY = boardTop + (currentRow + 1) * gapY;
				var t = clamp(seat.timer / stepFrames, 0, 1);
				currentX = lerp(currentX, nextX, t);
				currentY = lerp(currentY, nextY, t) - (sin(t * pi) * 6);
				draw_set_color(make_color_rgb(128, 255, 0));
				draw_line_width(boardLeft + currentPos * gapX, boardTop + currentRow * gapY, currentX, currentY, 2);
				if (t < 0.12 || t > 0.88) {
					ballRadius = 7;
				}
			}
			draw_set_alpha(1);

			draw_set_color(accentHoverColor);
			draw_circle(currentX, currentY, ballRadius, false);
			draw_set_color(c_white);
			draw_circle(currentX - 3, currentY - 3, 2, false);
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
	if (tableMultiplayerEnabled && tableCurrentLobbyId != "") {
		drawGameShell("Blackjack // 6-seat lobby", tableLastEvent);
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
		draw_set_color(mutedTextColor);
		draw_text(70, 224, "Phase: " + tablePhase + " | Turn: " + (tableYouAreTurn ? "YOU" : tableTurnPlayerId));
		draw_text(70, 252, "Dealer");
		drawMaybeCardRow(70, 282, tableDealerHand);
		drawBlackjackParticipants(350, 226);
		return;
	}
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
	if (tableMultiplayerEnabled && tableCurrentLobbyId != "") {
		drawGameShell("Texas Hold'em // 8-seat lobby", tableLastEvent);
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
		draw_set_color(mutedTextColor);
		draw_text(70, 224, "Phase: " + tablePhase + " | Pot: " + string(tablePot) + " | Turn: " + (tableYouAreTurn ? "YOU" : tableTurnPlayerId));
		draw_text(70, 252, "Community");
		drawMaybeCardRow(70, 282, tableCommunity);
		drawCardParticipants(70, 400, 4);
		return;
	}
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
	if (tableMultiplayerEnabled && tableCurrentLobbyId != "") {
		drawGameShell("Horse Racing // 20-seat lobby", tableLastEvent);
		var trackX = 86;
		var trackY = 248;
		var trackW = 740;
		var rowH = 66;
		for (var horse = 0; horse < 4; horse += 1) {
			var laneY = trackY + horse * rowH;
			draw_set_color(make_color_rgb(22, 44, 38));
			draw_rectangle(trackX, laneY, trackX + trackW, laneY + 42, false);
			draw_set_color(railColor);
			draw_rectangle(trackX, laneY, trackX + trackW, laneY + 42, true);
			var progress = (is_array(tableHorsePositions) && horse < array_length(tableHorsePositions)) ? real(tableHorsePositions[horse]) : 0;
			var runnerX = trackX + (trackW - 44) * clamp(progress / horseFinish, 0, 1);
			draw_set_color(horseColors[horse]);
			draw_roundrect(runnerX, laneY + 6, runnerX + 44, laneY + 36, false);
			draw_set_halign(fa_center);
			draw_set_valign(fa_middle);
			draw_set_color(textColor);
			draw_text(runnerX + 22, laneY + 21, horseNames[horse]);
			draw_set_halign(fa_left);
			draw_set_color((horse == horseChoice) ? textColor : mutedTextColor);
			draw_text(52, laneY + 22, horseNames[horse]);
			if (horse == tableHorseUnderdog) {
				draw_set_color(make_color_rgb(235, 199, 85));
				draw_text(trackX + trackW + 16, laneY + 22, "underdog");
			}
		}
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
		draw_set_color(mutedTextColor);
		draw_text(858, 248, "Host: " + (tableHostPlayerId == tablePlayerId ? "YOU" : tableHostPlayerId));
		draw_text(858, 272, "Race: " + tableHorseState + " | Winner: " + (tableHorseWinner >= 0 ? horseNames[tableHorseWinner] : "-"));
		draw_text(858, 300, "Participants");
		for (var p = 0; p < min(20, array_length(tableParticipants)); p += 1) {
			var participant = tableParticipants[p];
			var label = rouletteStructGet(participant, "name", "Player");
			if (rouletteStructGet(participant, "isHost", false)) label = label + " [HOST]";
			var pick = rouletteStructGet(participant, "horseChoice", 0);
			draw_set_color(rouletteStructGet(participant, "playerId", "") == tablePlayerId ? textColor : mutedTextColor);
			draw_text(858, 326 + p * 16, label + " -> " + horseNames[clamp(pick, 0, 3)]);
		}
		draw_set_color(mutedTextColor);
		draw_text(858, 640, tableIsHost ? "You are host: Start Race enabled." : "Only host can start race.");
		return;
	}
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
for (var stripe = 0; stripe < VIEW_H; stripe += 6) {
	var blend = stripe / VIEW_H;
	draw_set_color(merge_color(backgroundTop, backgroundBottom, blend));
	draw_rectangle(0, stripe, VIEW_W, stripe + 6, false);
}

draw_set_color(blackFeltColor);
draw_rectangle(0, 0, VIEW_W, 68, false);
draw_set_color(railColor);
draw_line(0, 68, VIEW_W, 68);

draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_color(textColor);
var headerTitle = tableRoomLocked ? gameNames[selectedGame] + " // TABLE NODE" : "DollOS Casino Tables";
draw_text(24, 34, headerTitle);
draw_set_color(mutedTextColor);
draw_text(318, 34, "[SGC] balance: " + string(balance) + " chips");

var backButton = { x: VIEW_W - 326, y: 20, w: 128, h: 42, label: tableRoomLocked ? "Tables" : "Back" };
var mainMenuButton = { x: VIEW_W - 178, y: 20, w: 148, h: 42, label: "Main Menu" };
drawTableButton(backButton, false, hoveredControl == "back");
drawTableButton(mainMenuButton, false, hoveredControl == "main_menu");

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
	draw_text(24, VIEW_H - 26, statusText);
	draw_set_halign(fa_right);
	draw_set_color(mutedTextColor);
	draw_text(VIEW_W - 24, VIEW_H - 26, "Esc: table lobby  |  Enter: join table");
	drawVolumeSlider(hoveredControl == "volume_slider" || tableVolumeSliderDragging);
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
	var raceLabel = "Start Race";
	if (tableMultiplayerEnabled && tableCurrentLobbyId != "" && !tableIsHost) raceLabel = "Host Starts";
	actionButtons = [{ x: 84, y: 636, w: 190, h: 56, label: raceLabel }];
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
draw_text(24, VIEW_H - 26, statusText);
draw_set_halign(fa_right);
draw_set_color(mutedTextColor);
draw_text(VIEW_W - 24, VIEW_H - 26, tableRoomLocked ? "Esc: lobby  |  Space/Enter: common actions" : "Esc: menu  |  1-5: tables  |  Space/Enter: common actions");
drawVolumeSlider(hoveredControl == "volume_slider" || tableVolumeSliderDragging);
