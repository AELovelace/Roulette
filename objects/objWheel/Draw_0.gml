draw_clear_alpha(make_color_rgb(5, 6, 10), 1);

var cx = room_width * 0.5;
var cy = room_height * 0.3;
var displayBallAngle = ((ballAngle mod 360) + 360) mod 360;
var bx = cx + lengthdir_x(ballRadius, displayBallAngle);
var by = cy + lengthdir_y(ballRadius, displayBallAngle);

draw_set_color(make_color_rgb(5, 6, 10));
draw_rectangle(0, 0, room_width, room_height, false);

var brokerMode = multiplayerEnabled && brokerConnected;

draw_set_alpha(0.22);
draw_set_color(c_black);
draw_circle(cx + 10, cy + 14, 196, false);
draw_set_alpha(1);

draw_sprite_ext(sprWheel,0,cx, cy, 1, 1, rotation, c_white,1);
draw_circle_color(bx, by, 8, c_white, c_silver, false);

draw_set_alpha(0.95);
draw_set_color(feltDarkColor);
draw_rectangle(tableX - feltPadX, tableY - feltPadTop, tableX + tableW + feltPadX, tableY + tableH + feltPadBottom, false);
draw_set_alpha(1);

draw_set_color(feltColor);
draw_rectangle(tableX, tableY, tableX + tableW, tableY + tableH, false);

draw_set_font(-1);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);

for (var i = 0; i < array_length(betAreas); i++) {
	var area = betAreas[i];
	var fillColor = area.baseColor;
	if (!spinActive && hoverBetIndex == i) {
		fillColor = merge_color(fillColor, c_white, 0.22);
	}
	if (area.amount > 0) {
		fillColor = merge_color(fillColor, chipColor, 0.10);
	}
	if (area.totalAmount - area.amount > 0) {
		fillColor = merge_color(fillColor, c_black, 0.08);
	}

	draw_set_color(fillColor);
	draw_rectangle(area.x, area.y, area.x + area.w, area.y + area.h, false);

	if (resultLocked && rouletteArrayContains(area.covered, winningNumber)) {
		draw_set_color(chipColor);
	} else {
		draw_set_color(lineColor);
	}
	draw_rectangle(area.x, area.y, area.x + area.w, area.y + area.h, true);

	draw_set_color(area.textColor);
	draw_text(area.x + (area.w * 0.5), area.y + (area.h * 0.5) - 1, area.label);

	if (area.amount > 0) {
		var chipX = area.x + area.w - 12;
		var chipY = area.y + 12;
		draw_circle_color(chipX + 1, chipY + 2, 10, ownChipShadowColor, ownChipShadowColor, false);
		draw_circle_color(chipX, chipY, 10, ownChipColor, c_white, false);
		draw_set_color(c_black);
		draw_text(chipX, chipY, string(area.amount));
	}

	var otherAmount = max(0, area.totalAmount - area.amount);
	if (otherAmount > 0) {
		var otherChipX = area.x + 12;
		var otherChipY = area.y + 12;
		draw_circle_color(otherChipX + 1, otherChipY + 2, 10, otherChipShadowColor, otherChipShadowColor, false);
		draw_circle_color(otherChipX, otherChipY, 10, otherChipColor, c_dkgray, false);
		draw_set_color(c_white);
		draw_text(otherChipX, otherChipY, string(otherAmount));
	}

	if (area.totalAmount > 0) {
		draw_set_halign(fa_left);
		draw_set_valign(fa_bottom);
		draw_set_color(lineColor);
		draw_text(area.x + 3, area.y + area.h - 2, "T:" + string(area.totalAmount));
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
	}
}

draw_set_halign(fa_left);
	draw_set_valign(fa_top);
draw_set_color(lineColor);
draw_text(tableX, tableY - feltPadTop + 12, "SADGIRL ROULETTE // SINGLE ZERO");
draw_text(tableX, tableY - feltPadTop + 30, "> left click adds chip // right click removes selected chip amount");

draw_set_color(panelColor);
draw_rectangle(spinButton.x, spinButton.y, spinButton.x + spinButton.w, spinButton.y + spinButton.h, false);
draw_rectangle(clearButton.x, clearButton.y, clearButton.x + clearButton.w, clearButton.y + clearButton.h, false);
draw_rectangle(lobbyButton.x, lobbyButton.y, lobbyButton.x + lobbyButton.w, lobbyButton.y + lobbyButton.h, false);
draw_rectangle(menuButton.x, menuButton.y, menuButton.x + menuButton.w, menuButton.y + menuButton.h, false);

