var mouseXPos = device_mouse_x_to_gui(0);
var mouseYPos = device_mouse_y_to_gui(0);
hoveredControl = "";

var backButton = { x: room_width - 326, y: 20, w: 128, h: 42, label: tableRoomLocked ? "Tables" : "Back" };
var mainMenuButton = { x: room_width - 178, y: 20, w: 148, h: 42, label: "Main Menu" };
var spinButton = { x: 90, y: 636, w: 190, h: 56, label: "Spin" };
var dropButton = { x: 88, y: 636, w: 190, h: 56, label: "Drop" };
var pegMinusButton = { x: 318, y: 636, w: 52, h: 56, label: "-" };
var pegPlusButton = { x: 486, y: 636, w: 52, h: 56, label: "+" };
var bjDealButton = { x: 82, y: 636, w: 142, h: 56, label: "Deal" };
var bjHitButton = { x: 242, y: 636, w: 142, h: 56, label: "Hit" };
var bjStayButton = { x: 402, y: 636, w: 142, h: 56, label: "Stay" };
var holdemDealButton = { x: 82, y: 636, w: 130, h: 56, label: "Deal" };
var holdemNextButton = { x: 228, y: 636, w: 130, h: 56, label: "Check" };
var holdemRaiseButton = { x: 374, y: 636, w: 130, h: 56, label: "Raise" };
var holdemFoldButton = { x: 520, y: 636, w: 130, h: 56, label: "Fold" };
var raceButton = { x: 84, y: 636, w: 190, h: 56, label: "Start Race" };
var joinTableButton = { x: room_width * 0.5 - 135, y: 508, w: 270, h: 60, label: "Join Table" };
var enterTableButton = { x: room_width * 0.5 - 135, y: 570, w: 270, h: 48, label: "Enter Table" };
var createTableLobbyButton = { x: room_width * 0.5 - 276, y: 508, w: 170, h: 52, label: "Create Lobby" };
var joinTableLobbyButton = { x: room_width * 0.5 - 86, y: 508, w: 170, h: 52, label: "Join Lobby" };
var leaveTableLobbyButton = { x: room_width * 0.5 + 104, y: 508, w: 170, h: 52, label: "Leave Lobby" };

if (keyboard_check_pressed(vk_escape)) {
	if (tableRoomLocked && tableMultiplayerEnabled) {
		leaveTableLobbyIfNeeded("Left the table lobby.");
	} else {
		closeTableBrokerSocket();
		room_goto(tableBackRoom);
	}
}

if (tablePointInButton(backButton, mouseXPos, mouseYPos)) {
	hoveredControl = "back";
}

if (tablePointInButton(mainMenuButton, mouseXPos, mouseYPos)) {
	hoveredControl = "main_menu";
}


if (!tableRoomLocked) {
	for (var tab = 0; tab < array_length(gameNames); tab += 1) {
		var tabButton = { x: 24 + tab * 158, y: 78, w: 148, h: 48, label: gameNames[tab] };
		if (tablePointInButton(tabButton, mouseXPos, mouseYPos)) {
			hoveredControl = "tab_" + string(tab);
			if (mouse_check_button_pressed(mb_left)) {
				selectedGame = tab;
				setTableStatus("Opened " + gameNames[tab] + ".");
			}
		}
	}
}

for (var betIndex = 0; betIndex < array_length(betOptions); betIndex += 1) {
	var chipButton = { x: 804 + betIndex * 82, y: 654, w: 64, h: 46, label: string(betOptions[betIndex]) };
	if (tablePointInButton(chipButton, mouseXPos, mouseYPos)) {
		hoveredControl = "bet_" + string(betIndex);
		if (mouse_check_button_pressed(mb_left)) {
			selectedBetIndex = betIndex;
			if (array_length(slotSeats) > 0) {
				var humanSlotSeat = slotSeats[0];
				humanSlotSeat.bet = currentBet();
				slotSeats[0] = humanSlotSeat;
			}
			if (array_length(pachinkoSeats) > 0) {
				var humanPachinkoSeat = pachinkoSeats[0];
				humanPachinkoSeat.bet = currentBet();
				pachinkoSeats[0] = humanPachinkoSeat;
			}
			if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") {
				rouletteSendJson(tableBrokerSocket, { type: "table_set_bet", amount: currentBet() });
			}
			setTableStatus("Bet set to " + string(currentBet()) + " chips.");
		}
	}
}

