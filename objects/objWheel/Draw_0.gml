// Roulette table renderer.
// Micro-adjust here: table readability, chip legibility, and panel/widget placement.
draw_clear_alpha(make_color_rgb(5, 6, 10), 1);

var cx = VIEW_W * 0.8;
var cy = VIEW_H * 0.5;
var displayBallAngle = ((ballAngle mod 360) + 360) mod 360;
var bx = cx + lengthdir_x(ballRadius, displayBallAngle);
var by = cy + lengthdir_y(ballRadius, displayBallAngle);

draw_set_color(make_color_rgb(5, 6, 10));
draw_rectangle(0, 0, VIEW_W, VIEW_H, false);

var brokerMode = multiplayerEnabled && brokerConnected;

if (multiplayerEnabled && rouletteLobbyOpen) {
	var mouseXPos = device_mouse_x_to_gui(0);
	var mouseYPos = device_mouse_y_to_gui(0);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(lineColor);
	draw_line(0, 36, VIEW_W, 36);
	draw_text(18, 12, "Roulette // TABLE NODE");
	draw_text(210, 12, "[SGC] balance: " + string(bankroll) + " chips");

	draw_set_color(panelColor);
	draw_rectangle(lobbyButton.x, lobbyButton.y, lobbyButton.x + lobbyButton.w, lobbyButton.y + lobbyButton.h, false);
	draw_rectangle(menuButton.x, menuButton.y, menuButton.x + menuButton.w, menuButton.y + menuButton.h, false);
	draw_set_color(lineColor);
	draw_rectangle(lobbyButton.x, lobbyButton.y, lobbyButton.x + lobbyButton.w, lobbyButton.y + lobbyButton.h, true);
	draw_rectangle(menuButton.x, menuButton.y, menuButton.x + menuButton.w, menuButton.y + menuButton.h, true);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_text(lobbyButton.x + lobbyButton.w * 0.5, lobbyButton.y + lobbyButton.h * 0.5, "Tables");
	draw_text(menuButton.x + menuButton.w * 0.5, menuButton.y + menuButton.h * 0.5, "Main Menu");

	draw_set_color(panelColor);
	draw_roundrect(210, 178, VIEW_W - 210, 594, false);
	draw_set_color(lineColor);
	draw_roundrect(210, 178, VIEW_W - 210, 594, true);

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_text(VIEW_W * 0.5, 250, "Roulette Lobby");
	draw_set_color(lineColor);
	draw_text(VIEW_W * 0.5, 304, "> TABLE LOBBY // SGC.WTF");
	draw_text(VIEW_W * 0.5, 346, "Balance: " + string(bankroll) + " chips");
	draw_text(VIEW_W * 0.5, 386, "Broker: " + brokerStatus + "  |  Lobby: " + currentLobbyName);

	var listLeft = VIEW_W * 0.5 - 300;
	var listTop = 338;
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	if (currentLobbyId == "") {
		draw_set_color(lineColor);
		draw_text(listLeft, listTop - 26, "> AVAILABLE LOBBIES");
		for (var lobbyIndex = 0; lobbyIndex < min(4, array_length(lobbyList)); lobbyIndex += 1) {
			var lobbyEntry = lobbyList[lobbyIndex];
			var rowTop = listTop + lobbyIndex * 34;
			var lobbyId = rouletteStructGet(lobbyEntry, "id", "");
			var rowSelected = lobbyId == selectedLobbyId;
			draw_set_color(rowSelected ? make_color_rgb(46, 33, 58) : make_color_rgb(12, 14, 24));
			draw_rectangle(listLeft, rowTop, listLeft + 600, rowTop + 28, false);
			draw_set_color(rowSelected ? chipColor : lineColor);
			draw_rectangle(listLeft, rowTop, listLeft + 600, rowTop + 28, true);
			draw_set_color(c_white);
			draw_text(listLeft + 12, rowTop + 7, rouletteStructGet(lobbyEntry, "name", "Lobby"));
			draw_set_color(lineColor);
			draw_text(listLeft + 390, rowTop + 7, "Players " + string(rouletteStructGet(lobbyEntry, "playerCount", 0)));
		}
		if (array_length(lobbyList) == 0) {
			draw_set_color(lineColor);
			draw_text(listLeft, listTop + 8, "No lobbies yet. Create one to open seats.");
		}
	} else {
		draw_set_halign(fa_center);
		draw_set_color(lineColor);
		draw_text(VIEW_W * 0.5, 416, "You are seated. Enter the table to play; leave only while your game is idle.");
	}

	var canLobbyInteract = brokerConnected;
	var createFill = (canLobbyInteract && point_in_rectangle(mouseXPos, mouseYPos, createLobbyButton.x, createLobbyButton.y, createLobbyButton.x + createLobbyButton.w, createLobbyButton.y + createLobbyButton.h)) ? merge_color(chipColor, c_white, 0.2) : panelColor;
	var joinFill = (canLobbyInteract && point_in_rectangle(mouseXPos, mouseYPos, joinLobbyButton.x, joinLobbyButton.y, joinLobbyButton.x + joinLobbyButton.w, joinLobbyButton.y + joinLobbyButton.h)) ? merge_color(panelColor, c_white, 0.2) : panelColor;
	var leaveFill = (canLobbyInteract && point_in_rectangle(mouseXPos, mouseYPos, leaveLobbyButton.x, leaveLobbyButton.y, leaveLobbyButton.x + leaveLobbyButton.w, leaveLobbyButton.y + leaveLobbyButton.h)) ? merge_color(panelColor, c_white, 0.2) : panelColor;

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(createFill);
	draw_rectangle(createLobbyButton.x, createLobbyButton.y, createLobbyButton.x + createLobbyButton.w, createLobbyButton.y + createLobbyButton.h, false);
	draw_set_color(lineColor);
	draw_rectangle(createLobbyButton.x, createLobbyButton.y, createLobbyButton.x + createLobbyButton.w, createLobbyButton.y + createLobbyButton.h, true);
	draw_set_color(c_white);
	draw_text(createLobbyButton.x + createLobbyButton.w * 0.5, createLobbyButton.y + createLobbyButton.h * 0.5, "Create Lobby");

	draw_set_color(joinFill);
	draw_rectangle(joinLobbyButton.x, joinLobbyButton.y, joinLobbyButton.x + joinLobbyButton.w, joinLobbyButton.y + joinLobbyButton.h, false);
	draw_set_color(lineColor);
	draw_rectangle(joinLobbyButton.x, joinLobbyButton.y, joinLobbyButton.x + joinLobbyButton.w, joinLobbyButton.y + joinLobbyButton.h, true);
	draw_set_color(c_white);
	draw_text(joinLobbyButton.x + joinLobbyButton.w * 0.5, joinLobbyButton.y + joinLobbyButton.h * 0.5, "Join Lobby");

	draw_set_color(leaveFill);
	draw_rectangle(leaveLobbyButton.x, leaveLobbyButton.y, leaveLobbyButton.x + leaveLobbyButton.w, leaveLobbyButton.y + leaveLobbyButton.h, false);
	draw_set_color(lineColor);
	draw_rectangle(leaveLobbyButton.x, leaveLobbyButton.y, leaveLobbyButton.x + leaveLobbyButton.w, leaveLobbyButton.y + leaveLobbyButton.h, true);
	draw_set_color(c_white);
	draw_text(leaveLobbyButton.x + leaveLobbyButton.w * 0.5, leaveLobbyButton.y + leaveLobbyButton.h * 0.5, "Leave Lobby");

	if (currentLobbyId != "") {
		var enterFill = point_in_rectangle(mouseXPos, mouseYPos, enterLobbyButton.x, enterLobbyButton.y, enterLobbyButton.x + enterLobbyButton.w, enterLobbyButton.y + enterLobbyButton.h) ? merge_color(chipColor, c_white, 0.2) : chipColor;
		draw_set_color(enterFill);
		draw_rectangle(enterLobbyButton.x, enterLobbyButton.y, enterLobbyButton.x + enterLobbyButton.w, enterLobbyButton.y + enterLobbyButton.h, false);
		draw_set_color(lineColor);
		draw_rectangle(enterLobbyButton.x, enterLobbyButton.y, enterLobbyButton.x + enterLobbyButton.w, enterLobbyButton.y + enterLobbyButton.h, true);
		draw_set_color(c_white);
		draw_text(enterLobbyButton.x + enterLobbyButton.w * 0.5, enterLobbyButton.y + enterLobbyButton.h * 0.5, "Enter Table");
	}

	exit;
}

