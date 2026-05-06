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
	var segmentPoints = rouletteStructGet(_telemetry, "segmentPoints", []);

	var boardX = _px + 18;
	var boardY = _py + 36;
	var boardW = _pw - 36;
	var boardH = _ph - 54;
	draw_set_colour(make_color_rgb(8, 12, 18));
	draw_rectangle(boardX, boardY, boardX + boardW, boardY + boardH, false);

	var pointCount = is_array(segmentPoints) ? floor(array_length(segmentPoints) * 0.5) : 0;
	if (pointCount <= 0) {
		segmentPoints = [headXNorm, headYNorm];
		pointCount = 1;
	}

	for (var i = pointCount - 1; i >= 0; i--) {
		var pxNorm = clamp(segmentPoints[i * 2], 0, 1);
		var pyNorm = clamp(segmentPoints[i * 2 + 1], 0, 1);
		var segX = boardX + pxNorm * boardW;
		var segY = boardY + pyNorm * boardH;
		var t = i / max(1, pointCount - 1);
		if (i < pointCount - 1) {
			var nextXNorm = clamp(segmentPoints[(i + 1) * 2], 0, 1);
			var nextYNorm = clamp(segmentPoints[(i + 1) * 2 + 1], 0, 1);
			var nextX = boardX + nextXNorm * boardW;
			var nextY = boardY + nextYNorm * boardH;
			draw_set_colour(make_color_rgb(44 + floor(70 * (1 - t)), 126 + floor(54 * (1 - t)), 72));
			draw_line(segX, segY, nextX, nextY);
		}
		draw_set_colour(make_color_rgb(58 + floor(80 * (1 - t)), 180 + floor(40 * (1 - t)), 86));
		draw_circle(segX, segY, i == 0 ? 6 : 5, false);
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
	var panelY1 = 86;
	var panelX2 = room_width - 16;
	var panelY2 = room_height - 24;
	var contentLeft = panelX1 + 18;
	var contentRight = panelX2 - 18;
	var gap = 14;
	var headerX1 = panelX1 + 12;
	var headerY1 = panelY1 + 12;
	var headerX2 = panelX2 - 12;
	var headerY2 = headerY1 + 64;
	var primaryTop = headerY2 + 22;
	var participantsW = clamp(floor(room_width * 0.24), 260, 300);
	var participantsX = contentRight - participantsW;
	var contentW = clamp(participantsX - contentLeft - gap, 260, 680);
	var primaryW = floor((contentW - gap) * 0.5);
	var mediumW = 190;
	var buttonH = 40;
	var betSectionY = primaryTop + 88;
	var chipRowY = betSectionY + 22;
	var chipW = floor((contentW - gap * 4) / 5);
	var chipH = 30;
	var betSpotY = chipRowY + chipH + 14;
	var betSpotW = floor((contentW - gap) * 0.5);
	var betSpotH = 94;
	var claimY = betSpotY + betSpotH + 22;
	var rematchY = claimY + 58;
	var participantsY = primaryTop;
	var participantsH = panelY2 - participantsY - 18;
	var listX = contentLeft;
	var listY = primaryTop + buttonH + 28;
	var listW = contentW;
	var listRowH = 34;
	var inCurrentLobby = showdownCurrentLobbyId != "";

	function drawClampedText(_x, _y, _text, _maxWidth) {
		var s = string(_text);
		if (_maxWidth <= 0) {
			draw_text(_x, _y, s);
			return;
		}
		if (string_width(s) <= _maxWidth) {
			draw_text(_x, _y, s);
			return;
		}
		var suffix = "...";
		var limit = max(0, _maxWidth - string_width(suffix));
		while (string_length(s) > 0 && string_width(s) > limit) {
			s = string_copy(s, 1, string_length(s) - 1);
		}
		draw_text(_x, _y, s + suffix);
	}

	function drawBetChip(_cx, _cy, _amount, _isMine) {
		var baseColor = _isMine ? make_color_rgb(226, 160, 74) : make_color_rgb(90, 126, 186);
		draw_set_colour(baseColor);
		draw_circle(_cx, _cy, 14, false);
		draw_set_colour(c_white);
		draw_circle(_cx, _cy, 14, true);
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_set_colour(make_color_rgb(14, 20, 30));
		draw_text(_cx, _cy, string(_amount));
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
	}

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_colour(make_color_rgb(20, 24, 32));
	draw_roundrect(panelX1, panelY1, panelX2, panelY2, false);
	draw_set_colour(make_color_rgb(86, 164, 192));
	draw_roundrect(panelX1, panelY1, panelX2, panelY2, true);

	draw_set_colour(make_color_rgb(12, 18, 28));
	draw_roundrect(headerX1, headerY1, headerX2, headerY2, false);
	draw_set_colour(make_color_rgb(66, 118, 154));
	draw_roundrect(headerX1, headerY1, headerX2, headerY2, true);

	draw_set_colour(c_white);
	draw_text(contentLeft + 6, headerY1 + 10, "SNAKE SHOWDOWN");
	draw_set_colour(make_color_rgb(190, 200, 214));
	drawClampedText(contentLeft + 6, headerY1 + 30, "Lobby: " + showdownCurrentLobbyName + "  |  Role: " + showdownRole + "  |  State: " + showdownState, headerX2 - (contentLeft + 20));
	drawClampedText(contentLeft + 6, headerY1 + 46, showdownSummary, headerX2 - (contentLeft + 20));

	if (!inCurrentLobby) {
		draw_set_colour(make_color_rgb(156, 168, 186));
		draw_text(contentLeft, primaryTop - 24, "Lobby Browser");

		var createColor = hoverCreate ? make_color_rgb(68, 128, 104) : make_color_rgb(44, 88, 74);
		var joinColor = hoverJoin ? make_color_rgb(68, 128, 104) : make_color_rgb(44, 88, 74);
		draw_set_colour(createColor);
		draw_roundrect(contentLeft, primaryTop, contentLeft + primaryW, primaryTop + buttonH, false);
		draw_set_colour(c_white);
		draw_roundrect(contentLeft, primaryTop, contentLeft + primaryW, primaryTop + buttonH, true);
		draw_text(contentLeft + 18, primaryTop + 12, "Create Lobby");

		draw_set_colour(joinColor);
		draw_roundrect(contentLeft + primaryW + gap, primaryTop, contentLeft + primaryW * 2 + gap, primaryTop + buttonH, false);
		draw_set_colour(c_white);
		draw_roundrect(contentLeft + primaryW + gap, primaryTop, contentLeft + primaryW * 2 + gap, primaryTop + buttonH, true);
		draw_text(contentLeft + primaryW + gap + 18, primaryTop + 12, "Join Selected");

		draw_set_colour(make_color_rgb(156, 168, 186));
		draw_text(listX, listY - 24, "Available Lobbies");
		for (var lobbyRow = 0; lobbyRow < min(6, array_length(showdownLobbyList)); lobbyRow++) {
			var lobbyInfo = showdownLobbyList[lobbyRow];
			var rowY = listY + lobbyRow * (listRowH + 8);
			var lobbyId = rouletteStructGet(lobbyInfo, "id", "");
			var isSelected = lobbyId == showdownSelectedLobbyId;
			var isCurrent = lobbyId == showdownCurrentLobbyId;
			draw_set_colour(isSelected ? make_color_rgb(60, 94, 130) : make_color_rgb(12, 18, 28));
			draw_roundrect(listX, rowY, listX + listW, rowY + listRowH, false);
			draw_set_colour(isCurrent ? make_color_rgb(120, 196, 164) : make_color_rgb(66, 118, 154));
			draw_roundrect(listX, rowY, listX + listW, rowY + listRowH, true);
			draw_set_colour(c_white);
			draw_text(listX + 12, rowY + 8, rouletteStructGet(lobbyInfo, "name", "Lobby"));
			draw_set_halign(fa_right);
			draw_text(listX + listW - 12, rowY + 8, string(rouletteStructGet(lobbyInfo, "playerCount", 0)) + "/" + string(rouletteStructGet(lobbyInfo, "maxPlayers", 0)) + (isCurrent ? "  CURRENT" : ""));
			draw_set_halign(fa_left);
		}
		if (array_length(showdownLobbyList) == 0) {
			draw_set_colour(make_color_rgb(180, 188, 198));
			draw_text(listX + 12, listY + 8, "No snake lobbies yet. Create one to get started.");
		}
	} else {
		draw_set_colour(make_color_rgb(156, 168, 186));
		draw_text(contentLeft, primaryTop - 24, "Lobby Room");

		var startColor = hoverStartRace ? make_color_rgb(156, 88, 70) : make_color_rgb(102, 58, 48);
		var leaveColor = hoverLeave ? make_color_rgb(122, 90, 70) : make_color_rgb(84, 62, 48);
		draw_set_colour(startColor);
		draw_roundrect(contentLeft, primaryTop, contentLeft + primaryW, primaryTop + buttonH, false);
		draw_set_colour(c_white);
		draw_roundrect(contentLeft, primaryTop, contentLeft + primaryW, primaryTop + buttonH, true);
		draw_text(contentLeft + 18, primaryTop + 12, "Start Showdown");

		draw_set_colour(leaveColor);
		draw_roundrect(contentLeft + primaryW + gap, primaryTop, contentLeft + primaryW * 2 + gap, primaryTop + buttonH, false);
		draw_set_colour(c_white);
		draw_roundrect(contentLeft + primaryW + gap, primaryTop, contentLeft + primaryW * 2 + gap, primaryTop + buttonH, true);
		draw_text(contentLeft + primaryW + gap + 18, primaryTop + 12, "Back To Lobbies");

		draw_set_colour(make_color_rgb(156, 168, 186));
		draw_text(contentLeft, betSectionY, "Spectator Bets");

		var myP1Total = 0;
		var myP2Total = 0;
		var p1Total = 0;
		var p2Total = 0;
		for (var betIndex = 0; betIndex < array_length(showdownSnakeBets); betIndex++) {
			var betRow = showdownSnakeBets[betIndex];
			var amount = max(0, floor(rouletteStructGet(betRow, "amount", 0)));
			var targetId = rouletteStructGet(betRow, "targetId", "");
			var bettorId = rouletteStructGet(betRow, "bettorId", "");
			if (amount <= 0) continue;
			if (targetId == showdownPlayer1Id) p1Total += amount;
			if (targetId == showdownPlayer2Id) p2Total += amount;
			if (bettorId == snakePlayerId) {
				if (targetId == showdownPlayer1Id) myP1Total += amount;
				if (targetId == showdownPlayer2Id) myP2Total += amount;
			}
		}

		var p1OthersTotal = max(0, p1Total - myP1Total);
		var p2OthersTotal = max(0, p2Total - myP2Total);
		var canPlaceBet = showdownRole == "spectator" && showdownAllowBets;
		var chipValues = [1, 5, 10, 25, 100];
		for (var chipIndex = 0; chipIndex < array_length(chipValues); chipIndex++) {
			var chipValue = chipValues[chipIndex];
			var chipX = contentLeft + (chipW + gap) * chipIndex;
			var activeChip = chipValue == selectedBetAmount;
			var chipHover = (chipValue == 1 && hoverBet1) || (chipValue == 5 && hoverBet5) || (chipValue == 10 && hoverBet10) || (chipValue == 25 && hoverBet25) || (chipValue == 100 && hoverBet100);
			draw_set_colour(activeChip ? make_color_rgb(168, 126, 58) : (chipHover ? make_color_rgb(88, 112, 154) : make_color_rgb(42, 60, 92)));
			draw_roundrect(chipX, chipRowY, chipX + chipW, chipRowY + chipH, false);
			draw_set_colour(c_white);
			draw_roundrect(chipX, chipRowY, chipX + chipW, chipRowY + chipH, true);
			draw_text(chipX + 12, chipRowY + 8, string(chipValue) + " SGC");
		}

		var p1SpotColor = canPlaceBet ? (hoverBetP1 ? make_color_rgb(88, 120, 170) : make_color_rgb(36, 60, 98)) : make_color_rgb(34, 46, 68);
		var p2SpotColor = canPlaceBet ? (hoverBetP2 ? make_color_rgb(88, 120, 170) : make_color_rgb(36, 60, 98)) : make_color_rgb(34, 46, 68);
		draw_set_colour(p1SpotColor);
		draw_roundrect(contentLeft, betSpotY, contentLeft + betSpotW, betSpotY + betSpotH, false);
		draw_set_colour(c_white);
		draw_roundrect(contentLeft, betSpotY, contentLeft + betSpotW, betSpotY + betSpotH, true);
		draw_set_colour(p2SpotColor);
		draw_roundrect(contentLeft + betSpotW + gap, betSpotY, contentLeft + betSpotW * 2 + gap, betSpotY + betSpotH, false);
		draw_set_colour(c_white);
		draw_roundrect(contentLeft + betSpotW + gap, betSpotY, contentLeft + betSpotW * 2 + gap, betSpotY + betSpotH, true);

		draw_set_colour(make_color_rgb(198, 208, 220));
		draw_text(contentLeft + 12, betSpotY + 8, showdownP1Name + " (P1)");
		draw_text(contentLeft + betSpotW + gap + 12, betSpotY + 8, showdownP2Name + " (P2)");
		draw_set_colour(make_color_rgb(176, 188, 202));
		draw_text(contentLeft + 12, betSpotY + 26, "Table: " + string(p1Total) + " SGC   You: " + string(myP1Total));
		draw_text(contentLeft + betSpotW + gap + 12, betSpotY + 26, "Table: " + string(p2Total) + " SGC   You: " + string(myP2Total));

		if (p1OthersTotal > 0) drawBetChip(contentLeft + 36, betSpotY + betSpotH - 24, p1OthersTotal, false);
		if (p2OthersTotal > 0) drawBetChip(contentLeft + betSpotW + gap + 36, betSpotY + betSpotH - 24, p2OthersTotal, false);
		if (myP1Total > 0) drawBetChip(contentLeft + betSpotW - 34, betSpotY + betSpotH - 24, myP1Total, true);
		if (myP2Total > 0) drawBetChip(contentLeft + betSpotW * 2 + gap - 34, betSpotY + betSpotH - 24, myP2Total, true);

		if (!showdownAllowBets) {
			draw_set_colour(make_color_rgb(176, 188, 202));
			draw_text(contentLeft, betSpotY + betSpotH + 6, "Betting closed while race is live.");
		} else if (showdownRole == "spectator") {
			draw_set_colour(make_color_rgb(176, 188, 202));
			draw_text(contentLeft, betSpotY + betSpotH + 6, "Pick chip value, then click P1/P2 to add chips (repeat to stack).");
		}

		if (showdownPromptOpen && showdownRole == "spectator") {
			draw_set_colour(make_color_rgb(156, 168, 186));
			draw_text(contentLeft, claimY - 24, "Open Seat");
			draw_set_colour(hoverClaim ? make_color_rgb(74, 140, 102) : make_color_rgb(48, 92, 70));
			draw_roundrect(contentLeft, claimY, contentLeft + 270, claimY + buttonH, false);
			draw_set_colour(c_white);
			draw_roundrect(contentLeft, claimY, contentLeft + 270, claimY + buttonH, true);
			draw_text(contentLeft + 16, claimY + 12, "Claim Player 2 Seat");
		}

		if (showdownRole == "racer" && showdownState == "showdown") {
			draw_set_colour(make_color_rgb(156, 168, 186));
			draw_text(contentLeft, rematchY - 24, "Post Match");
			draw_set_colour(hoverRematchYes ? make_color_rgb(74, 148, 92) : make_color_rgb(48, 98, 60));
			draw_roundrect(contentLeft, rematchY, contentLeft + mediumW, rematchY + buttonH, false);
			draw_set_colour(c_white);
			draw_roundrect(contentLeft, rematchY, contentLeft + mediumW, rematchY + buttonH, true);
			draw_text(contentLeft + 16, rematchY + 12, "Accept Rematch");

			draw_set_colour(hoverRematchNo ? make_color_rgb(160, 88, 88) : make_color_rgb(102, 54, 54));
			draw_roundrect(contentLeft + mediumW + gap, rematchY, contentLeft + mediumW * 2 + gap, rematchY + buttonH, false);
			draw_set_colour(c_white);
			draw_roundrect(contentLeft + mediumW + gap, rematchY, contentLeft + mediumW * 2 + gap, rematchY + buttonH, true);
			draw_text(contentLeft + mediumW + gap + 16, rematchY + 12, "Decline Rematch");

			draw_set_colour(hoverNextChallenger ? make_color_rgb(122, 122, 170) : make_color_rgb(80, 80, 120));
			draw_roundrect(contentLeft + mediumW * 2 + gap * 2, rematchY, contentLeft + mediumW * 2 + gap * 2 + 220, rematchY + buttonH, false);
			draw_set_colour(c_white);
			draw_roundrect(contentLeft + mediumW * 2 + gap * 2, rematchY, contentLeft + mediumW * 2 + gap * 2 + 220, rematchY + buttonH, true);
			draw_text(contentLeft + mediumW * 2 + gap * 2 + 16, rematchY + 12, "Next Challenger");
		}

		draw_set_colour(make_color_rgb(12, 18, 28));
		draw_roundrect(participantsX, participantsY, participantsX + participantsW, participantsY + participantsH, false);
		draw_set_colour(make_color_rgb(66, 118, 154));
		draw_roundrect(participantsX, participantsY, participantsX + participantsW, participantsY + participantsH, true);

		draw_set_colour(make_color_rgb(190, 200, 214));
		draw_text(participantsX + 16, participantsY + 14, "Participants");
		for (var pIndex = 0; pIndex < min(7, array_length(showdownParticipants)); pIndex++) {
			var p = showdownParticipants[pIndex];
			var rowY = participantsY + 42 + pIndex * 20;
			var tag = rouletteStructGet(p, "role", "spectator");
			draw_set_colour(rouletteStructGet(p, "playerId", "") == snakePlayerId ? c_white : make_color_rgb(180, 188, 198));
			draw_text(participantsX + 16, rowY, rouletteStructGet(p, "name", "Player") + " [" + tag + "]");
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