if (mouse_check_button_pressed(mb_left) && tablePointInButton(backButton, mouseXPos, mouseYPos)) {
	if (tableRoomLocked && tableMultiplayerEnabled) {
		leaveTableLobbyIfNeeded("Left the table lobby.");
	} else {
		closeTableBrokerSocket();
		room_goto(tableBackRoom);
	}
}

if (mouse_check_button_pressed(mb_left) && tablePointInButton(mainMenuButton, mouseXPos, mouseYPos)) {
	closeTableBrokerSocket();
	room_goto(RoomMenu);
}

if (tableLobbyOpen) {
	if (tableMultiplayerEnabled) {
		if (tablePointInButton(createTableLobbyButton, mouseXPos, mouseYPos)) hoveredControl = "create_table_lobby";
		if (tablePointInButton(joinTableLobbyButton, mouseXPos, mouseYPos)) hoveredControl = "join_table_lobby";
		if (tablePointInButton(leaveTableLobbyButton, mouseXPos, mouseYPos)) hoveredControl = "leave_table_lobby";
		if (tablePointInButton(enterTableButton, mouseXPos, mouseYPos) && tableCurrentLobbyId != "") hoveredControl = "join_table";

		for (var tableLobbyIndex = 0; tableLobbyIndex < array_length(tableLobbyList); tableLobbyIndex += 1) {
			var rowTop = 338 + tableLobbyIndex * 34;
			if (point_in_rectangle(mouseXPos, mouseYPos, room_width * 0.5 - 300, rowTop, room_width * 0.5 + 300, rowTop + 28)) {
				tableSelectedLobbyId = rouletteStructGet(tableLobbyList[tableLobbyIndex], "id", "");
			}
		}

		if (mouse_check_button_pressed(mb_left) && tableBrokerConnected) {
			if (tablePointInButton(createTableLobbyButton, mouseXPos, mouseYPos)) {
				rouletteSendJson(tableBrokerSocket, { type: "table_create_lobby", game: tableGameKey });
			}
			if (tablePointInButton(joinTableLobbyButton, mouseXPos, mouseYPos) && tableSelectedLobbyId != "") {
				rouletteSendJson(tableBrokerSocket, { type: "table_join_lobby", game: tableGameKey, lobbyId: tableSelectedLobbyId });
			}
			if (tablePointInButton(leaveTableLobbyButton, mouseXPos, mouseYPos) && tableCurrentLobbyId != "") {
				rouletteSendJson(tableBrokerSocket, { type: "table_leave_lobby", game: tableGameKey });
				resetTableLobbyState("Left the table lobby.");
			}
		}

		if (((mouse_check_button_pressed(mb_left) && tablePointInButton(enterTableButton, mouseXPos, mouseYPos)) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) && tableCurrentLobbyId != "") {
			tableLobbyOpen = false;
			setTableStatus("Joined " + tableCurrentLobbyName + ".");
		}
	} else {
		if (tablePointInButton(joinTableButton, mouseXPos, mouseYPos)) {
			hoveredControl = "join_table";
		}

		if ((mouse_check_button_pressed(mb_left) && tablePointInButton(joinTableButton, mouseXPos, mouseYPos)) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
			tableLobbyOpen = false;
			setTableStatus("Joined " + gameNames[selectedGame] + ".");
		}
	}

	exit;
}

if (!tableRoomLocked) {
	if (keyboard_check_pressed(ord("1"))) selectedGame = GAME_SLOTS;
	if (keyboard_check_pressed(ord("2"))) selectedGame = GAME_PACHINKO;
	if (keyboard_check_pressed(ord("3"))) selectedGame = GAME_BLACKJACK;
	if (keyboard_check_pressed(ord("4"))) selectedGame = GAME_HOLDEM;
	if (keyboard_check_pressed(ord("5"))) selectedGame = GAME_HORSE;
}

if (selectedGame == GAME_SLOTS && (!tableMultiplayerEnabled || !tableBrokerConnected || tableCurrentLobbyId == "")) {
	updateSlotSeats();
}