draw_set_alpha(0.22);
draw_set_color(c_black);
draw_circle(cx + 10, cy + 14, 196, false);
draw_set_alpha(1);

draw_sprite_ext(sprWheel,0,cx, cy, 1, 1, rotation, c_white,1);
draw_circle_color(bx, by, 16, c_white, c_silver, false);

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

// Build a player list snapshot for the panel.
// In local mode we show just you, and in broker mode we use server-provided player structs.
var roster = activePlayers;
if (!is_array(roster)) roster = [];
if (!brokerMode) {
	roster = [{
		playerId: brokerPlayerId,
		name: playerName,
		bankroll: bankroll,
		wager: rouletteGetTotalBet(betAreas),
		signedIn: variable_global_exists("sgcSignedIn") ? global.sgcSignedIn : false
	}];
}

var rosterPanelX = panelX;
var rosterPanelY = panelY + 288;
var rosterPanelW = 432;
var rosterPanelH = 220;
draw_set_color(panelColor);
draw_rectangle(rosterPanelX, rosterPanelY, rosterPanelX + rosterPanelW, rosterPanelY + rosterPanelH, false);
draw_set_color(lineColor);
draw_rectangle(rosterPanelX, rosterPanelY, rosterPanelX + rosterPanelW, rosterPanelY + rosterPanelH, true);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_text(rosterPanelX + 10, rosterPanelY + 10, "ACTIVE PLAYERS");
draw_set_color(lineColor);
draw_text(rosterPanelX + 10, rosterPanelY + 30, "Name");
draw_text(rosterPanelX + 188, rosterPanelY + 30, "Bankroll");
draw_text(rosterPanelX + 296, rosterPanelY + 30, "Wager");
draw_text(rosterPanelX + 380, rosterPanelY + 30, "State");

