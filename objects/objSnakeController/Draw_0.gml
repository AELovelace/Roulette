draw_clear(make_color_rgb(10, 12, 18));

draw_set_colour(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_text(8, 8, "[SGC] Balance: " + string(global.sgcArcadeBalance));
draw_text(8, 28, "Broker: " + snakeBrokerStatus);
draw_set_halign(fa_right);
draw_text(room_width - 8, 8, "Snake Hi Score: " + string(global.snakeHighScore));
draw_text(room_width - 8, 28, "Buy-in: " + string(entryCost));

draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
draw_set_colour(make_color_rgb(220, 230, 230));
draw_text(room_width * 0.5, room_height - 8, statusText);

function drawSnakeBoardCell(_x, _y, _cell, _size) {
	switch (_cell) {
		case 0: draw_set_color(make_color_rgb(28, 30, 38)); break;
		case 1: draw_set_color(make_color_rgb(96, 220, 128)); break;
		case 2: draw_set_color(c_red); break;
		case 3: draw_set_color(c_yellow); break;
		case 4: draw_set_color(c_aqua); break;
	}
	draw_rectangle(_x, _y, _x + _size - 2, _y + _size - 2, false);
}

function drawSnakeTelemetryField(_px, _py, _pw, _ph, _name, _telemetry, _localFocus) {
	draw_set_colour(make_color_rgb(14, 18, 28));
	draw_roundrect(_px, _py, _px + _pw, _py + _ph, false);
	draw_set_colour(_localFocus ? make_color_rgb(110, 188, 236) : make_color_rgb(86, 130, 176));
	draw_roundrect(_px, _py, _px + _pw, _py + _ph, true);

	var headXNorm = clamp(rouletteStructGet(_telemetry, "headXNorm", 0.5), 0, 1);
	var headYNorm = clamp(rouletteStructGet(_telemetry, "headYNorm", 0.5), 0, 1);
	var len = max(3, floor(rouletteStructGet(_telemetry, "length", 3)));
	var scoreValue = max(0, floor(rouletteStructGet(_telemetry, "score", 0)));
	var alive = rouletteStructGet(_telemetry, "alive", true);

	var boardX = _px + 18;
	var boardY = _py + 36;
	var boardW = _pw - 36;
	var boardH = _ph - 54;
	draw_set_colour(make_color_rgb(8, 12, 18));
	draw_rectangle(boardX, boardY, boardX + boardW, boardY + boardH, false);

	var headX = boardX + headXNorm * boardW;
	var headY = boardY + headYNorm * boardH;
	var bodyLen = clamp(len, 3, 24);
	for (var i = 0; i < bodyLen; i++) {
		var t = i / max(1, bodyLen - 1);
		var segX = headX - t * 40;
		var segY = headY;
		draw_set_colour(make_color_rgb(58 + floor(80 * (1 - t)), 180 + floor(40 * (1 - t)), 86));
		draw_circle(segX, segY, 5, false);
	}

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_colour(c_white);
	draw_text(_px + 12, _py + 10, _name + (alive ? "" : " (OUT)"));
	draw_set_colour(make_color_rgb(190, 200, 214));
	draw_text(_px + 12, _py + _ph - 22, "Score " + string(scoreValue) + "  Length " + string(len));
}

if (state == "START") {
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_colour(c_white);
	draw_text(room_width * 0.5, room_height * 0.5 - 92, "SNAKE GRID ARCADE");
	draw_text(room_width * 0.5, room_height * 0.5 - 68, "Solo now uses live SGC API settlement");

	var soloColor = hoverSolo ? make_color_rgb(84, 156, 136) : make_color_rgb(56, 110, 98);
	var showdownColor = hoverShowdown ? make_color_rgb(150, 88, 132) : make_color_rgb(108, 56, 96);
	draw_set_colour(soloColor);
	draw_roundrect(room_width * 0.5 - 164, room_height * 0.5 - 26, room_width * 0.5 + 164, room_height * 0.5 + 22, false);
	draw_set_colour(c_white);
	draw_roundrect(room_width * 0.5 - 164, room_height * 0.5 - 26, room_width * 0.5 + 164, room_height * 0.5 + 22, true);
	draw_text(room_width * 0.5, room_height * 0.5 - 2, "SOLO START (DEPOSIT 25 SGC)");

	draw_set_colour(showdownColor);
	draw_roundrect(room_width * 0.5 - 164, room_height * 0.5 + 34, room_width * 0.5 + 164, room_height * 0.5 + 82, false);
	draw_set_colour(c_white);
	draw_roundrect(room_width * 0.5 - 164, room_height * 0.5 + 34, room_width * 0.5 + 164, room_height * 0.5 + 82, true);
	draw_text(room_width * 0.5, room_height * 0.5 + 58, "SHOWDOWN LOBBY (2P + 5 SPECTATORS)");
	draw_text(room_width * 0.5, room_height * 0.5 + 112, "S: solo  |  M: showdown  |  Esc: arcade lobby");
	exit;
}

if (state == "SHOWDOWN_LOBBY") {
	var panelX1 = 16;
	var panelY1 = 120;
	var panelX2 = room_width - 16;
	var panelY2 = room_height - 40;
	var listX = panelX1 + 18;
	var listY = panelY1 + 72;
	var listW = panelX2 - panelX1 - 36;
	var rowH = 36;

	draw_set_colour(make_color_rgb(20, 24, 32));
	draw_roundrect(panelX1, panelY1, panelX2, panelY2, false);
	draw_set_colour(make_color_rgb(86, 164, 192));
	draw_roundrect(panelX1, panelY1, panelX2, panelY2, true);

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_colour(c_white);
	draw_text(panelX1 + 18, panelY1 + 14, "SNAKE SHOWDOWN");
	draw_set_colour(make_color_rgb(190, 200, 214));
	draw_text(panelX1 + 18, panelY1 + 34, "Lobby: " + showdownCurrentLobbyName + "  |  Role: " + showdownRole + "  |  State: " + showdownState);
	draw_text(panelX1 + 18, panelY1 + 52, showdownSummary);

	var inCurrentLobby = showdownCurrentLobbyId != "";
	if (!inCurrentLobby) {
		draw_set_colour(make_color_rgb(44, 88, 74));
		draw_roundrect(panelX1 + 18, panelY1 + 14, panelX1 + 210, panelY1 + 52, false);
		draw_set_colour(c_white);
		draw_roundrect(panelX1 + 18, panelY1 + 14, panelX1 + 210, panelY1 + 52, true);
		draw_text(panelX1 + 32, panelY1 + 25, "Create Lobby");

		draw_set_colour(make_color_rgb(44, 88, 74));
		draw_roundrect(panelX1 + 222, panelY1 + 14, panelX1 + 414, panelY1 + 52, false);
		draw_set_colour(c_white);
		draw_roundrect(panelX1 + 222, panelY1 + 14, panelX1 + 414, panelY1 + 52, true);
		draw_text(panelX1 + 236, panelY1 + 25, "Join Selected");

		for (var i = 0; i < min(6, array_length(showdownLobbyList)); i++) {
			var lobbyInfo = showdownLobbyList[i];
			var rowY = listY + i * (rowH + 8);
			var lobbyId = rouletteStructGet(lobbyInfo, "id", "");
			var isSelected = lobbyId == showdownSelectedLobbyId;
			draw_set_colour(isSelected ? make_color_rgb(60, 94, 130) : make_color_rgb(12, 18, 28));
			draw_roundrect(listX, rowY, listX + listW, rowY + rowH, false);
			draw_set_colour(make_color_rgb(66, 118, 154));
			draw_roundrect(listX, rowY, listX + listW, rowY + rowH, true);
			draw_set_colour(c_white);
			draw_text(listX + 12, rowY + 8, rouletteStructGet(lobbyInfo, "name", "Lobby"));
			draw_set_halign(fa_right);
			draw_text(listX + listW - 12, rowY + 8, string(rouletteStructGet(lobbyInfo, "playerCount", 0)) + "/" + string(rouletteStructGet(lobbyInfo, "maxPlayers", 0)));
			draw_set_halign(fa_left);
		}
	} else {
		draw_set_colour(make_color_rgb(102, 58, 48));
		draw_roundrect(panelX1 + 630, panelY1 + 14, panelX1 + 822, panelY1 + 52, false);
		draw_set_colour(c_white);
		draw_roundrect(panelX1 + 630, panelY1 + 14, panelX1 + 822, panelY1 + 52, true);
		draw_text(panelX1 + 644, panelY1 + 25, "Start Showdown");

		draw_set_colour(make_color_rgb(84, 62, 48));
		draw_roundrect(panelX1 + 426, panelY1 + 14, panelX1 + 618, panelY1 + 52, false);
		draw_set_colour(c_white);
		draw_roundrect(panelX1 + 426, panelY1 + 14, panelX1 + 618, panelY1 + 52, true);
		draw_text(panelX1 + 440, panelY1 + 25, "Back To Lobbies");

		var betY = panelY1 + 330;
		var chipW = 88;
		var chipGap = 10;
		var chips = [1, 5, 10, 25, 100];
		for (var c = 0; c < array_length(chips); c++) {
			var value = chips[c];
			var cx = panelX1 + 18 + c * (chipW + chipGap);
			draw_set_colour(value == selectedBetAmount ? make_color_rgb(168, 126, 58) : make_color_rgb(42, 60, 92));
			draw_roundrect(cx, betY + 12, cx + chipW, betY + 42, false);
			draw_set_colour(c_white);
			draw_roundrect(cx, betY + 12, cx + chipW, betY + 42, true);
			draw_text(cx + 12, betY + 20, string(value) + " SGC");
		}

		draw_set_colour(make_color_rgb(36, 60, 98));
		draw_roundrect(panelX1 + 18, betY + 54, panelX1 + 280, betY + 118, false);
		draw_set_colour(c_white);
		draw_roundrect(panelX1 + 18, betY + 54, panelX1 + 280, betY + 118, true);
		draw_set_colour(make_color_rgb(198, 208, 220));
		draw_text(panelX1 + 30, betY + 64, showdownP1Name + " (P1)");

		draw_set_colour(make_color_rgb(36, 60, 98));
		draw_roundrect(panelX1 + 296, betY + 54, panelX1 + 558, betY + 118, false);
		draw_set_colour(c_white);
		draw_roundrect(panelX1 + 296, betY + 54, panelX1 + 558, betY + 118, true);
		draw_set_colour(make_color_rgb(198, 208, 220));
		draw_text(panelX1 + 308, betY + 64, showdownP2Name + " (P2)");

		if (showdownPromptOpen && showdownRole == "spectator") {
			draw_set_colour(make_color_rgb(48, 92, 70));
			draw_roundrect(panelX1 + 18, betY + 132, panelX1 + 280, betY + 170, false);
			draw_set_colour(c_white);
			draw_roundrect(panelX1 + 18, betY + 132, panelX1 + 280, betY + 170, true);
			draw_text(panelX1 + 32, betY + 143, "Claim Player 2 Seat");
		}
	}
	exit;
}

if (state == "PLAYING" || state == "GAMEOVER") {
	for (var xx = 0; xx < gridW; xx++) {
		for (var yy = 0; yy < gridH; yy++) {
			var cell = gameBoard[# xx, yy];
			var px = boardX + xx * cellSize;
			var py = boardY + yy * cellSize;
			drawSnakeBoardCell(px, py, cell, cellSize);
		}
	}

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_colour(c_white);
	draw_text(8, 52, "Score: " + string(snakeScore));
	draw_text(8, 70, "Length: " + string(snakeLength));
	draw_text(8, 88, "Distance: " + string(snakeDistance(id)));

	if (mode == "showdown") {
		var localIsP1 = snakePlayerId != "" && snakePlayerId == showdownPlayer1Id;
		var remoteName = localIsP1 ? showdownP2Name : showdownP1Name;
		var remoteSnake = localIsP1 ? showdownP2Snake : showdownP1Snake;
		var remoteX = localIsP1 ? room_width - 350 : 30;
		drawSnakeTelemetryField(remoteX, 120, 320, 260, remoteName, remoteSnake, false);
	}

	if (state == "GAMEOVER") {
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_set_colour(c_white);
		draw_text(room_width * 0.5, room_height * 0.5, mode == "solo" ? "RUN OVER\nPress any key" : "RACE FINISHED\nAwaiting result...");
	}
	exit;
}

if (state == "SHOWDOWN_WATCH") {
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	draw_set_colour(c_white);
	draw_text(room_width * 0.5, 96, showdownState == "racing" ? "SNAKE SHOWDOWN LIVE" : "SNAKE SHOWDOWN RESULTS");
	draw_set_colour(make_color_rgb(190, 200, 214));
	draw_text(room_width * 0.5, 118, showdownSummary);

	drawSnakeTelemetryField(room_width * 0.5 - 350, 170, 320, 260, showdownP1Name, showdownP1Snake, showdownPlayer1Id == snakePlayerId);
	drawSnakeTelemetryField(room_width * 0.5 + 30, 170, 320, 260, showdownP2Name, showdownP2Snake, showdownPlayer2Id == snakePlayerId);
}