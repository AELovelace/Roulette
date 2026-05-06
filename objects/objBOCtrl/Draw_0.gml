draw_set_colour(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_text(8, 8, "[SGC] Balance: " + string(global.sgcArcadeBalance));
draw_text(8, 28, "Broker: " + breakoutBrokerStatus);

draw_set_halign(fa_right);
draw_text(room_width - 8, 8, "Hi Score: " + string(global.highScore));
draw_text(room_width - 8, 28, "Buy-in: " + string(entryCost));

draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
draw_set_colour(make_color_rgb(220, 230, 230));
draw_text(room_width * 0.5, room_height - 8, statusText);

function drawBreakoutTelemetryField(_px, _py, _pw, _ph, _title, _telemetry, _localFocus, _ballXOverride, _ballYOverride, _batOverride) {
	draw_set_colour(make_color_rgb(14, 18, 28));
	draw_roundrect(_px, _py, _px + _pw, _py + _ph, false);
	draw_set_colour(_localFocus ? make_color_rgb(110, 188, 236) : make_color_rgb(86, 130, 176));
	draw_roundrect(_px, _py, _px + _pw, _py + _ph, true);

	var tScore = rouletteStructGet(_telemetry, "score", 0);
	var tLevel = rouletteStructGet(_telemetry, "level", 1);
	var tLives = rouletteStructGet(_telemetry, "lives", 3);
	var tDistance = rouletteStructGet(_telemetry, "distance", 0);
	var tBatNorm = clamp(_batOverride >= 0 ? _batOverride : rouletteStructGet(_telemetry, "batNorm", 0.5), 0, 1);
	var tBallXNorm = clamp(_ballXOverride >= 0 ? _ballXOverride : rouletteStructGet(_telemetry, "ballXNorm", 0.5), 0, 1);
	var tBallYNorm = clamp(_ballYOverride >= 0 ? _ballYOverride : rouletteStructGet(_telemetry, "ballYNorm", 0.85), 0, 1);
	var tBrickCount = max(0, floor(rouletteStructGet(_telemetry, "brickCount", 0)));
	var tBrickMask = rouletteStructGet(_telemetry, "brickMask", "");
	var tBrickColorMask = rouletteStructGet(_telemetry, "brickColorMask", "");

	function brickColorFromCode(_code) {
		switch (_code) {
			case "1": return c_red;
			case "2": return c_yellow;
			case "3": return c_blue;
			case "4": return c_green;
			case "5": return c_fuchsia;
			case "6": return c_orange;
		}
		return make_color_rgb(96, 170, 228);
	}

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_colour(c_white);
	draw_text(_px + 10, _py + 8, _title);
	draw_set_colour(make_color_rgb(188, 202, 220));
	draw_text(_px + 10, _py + 26, "Score " + string(tScore) + " | Level " + string(tLevel) + " | Lives " + string(tLives));
	draw_text(_px + 10, _py + 42, "Distance " + string(tDistance));

	var boardX = _px + 32;
	var boardY = _py + 32;
	var boardW = _pw - 64;
	var boardH = _ph - 64;
	draw_set_colour(make_color_rgb(8, 12, 18));
	draw_rectangle(boardX, boardY, boardX + boardW, boardY + boardH, false);

	var cols = 18;
	var rows = 6;
	var cellStepX = 32;
	var cellStepY = 32;
	var brickW = 32;
	var brickH = 16;
	draw_set_colour(make_color_rgb(96, 170, 228));
	if (string_length(tBrickMask) >= cols * rows) {
		for (var i = 0; i < cols * rows; i++) {
			if (string_char_at(tBrickMask, i + 1) != "1") continue;
			var c = i mod cols;
			var r = floor(i / cols);
			if (string_length(tBrickColorMask) >= cols * rows) {
				draw_set_colour(brickColorFromCode(string_char_at(tBrickColorMask, i + 1)));
			} else {
				draw_set_colour(make_color_rgb(96, 170, 228));
			}
			var bx1 = boardX + c * cellStepX + 1;
			var by1 = boardY + r * cellStepY + 1;
			draw_rectangle(bx1, by1, bx1 + brickW - 2, by1 + brickH - 2, false);
		}
	} else {
		for (var j = 0; j < tBrickCount; j++) {
			var cc = j mod cols;
			var rr = floor(j / cols);
			if (rr >= rows) break;
			draw_set_colour(make_color_rgb(96, 170, 228));
			var bbx1 = boardX + cc * cellStepX + 1;
			var bby1 = boardY + rr * cellStepY + 1;
			draw_rectangle(bbx1, bby1, bbx1 + brickW - 2, bby1 + brickH - 2, false);
		}
	}

	var batY = boardY + boardH - 14;
	var batHalf = 42;
	var batX = boardX + tBatNorm * boardW;
	draw_set_colour(make_color_rgb(120, 255, 166));
	draw_rectangle(batX - batHalf, batY, batX + batHalf, batY + 8, false);

	var ballX = boardX + tBallXNorm * boardW;
	var ballY = boardY + tBallYNorm * boardH;
	draw_set_colour(make_color_rgb(255, 224, 160));
	draw_circle(ballX, ballY, 5, false);
}

if (state == "START") {
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_colour(c_white);
	draw_text(room_width * 0.5, room_height * 0.5 - 92, "BREAKOUT ARCADE");
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
	draw_text(contentLeft + 6, headerY1 + 10, "BREAKOUT SHOWDOWN");
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
			draw_text(listX + 12, listY + 8, "No breakout lobbies yet. Create one to get started.");
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

		var myBetAmount = 0;
		var myBetTargetId = "";
		var p1Total = 0;
		var p2Total = 0;
		for (var betIndex = 0; betIndex < array_length(showdownBreakoutBets); betIndex++) {
			var betRow = showdownBreakoutBets[betIndex];
			var amount = max(0, floor(rouletteStructGet(betRow, "amount", 0)));
			var targetId = rouletteStructGet(betRow, "targetId", "");
			var bettorId = rouletteStructGet(betRow, "bettorId", "");
			if (amount <= 0) continue;
			if (targetId == showdownPlayer1Id) p1Total += amount;
			if (targetId == showdownPlayer2Id) p2Total += amount;
			if (bettorId == breakoutPlayerId) {
				myBetAmount = amount;
				myBetTargetId = targetId;
			}
		}

		var canPlaceBet = showdownRole == "spectator" && showdownAllowBets && myBetAmount <= 0;
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
		draw_text(contentLeft + 12, betSpotY + 26, "Table: " + string(p1Total) + " SGC");
		draw_text(contentLeft + betSpotW + gap + 12, betSpotY + 26, "Table: " + string(p2Total) + " SGC");

		if (p1Total > 0) {
			drawBetChip(contentLeft + 36, betSpotY + betSpotH - 24, p1Total, false);
		}
		if (p2Total > 0) {
			drawBetChip(contentLeft + betSpotW + gap + 36, betSpotY + betSpotH - 24, p2Total, false);
		}

		if (myBetAmount > 0) {
			var myChipX = myBetTargetId == showdownPlayer1Id ? contentLeft + betSpotW - 34 : contentLeft + betSpotW * 2 + gap - 34;
			var myChipY = betSpotY + betSpotH - 24;
			drawBetChip(myChipX, myChipY, myBetAmount, true);
			draw_set_colour(make_color_rgb(214, 192, 140));
			draw_text(contentLeft, betSpotY + betSpotH + 6, "Your bet is locked for this showdown.");
		} else if (!showdownAllowBets) {
			draw_set_colour(make_color_rgb(176, 188, 202));
			draw_text(contentLeft, betSpotY + betSpotH + 6, "Betting closed while race is live.");
		} else if (showdownRole == "spectator") {
			draw_set_colour(make_color_rgb(176, 188, 202));
			draw_text(contentLeft, betSpotY + betSpotH + 6, "Pick chip value, then click P1 or P2 to place.");
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
		for (var i = 0; i < min(7, array_length(showdownParticipants)); i++) {
			var p = showdownParticipants[i];
			var rowY = participantsY + 42 + i * 20;
			var tag = rouletteStructGet(p, "role", "spectator");
			draw_set_colour(rouletteStructGet(p, "playerId", "") == breakoutPlayerId ? c_white : make_color_rgb(180, 188, 198));
			draw_text(participantsX + 16, rowY, rouletteStructGet(p, "name", "Player") + " [" + tag + "]");
		}
	}
	exit;
}

if (state == "PLAYING" || state == "GAMEOVER") {
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_colour(c_white);
	draw_text(8, 52, "Score: " + string(global.BOPScore));
	draw_text(8, 70, "Level: " + string(level));
	draw_text(8, 88, "Lives: " + string(max(0, global.BOPLives)));
	draw_set_colour(make_color_rgb(44, 94, 142));
	draw_roundrect(currentArenaX - 6, currentArenaY - 6, currentArenaX + arenaW + 6, currentArenaY + arenaH + 6, true);

	if (mode == "showdown") {
		var localIsP1Label = breakoutPlayerId != "" && breakoutPlayerId == showdownPlayer1Id;
		var localLabel = localIsP1Label ? showdownP1Name : showdownP2Name;
		draw_set_halign(fa_center);
		draw_set_valign(fa_bottom);
		draw_set_colour(c_white);
		draw_text(currentArenaX + arenaW * 0.5, currentArenaY - 10, localLabel);
	}

	if (mode == "showdown") {
		var localIsP1 = breakoutPlayerId != "" && breakoutPlayerId == showdownPlayer1Id;
		var remoteName = localIsP1 ? showdownP2Name : showdownP1Name;
		var remoteBo = localIsP1 ? showdownP2Breakout : showdownP1Breakout;
		var remoteArenaX = localIsP1 ? showdownArenaRightX : showdownArenaLeftX;
		var remoteBallXDraw = localIsP1 ? showdownP2BallXDraw : showdownP1BallXDraw;
		var remoteBallYDraw = localIsP1 ? showdownP2BallYDraw : showdownP1BallYDraw;

		draw_set_colour(make_color_rgb(16, 26, 40));
		draw_roundrect(198, 48, room_width - 8, 124, false);
		draw_set_colour(make_color_rgb(110, 170, 210));
		draw_roundrect(198, 48, room_width - 8, 124, true);
		draw_set_colour(c_white);
		draw_text(208, 56, "Opponent: " + remoteName);
		draw_text(208, 74, "Score " + string(rouletteStructGet(remoteBo, "score", 0)) + " | Level " + string(rouletteStructGet(remoteBo, "level", 1)) + " | Lives " + string(rouletteStructGet(remoteBo, "lives", 3)));
		draw_text(208, 92, "Distance " + string(rouletteStructGet(remoteBo, "distance", 0)));
		draw_text(208, 110, "Showdown state: " + showdownState);
		draw_set_halign(fa_center);
		draw_set_valign(fa_bottom);
		draw_set_colour(c_white);
		draw_text(remoteArenaX + arenaW * 0.5, showdownArenaY - 10, remoteName);
		var remoteBatDraw = localIsP1 ? showdownP2BatDraw : showdownP1BatDraw;
		drawBreakoutTelemetryField(remoteArenaX, showdownArenaY, arenaW, arenaH, remoteName, remoteBo, false, remoteBallXDraw, remoteBallYDraw, remoteBatDraw);
	}
}

if (state == "SHOWDOWN_WATCH") {
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	draw_set_colour(c_white);
	draw_text(room_width * 0.5, 108, showdownState == "racing" ? "SHOWDOWN LIVE WATCH" : "SHOWDOWN HOT-SEAT RESULTS");
	draw_set_colour(make_color_rgb(188, 202, 220));
	draw_text(room_width * 0.5, 128, showdownState == "racing" ? "Waiting for both racers to finish" : "Esc to return to lobby controls");

	draw_set_halign(fa_center);
	draw_set_valign(fa_bottom);
	draw_set_colour(c_white);
	draw_text(showdownArenaLeftX + arenaW * 0.5, showdownArenaY - 10, showdownP1Name);
	draw_text(showdownArenaRightX + arenaW * 0.5, showdownArenaY - 10, showdownP2Name);

	drawBreakoutTelemetryField(showdownArenaLeftX, showdownArenaY, arenaW, arenaH, showdownP1Name, showdownP1Breakout, showdownPlayer1Id == breakoutPlayerId, showdownP1BallXDraw, showdownP1BallYDraw, showdownP1BatDraw);
	drawBreakoutTelemetryField(showdownArenaRightX, showdownArenaY, arenaW, arenaH, showdownP2Name, showdownP2Breakout, showdownPlayer2Id == breakoutPlayerId, showdownP2BallXDraw, showdownP2BallYDraw, showdownP2BatDraw);
}

if (state == "GAMEOVER" && mode == "solo") {
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_colour(c_white);
	draw_text(room_width * 0.5, room_height * 0.5 - 18, "GAME OVER");
	draw_text(room_width * 0.5, room_height * 0.5 + 4, "Payout: " + string(lastRunPayout) + " SGC");
	draw_text(room_width * 0.5, room_height * 0.5 + 26, "Net: " + string(runNet) + " SGC");
	draw_text(room_width * 0.5, room_height * 0.5 + 48, "Press any key to return");
}