if (array_length(roster) == 0) {
	draw_set_color(make_color_rgb(180, 187, 200));
	draw_text(rosterPanelX + 10, rosterPanelY + 56, "No active players in this lobby.");
} else {
	var rosterMaxRows = 7;
	for (var rosterIndex = 0; rosterIndex < min(array_length(roster), rosterMaxRows); rosterIndex += 1) {
		var row = roster[rosterIndex];
		var rowTop = rosterPanelY + 54 + (rosterIndex * 22);
		var rowName = rouletteStructGet(row, "name", "Player");
		var rowBankroll = rouletteStructGet(row, "bankroll", 0);
		var rowWager = rouletteStructGet(row, "wager", 0);
		var rowSignedIn = rouletteStructGet(row, "signedIn", false);
		var rowId = rouletteStructGet(row, "playerId", "");
		var isSelf = (rowId != "" && rowId == brokerPlayerId);
		draw_set_color(isSelf ? merge_color(lineColor, c_white, 0.15) : make_color_rgb(180, 187, 200));
		draw_text(rosterPanelX + 10, rowTop, (isSelf ? "> " : "") + string_copy(rowName, 1, 18));
		draw_text(rosterPanelX + 188, rowTop, "$" + string(rowBankroll));
		draw_text(rosterPanelX + 296, rowTop, "$" + string(rowWager));
		draw_text(rosterPanelX + 380, rowTop, rowSignedIn ? "SGC" : "Guest");
	}
	if (array_length(roster) > rosterMaxRows) {
		draw_set_color(make_color_rgb(180, 187, 200));
		draw_text(rosterPanelX + 10, rosterPanelY + rosterPanelH - 24, "+" + string(array_length(roster) - rosterMaxRows) + " more...");
	}
}