draw_set_color(lineColor);
draw_rectangle(spinButton.x, spinButton.y, spinButton.x + spinButton.w, spinButton.y + spinButton.h, true);
draw_rectangle(clearButton.x, clearButton.y, clearButton.x + clearButton.w, clearButton.y + clearButton.h, true);
draw_rectangle(lobbyButton.x, lobbyButton.y, lobbyButton.x + lobbyButton.w, lobbyButton.y + lobbyButton.h, true);
draw_rectangle(menuButton.x, menuButton.y, menuButton.x + menuButton.w, menuButton.y + menuButton.h, true);

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
draw_text(spinButton.x + (spinButton.w * 0.5), spinButton.y + (spinButton.h * 0.5), "SPIN");
draw_text(clearButton.x + (clearButton.w * 0.5), clearButton.y + (clearButton.h * 0.5), "CLEAR");
draw_text(lobbyButton.x + (lobbyButton.w * 0.5), lobbyButton.y + (lobbyButton.h * 0.5), "LOBBIES");
draw_text(menuButton.x + (menuButton.w * 0.5), menuButton.y + (menuButton.h * 0.5), "MAIN MENU");

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(lineColor);
draw_text(panelX, panelY + 92, "Chip size");

var statusX = panelX + 168;
var statusY = panelY + 92;

