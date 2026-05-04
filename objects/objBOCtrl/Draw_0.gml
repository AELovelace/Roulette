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

	if (mode == "showdown") {
		draw_set_colour(make_color_rgb(16, 26, 40));
		draw_roundrect(198, 48, room_width - 8, 124, false);
		draw_set_colour(make_color_rgb(110, 170, 210));
		draw_roundrect(198, 48, room_width - 8, 124, true);
		draw_set_colour(c_white);
		draw_text(208, 56, "Opponent: " + opponentName);
		draw_text(208, 74, "Score " + string(opponentScore) + " | Level " + string(opponentLevel) + " | Lives " + string(opponentLives));
		draw_text(208, 92, "Distance " + string(opponentDistance));
		draw_text(208, 110, "Showdown state: " + showdownState);
	}
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