if (selectedGame == GAME_PACHINKO && (!tableMultiplayerEnabled || !tableBrokerConnected || tableCurrentLobbyId == "")) {
	updatePachinkoSeats();
}

if (horseState == "racing" && (!tableMultiplayerEnabled || !tableBrokerConnected || tableCurrentLobbyId == "")) {
	var underdog = horseUnderdog();
	for (var horse = 0; horse < 4; horse += 1) {
		var boost = (horse == underdog) ? 1 : 0;
		horsePositions[horse] += random_range(0.8, 3.8) + boost;
		if (horsePositions[horse] >= horseFinish && horseWinner < 0) {
			resolveHorseRace(horse);
		}
	}
}

if (selectedGame == GAME_SLOTS) {
	if (tablePointInButton(spinButton, mouseXPos, mouseYPos)) hoveredControl = "spin";
	if ((mouse_check_button_pressed(mb_left) && tablePointInButton(spinButton, mouseXPos, mouseYPos)) || keyboard_check_pressed(vk_space)) {
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") {
			rouletteSendJson(tableBrokerSocket, { type: "table_spin" });
		} else {
			startSlots();
		}
	}
}

if (selectedGame == GAME_PACHINKO) {
	if (tablePointInButton(dropButton, mouseXPos, mouseYPos)) hoveredControl = "drop";
	if (tablePointInButton(pegMinusButton, mouseXPos, mouseYPos)) hoveredControl = "peg_minus";
	if (tablePointInButton(pegPlusButton, mouseXPos, mouseYPos)) hoveredControl = "peg_plus";
	var humanPachinko = pachinkoSeats[0];
	if (mouse_check_button_pressed(mb_left) && tablePointInButton(pegMinusButton, mouseXPos, mouseYPos) && !humanPachinko.running) {
		humanPachinko.guess = max(1, humanPachinko.guess - 1);
		pachinkoGuess = humanPachinko.guess;
		pachinkoSeats[0] = humanPachinko;
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") rouletteSendJson(tableBrokerSocket, { type: "table_set_peg", peg: pachinkoGuess });
		setTableStatus("Pachinko peg set to " + string(pachinkoGuess) + ".");
	}
	if (mouse_check_button_pressed(mb_left) && tablePointInButton(pegPlusButton, mouseXPos, mouseYPos) && !humanPachinko.running) {
		humanPachinko.guess = min(10, humanPachinko.guess + 1);
		pachinkoGuess = humanPachinko.guess;
		pachinkoSeats[0] = humanPachinko;
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") rouletteSendJson(tableBrokerSocket, { type: "table_set_peg", peg: pachinkoGuess });
		setTableStatus("Pachinko peg set to " + string(pachinkoGuess) + ".");
	}
	if ((mouse_check_button_pressed(mb_left) && tablePointInButton(dropButton, mouseXPos, mouseYPos)) || keyboard_check_pressed(vk_space)) {
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") {
			rouletteSendJson(tableBrokerSocket, { type: "table_drop" });
		} else {
			startPachinko();
		}
	}
}

if (selectedGame == GAME_BLACKJACK) {
	if (tablePointInButton(bjDealButton, mouseXPos, mouseYPos)) hoveredControl = "bj_deal";
	if (tablePointInButton(bjHitButton, mouseXPos, mouseYPos)) hoveredControl = "bj_hit";
	if (tablePointInButton(bjStayButton, mouseXPos, mouseYPos)) hoveredControl = "bj_stay";
	if (mouse_check_button_pressed(mb_left) && tablePointInButton(bjDealButton, mouseXPos, mouseYPos)) {
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") rouletteSendJson(tableBrokerSocket, { type: "table_blackjack_deal" });
		else startBlackjack();
	}
	if (mouse_check_button_pressed(mb_left) && tablePointInButton(bjHitButton, mouseXPos, mouseYPos)) {
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") rouletteSendJson(tableBrokerSocket, { type: "table_blackjack_hit" });
		else blackjackHit();
	}
	if (mouse_check_button_pressed(mb_left) && tablePointInButton(bjStayButton, mouseXPos, mouseYPos)) {
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") rouletteSendJson(tableBrokerSocket, { type: "table_blackjack_stay" });
		else resolveBlackjack();
	}
	if (keyboard_check_pressed(vk_space) && bjPhase != "playing") {
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") rouletteSendJson(tableBrokerSocket, { type: "table_blackjack_deal" });
		else startBlackjack();
	}
	if (keyboard_check_pressed(ord("H"))) {
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") rouletteSendJson(tableBrokerSocket, { type: "table_blackjack_hit" });
		else blackjackHit();
	}
	if (keyboard_check_pressed(ord("S"))) {
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") rouletteSendJson(tableBrokerSocket, { type: "table_blackjack_stay" });
		else if (bjPhase == "playing") resolveBlackjack();
	}
}