for (var chipIndex = 0; chipIndex < array_length(chipButtons); chipIndex++) {
	var chipButton = chipButtons[chipIndex];
	var chipFill = (currentChip == chipButton.value) ? chipColor : panelColor;
	var chipText = (currentChip == chipButton.value) ? c_black : c_white;

	draw_set_color(chipFill);
	draw_rectangle(chipButton.x, chipButton.y, chipButton.x + chipButton.w, chipButton.y + chipButton.h, false);
	draw_set_color(lineColor);
	draw_rectangle(chipButton.x, chipButton.y, chipButton.x + chipButton.w, chipButton.y + chipButton.h, true);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(chipText);
	draw_text(chipButton.x + (chipButton.w * 0.5), chipButton.y + (chipButton.h * 0.5), "$" + string(chipButton.value));
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

draw_set_color(lineColor);
draw_text(statusX, statusY - 24, "[LOBBY] " + currentLobbyName);
draw_text(statusX, statusY, "[SGC] bankroll: $" + string(bankroll));
draw_text(statusX, statusY + 24, "[TABLE] wagered: $" + string(rouletteGetTotalBet(betAreas)));
draw_text(statusX, statusY + 48, "[PAYOUT] last: $" + string(lastPayout));
draw_text(statusX, statusY + 72, "[BROKER] " + brokerStatus);
draw_text(statusX, statusY + 96, "[PLAYERS] " + string(brokerPlayerCount));
draw_text(statusX, statusY + 120, "Esc returns to menu");

if (winningNumber != -1) {
	draw_text(statusX, statusY + 144, "Winner: " + string(winningNumber));
}

draw_text_ext(statusX, statusY + 174, lastSpinSummary, 280, 18);

if (brokerMode && lobbyBrowserOpen) {
	draw_set_alpha(0.76);
	draw_set_color(c_black);
	draw_rectangle(0, 0, room_width, room_height, false);
	draw_set_alpha(1);

	draw_set_color(panelColor);
	draw_roundrect(lobbyPanel.x1, lobbyPanel.y1, lobbyPanel.x2, lobbyPanel.y2, false);
	draw_set_color(lineColor);
	draw_roundrect(lobbyPanel.x1, lobbyPanel.y1, lobbyPanel.x2, lobbyPanel.y2, true);

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
	draw_text(lobbyPanel.x1 + 28, lobbyPanel.y1 + 22, "Lobby Browser");
	draw_set_color(lineColor);
	draw_text(lobbyPanel.x1 + 28, lobbyPanel.y1 + 52, "Join an existing roulette table or create a new one.");

	var entryY = lobbyPanel.y1 + 94;
	var entryH = 34;
	for (var lobbyIndex = 0; lobbyIndex < array_length(lobbyList); lobbyIndex++) {
		var lobbyEntry = lobbyList[lobbyIndex];
		var rowTop = entryY + (lobbyIndex * (entryH + 8));
		var lobbyId = rouletteStructGet(lobbyEntry, "id", "");
		var selected = lobbyId == selectedLobbyId;
		draw_set_color(selected ? merge_color(chipColor, c_white, 0.25) : feltDarkColor);
		draw_rectangle(lobbyPanel.x1 + 26, rowTop, lobbyPanel.x2 - 26, rowTop + entryH, false);
		draw_set_color(lineColor);
		draw_rectangle(lobbyPanel.x1 + 26, rowTop, lobbyPanel.x2 - 26, rowTop + entryH, true);
		draw_text(lobbyPanel.x1 + 38, rowTop + 8, rouletteStructGet(lobbyEntry, "name", "Lobby"));
		draw_text(lobbyPanel.x1 + 270, rowTop + 8, "Players: " + string(rouletteStructGet(lobbyEntry, "playerCount", 0)));
		draw_text(lobbyPanel.x1 + 430, rowTop + 8, string_upper(rouletteStructGet(lobbyEntry, "phase", "betting")));
	}

	if (array_length(lobbyList) == 0) {
		draw_set_color(lineColor);
		draw_text(lobbyPanel.x1 + 28, entryY + 8, "No lobbies yet. Create the first one.");
	}

	var createFill = point_in_rectangle(mouse_x, mouse_y, createLobbyButton.x, createLobbyButton.y, createLobbyButton.x + createLobbyButton.w, createLobbyButton.y + createLobbyButton.h) ? merge_color(chipColor, c_white, 0.2) : chipColor;
	var joinFill = point_in_rectangle(mouse_x, mouse_y, joinLobbyButton.x, joinLobbyButton.y, joinLobbyButton.x + joinLobbyButton.w, joinLobbyButton.y + joinLobbyButton.h) ? merge_color(panelColor, c_white, 0.2) : panelColor;
	var leaveFill = point_in_rectangle(mouse_x, mouse_y, leaveLobbyButton.x, leaveLobbyButton.y, leaveLobbyButton.x + leaveLobbyButton.w, leaveLobbyButton.y + leaveLobbyButton.h) ? merge_color(panelColor, c_white, 0.2) : panelColor;

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(createFill);
	draw_rectangle(createLobbyButton.x, createLobbyButton.y, createLobbyButton.x + createLobbyButton.w, createLobbyButton.y + createLobbyButton.h, false);
	draw_set_color(lineColor);
	draw_rectangle(createLobbyButton.x, createLobbyButton.y, createLobbyButton.x + createLobbyButton.w, createLobbyButton.y + createLobbyButton.h, true);
	draw_set_color(c_white);
	draw_text(createLobbyButton.x + createLobbyButton.w * 0.5, createLobbyButton.y + createLobbyButton.h * 0.5, "CREATE");

	draw_set_color(joinFill);
	draw_rectangle(joinLobbyButton.x, joinLobbyButton.y, joinLobbyButton.x + joinLobbyButton.w, joinLobbyButton.y + joinLobbyButton.h, false);
	draw_set_color(lineColor);
	draw_rectangle(joinLobbyButton.x, joinLobbyButton.y, joinLobbyButton.x + joinLobbyButton.w, joinLobbyButton.y + joinLobbyButton.h, true);
	draw_set_color(c_white);
	draw_text(joinLobbyButton.x + joinLobbyButton.w * 0.5, joinLobbyButton.y + joinLobbyButton.h * 0.5, "JOIN");

	draw_set_color(leaveFill);
	draw_rectangle(leaveLobbyButton.x, leaveLobbyButton.y, leaveLobbyButton.x + leaveLobbyButton.w, leaveLobbyButton.y + leaveLobbyButton.h, false);
	draw_set_color(lineColor);
	draw_rectangle(leaveLobbyButton.x, leaveLobbyButton.y, leaveLobbyButton.x + leaveLobbyButton.w, leaveLobbyButton.y + leaveLobbyButton.h, true);
	draw_set_color(c_white);
	draw_text(leaveLobbyButton.x + leaveLobbyButton.w * 0.5, leaveLobbyButton.y + leaveLobbyButton.h * 0.5, "LEAVE");

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(lineColor);
	if (currentLobbyId != "") {
		draw_text(lobbyPanel.x1 + 28, leaveLobbyButton.y + 52, "Current lobby: " + currentLobbyName + " (Esc closes browser)");
	} else {
		draw_text(lobbyPanel.x1 + 28, leaveLobbyButton.y + 52, "You must join or create a lobby before betting.");
	}
}

