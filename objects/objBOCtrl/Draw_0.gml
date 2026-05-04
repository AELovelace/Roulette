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
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_colour(make_color_rgb(20, 24, 32));
	draw_roundrect(16, 96, room_width - 16, room_height - 24, false);
	draw_set_colour(make_color_rgb(86, 164, 192));
	draw_roundrect(16, 96, room_width - 16, room_height - 24, true);

	draw_set_colour(c_white);
	draw_text(28, 108, "BREAKOUT SHOWDOWN");
	draw_set_colour(make_color_rgb(190, 200, 214));
	draw_text(28, 126, "Lobby: " + showdownCurrentLobbyName + "  |  Role: " + showdownRole + "  |  State: " + showdownState);
	draw_text(28, 146, showdownSummary);

	var createColor = hoverCreate ? make_color_rgb(68, 128, 104) : make_color_rgb(44, 88, 74);
	var joinColor = hoverJoin ? make_color_rgb(68, 128, 104) : make_color_rgb(44, 88, 74);
	var startColor = hoverStartRace ? make_color_rgb(156, 88, 70) : make_color_rgb(102, 58, 48);
	draw_set_colour(createColor);
	draw_roundrect(34, 140, 214, 178, false);
	draw_set_colour(c_white);
	draw_roundrect(34, 140, 214, 178, true);
	draw_text(48, 152, "Create Lobby");

	draw_set_colour(joinColor);
	draw_roundrect(224, 140, 404, 178, false);
	draw_set_colour(c_white);
	draw_roundrect(224, 140, 404, 178, true);
	draw_text(238, 152, "Join First Lobby");

	draw_set_colour(startColor);
	draw_roundrect(414, 140, 594, 178, false);
	draw_set_colour(c_white);
	draw_roundrect(414, 140, 594, 178, true);
	draw_text(432, 152, "Start Showdown");

	draw_set_colour(hoverBetP1 ? make_color_rgb(112, 94, 152) : make_color_rgb(72, 60, 98));
	draw_roundrect(34, 324, 184, 358, false);
	draw_set_colour(c_white);
	draw_roundrect(34, 324, 184, 358, true);
	draw_text(46, 336, "Bet P1");

	draw_set_colour(hoverBetP2 ? make_color_rgb(112, 94, 152) : make_color_rgb(72, 60, 98));
	draw_roundrect(194, 324, 344, 358, false);
	draw_set_colour(c_white);
	draw_roundrect(194, 324, 344, 358, true);
	draw_text(206, 336, "Bet P2");

	draw_set_colour(hoverBetSend ? make_color_rgb(160, 120, 68) : make_color_rgb(110, 82, 46));
	draw_roundrect(354, 324, 594, 358, false);
	draw_set_colour(c_white);
	draw_roundrect(354, 324, 594, 358, true);
	draw_text(366, 336, "Place " + string(selectedBetAmount) + " SGC Bet");

	if (showdownPromptOpen && showdownRole == "spectator") {
		draw_set_colour(hoverClaim ? make_color_rgb(74, 140, 102) : make_color_rgb(48, 92, 70));
		draw_roundrect(34, 370, 274, 406, false);
		draw_set_colour(c_white);
		draw_roundrect(34, 370, 274, 406, true);
		draw_text(46, 382, "Claim Player 2 Seat");
	}

	if (showdownRole == "racer" && showdownState == "showdown") {
		draw_set_colour(hoverRematchYes ? make_color_rgb(74, 148, 92) : make_color_rgb(48, 98, 60));
		draw_roundrect(34, 412, 204, 448, false);
		draw_set_colour(c_white);
		draw_roundrect(34, 412, 204, 448, true);
		draw_text(46, 424, "Accept Rematch");

		draw_set_colour(hoverRematchNo ? make_color_rgb(160, 88, 88) : make_color_rgb(102, 54, 54));
		draw_roundrect(214, 412, 384, 448, false);
		draw_set_colour(c_white);
		draw_roundrect(214, 412, 384, 448, true);
		draw_text(226, 424, "Decline Rematch");

		draw_set_colour(hoverNextChallenger ? make_color_rgb(122, 122, 170) : make_color_rgb(80, 80, 120));
		draw_roundrect(394, 412, 594, 448, false);
		draw_set_colour(c_white);
		draw_roundrect(394, 412, 594, 448, true);
		draw_text(408, 424, "Next Challenger");
	}

	draw_set_colour(make_color_rgb(190, 200, 214));
	draw_text(28, 468, "Participants");
	for (var i = 0; i < min(7, array_length(showdownParticipants)); i++) {
		var p = showdownParticipants[i];
		var rowY = 488 + i * 16;
		var tag = rouletteStructGet(p, "role", "spectator");
		draw_set_colour(rouletteStructGet(p, "playerId", "") == breakoutPlayerId ? c_white : make_color_rgb(180, 188, 198));
		draw_text(34, rowY, rouletteStructGet(p, "name", "Player") + " [" + tag + "]");
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
	draw_text(room_width * 0.5, 108, "SHOWDOWN LIVE WATCH");
	draw_set_colour(make_color_rgb(188, 202, 220));
	draw_text(room_width * 0.5, 128, "Esc to return to lobby controls");

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