if (selectedGame == GAME_HOLDEM) {
	if (tablePointInButton(holdemDealButton, mouseXPos, mouseYPos)) hoveredControl = "holdem_deal";
	if (tablePointInButton(holdemNextButton, mouseXPos, mouseYPos)) hoveredControl = "holdem_next";
	if (tablePointInButton(holdemRaiseButton, mouseXPos, mouseYPos)) hoveredControl = "holdem_raise";
	if (tablePointInButton(holdemFoldButton, mouseXPos, mouseYPos)) hoveredControl = "holdem_fold";
	if (mouse_check_button_pressed(mb_left) && tablePointInButton(holdemDealButton, mouseXPos, mouseYPos)) {
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") rouletteSendJson(tableBrokerSocket, { type: "table_holdem_deal" });
		else startHoldem();
	}
	if (mouse_check_button_pressed(mb_left) && tablePointInButton(holdemNextButton, mouseXPos, mouseYPos)) {
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") rouletteSendJson(tableBrokerSocket, { type: "table_holdem_action", action: "check" });
		else holdemAdvance();
	}
	if (mouse_check_button_pressed(mb_left) && tablePointInButton(holdemRaiseButton, mouseXPos, mouseYPos)) {
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") rouletteSendJson(tableBrokerSocket, { type: "table_holdem_action", action: "raise" });
		else holdemRaise();
	}
	if (mouse_check_button_pressed(mb_left) && tablePointInButton(holdemFoldButton, mouseXPos, mouseYPos)) {
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") rouletteSendJson(tableBrokerSocket, { type: "table_holdem_action", action: "fold" });
		else holdemFold();
	}
	if (keyboard_check_pressed(vk_space) && (holdemPhase == "idle" || holdemPhase == "done")) {
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") rouletteSendJson(tableBrokerSocket, { type: "table_holdem_deal" });
		else startHoldem();
	}
	if (keyboard_check_pressed(vk_enter)) {
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") rouletteSendJson(tableBrokerSocket, { type: "table_holdem_action", action: "check" });
		else holdemAdvance();
	}
	if (keyboard_check_pressed(ord("R"))) {
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") rouletteSendJson(tableBrokerSocket, { type: "table_holdem_action", action: "raise" });
		else holdemRaise();
	}
	if (keyboard_check_pressed(ord("F"))) {
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") rouletteSendJson(tableBrokerSocket, { type: "table_holdem_action", action: "fold" });
		else holdemFold();
	}
}

if (selectedGame == GAME_HORSE) {
	if (tablePointInButton(raceButton, mouseXPos, mouseYPos)) hoveredControl = "race";
	for (var h = 0; h < 4; h += 1) {
		var horseButton = { x: 340 + h * 88, y: 636, w: 68, h: 56, label: horseNames[h] };
		if (tablePointInButton(horseButton, mouseXPos, mouseYPos)) {
			hoveredControl = "horse_" + string(h);
			if (mouse_check_button_pressed(mb_left) && horseState != "racing") {
				horseChoice = h;
				if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") {
					rouletteSendJson(tableBrokerSocket, { type: "table_set_horse", horse: h });
				} else {
					setTableStatus("Picked Horse " + horseNames[h] + ".");
				}
			}
		}
	}
	if ((mouse_check_button_pressed(mb_left) && tablePointInButton(raceButton, mouseXPos, mouseYPos)) || keyboard_check_pressed(vk_space)) {
		if (tableMultiplayerEnabled && tableBrokerConnected && tableCurrentLobbyId != "") {
			if (tableIsHost) rouletteSendJson(tableBrokerSocket, { type: "table_horse_start" });
			else setTableStatus("Only lobby host can start races.");
		} else {
			startHorseRace();
		}
	}
}