viewResize();

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

var soloButton = { x1: room_width * 0.5 - 164, y1: room_height * 0.5 - 26, x2: room_width * 0.5 + 164, y2: room_height * 0.5 + 22 };
var showdownButton = { x1: room_width * 0.5 - 164, y1: room_height * 0.5 + 34, x2: room_width * 0.5 + 164, y2: room_height * 0.5 + 82 };

hoverSolo = point_in_rectangle(mx, my, soloButton.x1, soloButton.y1, soloButton.x2, soloButton.y2);
hoverShowdown = point_in_rectangle(mx, my, showdownButton.x1, showdownButton.y1, showdownButton.x2, showdownButton.y2);

if (state == "START") {
	if (keyboard_check_pressed(vk_escape)) room_goto(RoomArcadeLobby);
	if (mouse_check_button_pressed(mb_left) && hoverSolo) snakeRequestSoloStart(id);
	if (mouse_check_button_pressed(mb_left) && hoverShowdown) snakeRequestShowdownWatch(id);
	if (keyboard_check_pressed(ord("S"))) snakeRequestSoloStart(id);
	if (keyboard_check_pressed(ord("M"))) snakeRequestShowdownWatch(id);
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
	var headerY1 = panelY1 + 12;
	var headerY2 = headerY1 + 64;
	var primaryTop = headerY2 + 22;
	var participantsW = clamp(floor(room_width * 0.24), 260, 300);
	var participantsX = contentRight - participantsW;
	var contentW = clamp(participantsX - contentLeft - gap, 260, 680);
	var primaryW = floor((contentW - gap) * 0.5);
	var mediumW = 190;
	var buttonH = 40;
	var listX = contentLeft;
	var listY = primaryTop + buttonH + 28;
	var listW = contentW;
	var listRowH = 34;
	var betSectionY = primaryTop + 88;
	var chipRowY = betSectionY + 22;
	var chipW = floor((contentW - gap * 4) / 5);
	var chipH = 30;
	var betSpotY = chipRowY + chipH + 14;
	var betSpotW = floor((contentW - gap) * 0.5);
	var betSpotH = 94;
	var claimY = betSpotY + betSpotH + 22;
	var rematchY = claimY + 58;
	var createButton = { x1: contentLeft, y1: primaryTop, x2: contentLeft + primaryW, y2: primaryTop + buttonH };
	var joinButton = { x1: contentLeft + primaryW + gap, y1: primaryTop, x2: contentLeft + primaryW * 2 + gap, y2: primaryTop + buttonH };
	var leaveButton = { x1: contentLeft + primaryW + gap, y1: primaryTop, x2: contentLeft + primaryW * 2 + gap, y2: primaryTop + buttonH };
	var startButton = { x1: contentLeft, y1: primaryTop, x2: contentLeft + primaryW, y2: primaryTop + buttonH };
	var betP1Button = { x1: contentLeft, y1: betSpotY, x2: contentLeft + betSpotW, y2: betSpotY + betSpotH };
	var betP2Button = { x1: contentLeft + betSpotW + gap, y1: betSpotY, x2: contentLeft + betSpotW * 2 + gap, y2: betSpotY + betSpotH };
	var claimButton = { x1: contentLeft, y1: claimY, x2: contentLeft + 270, y2: claimY + buttonH };
	var rematchYesButton = { x1: contentLeft, y1: rematchY, x2: contentLeft + mediumW, y2: rematchY + buttonH };
	var rematchNoButton = { x1: contentLeft + mediumW + gap, y1: rematchY, x2: contentLeft + mediumW * 2 + gap, y2: rematchY + buttonH };
	var nextChallengerButton = { x1: contentLeft + mediumW * 2 + gap * 2, y1: rematchY, x2: contentLeft + mediumW * 2 + gap * 2 + 220, y2: rematchY + buttonH };
	var betChip1Button = { x1: contentLeft, y1: chipRowY, x2: contentLeft + chipW, y2: chipRowY + chipH };
	var betChip5Button = { x1: contentLeft + (chipW + gap) * 1, y1: chipRowY, x2: contentLeft + (chipW + gap) * 1 + chipW, y2: chipRowY + chipH };
	var betChip10Button = { x1: contentLeft + (chipW + gap) * 2, y1: chipRowY, x2: contentLeft + (chipW + gap) * 2 + chipW, y2: chipRowY + chipH };
	var betChip25Button = { x1: contentLeft + (chipW + gap) * 3, y1: chipRowY, x2: contentLeft + (chipW + gap) * 3 + chipW, y2: chipRowY + chipH };
	var betChip100Button = { x1: contentLeft + (chipW + gap) * 4, y1: chipRowY, x2: contentLeft + (chipW + gap) * 4 + chipW, y2: chipRowY + chipH };

	hoverCreate = point_in_rectangle(mx, my, createButton.x1, createButton.y1, createButton.x2, createButton.y2);
	hoverJoin = point_in_rectangle(mx, my, joinButton.x1, joinButton.y1, joinButton.x2, joinButton.y2);
	hoverLeave = point_in_rectangle(mx, my, leaveButton.x1, leaveButton.y1, leaveButton.x2, leaveButton.y2);
	hoverStartRace = point_in_rectangle(mx, my, startButton.x1, startButton.y1, startButton.x2, startButton.y2);
	hoverBet1 = point_in_rectangle(mx, my, betChip1Button.x1, betChip1Button.y1, betChip1Button.x2, betChip1Button.y2);
	hoverBet5 = point_in_rectangle(mx, my, betChip5Button.x1, betChip5Button.y1, betChip5Button.x2, betChip5Button.y2);
	hoverBet10 = point_in_rectangle(mx, my, betChip10Button.x1, betChip10Button.y1, betChip10Button.x2, betChip10Button.y2);
	hoverBet25 = point_in_rectangle(mx, my, betChip25Button.x1, betChip25Button.y1, betChip25Button.x2, betChip25Button.y2);
	hoverBet100 = point_in_rectangle(mx, my, betChip100Button.x1, betChip100Button.y1, betChip100Button.x2, betChip100Button.y2);
	hoverBetP1 = point_in_rectangle(mx, my, betP1Button.x1, betP1Button.y1, betP1Button.x2, betP1Button.y2);
	hoverBetP2 = point_in_rectangle(mx, my, betP2Button.x1, betP2Button.y1, betP2Button.x2, betP2Button.y2);
	hoverClaim = point_in_rectangle(mx, my, claimButton.x1, claimButton.y1, claimButton.x2, claimButton.y2);
	hoverRematchYes = point_in_rectangle(mx, my, rematchYesButton.x1, rematchYesButton.y1, rematchYesButton.x2, rematchYesButton.y2);
	hoverRematchNo = point_in_rectangle(mx, my, rematchNoButton.x1, rematchNoButton.y1, rematchNoButton.x2, rematchNoButton.y2);
	hoverNextChallenger = point_in_rectangle(mx, my, nextChallengerButton.x1, nextChallengerButton.y1, nextChallengerButton.x2, nextChallengerButton.y2);

	if (keyboard_check_pressed(vk_escape)) {
		state = "START";
		mode = "menu";
		statusText = "Choose Solo or Showdown.";
		exit;
	}

	if (snakeBrokerConnected) {
		var inCurrentLobby = showdownCurrentLobbyId != "";
		if (!inCurrentLobby) {
			for (var i = 0; i < min(6, array_length(showdownLobbyList)); i++) {
				var rowY = listY + i * (listRowH + 8);
				if (mouse_check_button_pressed(mb_left) && point_in_rectangle(mx, my, listX, rowY, listX + listW, rowY + listRowH)) {
					showdownSelectedLobbyId = rouletteStructGet(showdownLobbyList[i], "id", showdownSelectedLobbyId);
				}
			}
			if (mouse_check_button_pressed(mb_left) && hoverCreate) rouletteSendJson(snakeBrokerSocket, { type: "table_create_lobby", game: showdownGameKey });
			if (mouse_check_button_pressed(mb_left) && hoverJoin && showdownSelectedLobbyId != "") rouletteSendJson(snakeBrokerSocket, { type: "table_join_lobby", game: showdownGameKey, lobbyId: showdownSelectedLobbyId });
		}
		if (inCurrentLobby) {
			if (mouse_check_button_pressed(mb_left) && hoverLeave) rouletteSendJson(snakeBrokerSocket, { type: "table_leave_lobby", game: showdownGameKey });
			if (mouse_check_button_pressed(mb_left) && hoverStartRace && showdownRole == "racer") rouletteSendJson(snakeBrokerSocket, { type: "table_snake_start" });
			if (mouse_check_button_pressed(mb_left) && hoverClaim && showdownPromptOpen && showdownRole == "spectator") rouletteSendJson(snakeBrokerSocket, { type: "table_snake_claim_player2" });

			if (mouse_check_button_pressed(mb_left) && hoverBet1) selectedBetAmount = 1;
			if (mouse_check_button_pressed(mb_left) && hoverBet5) selectedBetAmount = 5;
			if (mouse_check_button_pressed(mb_left) && hoverBet10) selectedBetAmount = 10;
			if (mouse_check_button_pressed(mb_left) && hoverBet25) selectedBetAmount = 25;
			if (mouse_check_button_pressed(mb_left) && hoverBet100) selectedBetAmount = 100;

			if (showdownRole == "spectator" && showdownAllowBets) {
				if (mouse_check_button_pressed(mb_left) && (hoverBetP1 || hoverBetP2)) {
					selectedBetTarget = hoverBetP1 ? 1 : 2;
					var targetId = selectedBetTarget == 1 ? showdownPlayer1Id : showdownPlayer2Id;
					if (targetId != "") {
						rouletteSendJson(snakeBrokerSocket, { type: "table_snake_place_bet", targetPlayerId: targetId, amount: selectedBetAmount });
						statusText = "[SGC] Adding " + string(selectedBetAmount) + " on " + (selectedBetTarget == 1 ? showdownP1Name : showdownP2Name) + ".";
					} else {
						statusText = "[SGC] No racer in that seat yet.";
					}
				}
			}

			if (mouse_check_button_pressed(mb_left) && hoverRematchYes && showdownRole == "racer" && showdownState == "showdown") rouletteSendJson(snakeBrokerSocket, { type: "table_snake_vote_rematch", accept: true });
			if (mouse_check_button_pressed(mb_left) && hoverRematchNo && showdownRole == "racer" && showdownState == "showdown") rouletteSendJson(snakeBrokerSocket, { type: "table_snake_vote_rematch", accept: false });
			if (mouse_check_button_pressed(mb_left) && hoverNextChallenger && showdownRole == "racer" && showdownState == "showdown") rouletteSendJson(snakeBrokerSocket, { type: "table_snake_next_challenger" });
		}
	}
	exit;
}

if (state == "SHOWDOWN_WATCH") {
	if (keyboard_check_pressed(vk_escape) && showdownState != "racing") {
		state = "SHOWDOWN_LOBBY";
		statusText = showdownSummary;
	}
	exit;
}

if (state == "GAMEOVER") {
	if (mode == "solo") {
		if (!payoutSettled) {
			lastRunPayout = floor(max(0, snakeScore) * scoreToSgcRate);
			runNet = lastRunPayout - entryCost;
			if (snakeScore > global.snakeHighScore) global.snakeHighScore = snakeScore;
			if (snakeBrokerConnected) {
				soloSettlePending = true;
				rouletteSendJson(snakeBrokerSocket, {
					type: "snake_single_settle",
					score: snakeScore,
					length: snakeLength,
					distance: snakeDistance(id)
				});
			} else {
				global.sgcArcadeBalance += lastRunPayout;
			}
			statusText = "[SGC] Cashed out " + string(lastRunPayout) + " coins.";
			payoutSettled = true;
		}
		if (keyboard_check_pressed(vk_anykey)) {
			state = "START";
			mode = "menu";
			statusText = "Choose Solo or Showdown.";
		}
	} else if (mode == "showdown") {
		showdownLocalFinished = true;
		if (!localRaceSubmitted && snakeBrokerConnected) {
			var finishTelemetry = snakeReadTelemetry(id);
			localRaceSubmitted = true;
			rouletteSendJson(snakeBrokerSocket, {
				type: "table_snake_finish",
				score: finishTelemetry.score,
				length: finishTelemetry.length,
				distance: finishTelemetry.distance,
				headXNorm: finishTelemetry.headXNorm,
				headYNorm: finishTelemetry.headYNorm,
				segmentPoints: finishTelemetry.segmentPoints,
				alive: finishTelemetry.alive
			});
			statusText = "Waiting for showdown result...";
		}
		state = "SHOWDOWN_WATCH";
	}
	exit;
}

if (state == "PLAYING") {
	if (keyboard_check_pressed(vk_right) && snakeDirX != -1) {
		snakeNextDirX = 1;
		snakeNextDirY = 0;
	}
	if (keyboard_check_pressed(vk_left) && snakeDirX != 1) {
		snakeNextDirX = -1;
		snakeNextDirY = 0;
	}
	if (keyboard_check_pressed(vk_down) && snakeDirY != -1) {
		snakeNextDirX = 0;
		snakeNextDirY = 1;
	}
	if (keyboard_check_pressed(vk_up) && snakeDirY != 1) {
		snakeNextDirX = 0;
		snakeNextDirY = -1;
	}

	moveTimer += 1;
	if (moveTimer >= moveDelay) {
		moveTimer = 0;
		snakeDirX = snakeNextDirX;
		snakeDirY = snakeNextDirY;

		var headX = snakeX[0];
		var headY = snakeY[0];
		var newX = headX + snakeDirX;
		var newY = headY + snakeDirY;

		if (newX < 0 || newX >= gridW || newY < 0 || newY >= gridH) {
			snakeAlive = false;
			state = "GAMEOVER";
			exit;
		}

		var cellValue = gameBoard[# newX, newY];
		var ateFood = (cellValue == 2 || cellValue == 3 || cellValue == 4);
		var foodPoints = 0;
		switch (cellValue) {
			case 2: foodPoints = 1; break;
			case 3: foodPoints = 5; break;
			case 4: foodPoints = 10; break;
		}

		var tailX = snakeX[array_length(snakeX) - 1];
		var tailY = snakeY[array_length(snakeY) - 1];
		if (gameBoard[# newX, newY] == 1 && !(newX == tailX && newY == tailY && !ateFood)) {
			snakeAlive = false;
			state = "GAMEOVER";
			exit;
		}

		array_insert(snakeX, 0, newX);
		array_insert(snakeY, 0, newY);
		gameBoard[# newX, newY] = 1;

		if (ateFood) {
			snakeScore += foodPoints;
			if (!snakeSpawnFood(id)) {
				snakeAlive = false;
				state = "GAMEOVER";
				exit;
			}
		} else {
			gameBoard[# tailX, tailY] = 0;
			array_delete(snakeX, array_length(snakeX) - 1, 1);
			array_delete(snakeY, array_length(snakeY) - 1, 1);
		}
		snakeLength = array_length(snakeX);
	}

	if (mode == "showdown" && snakeBrokerConnected) {
		progressSendCooldown += 1;
		if (progressSendCooldown >= 8) {
			progressSendCooldown = 0;
			var telemetry = snakeReadTelemetry(id);
			rouletteSendJson(snakeBrokerSocket, {
				type: "table_snake_progress",
				score: telemetry.score,
				length: telemetry.length,
				distance: telemetry.distance,
				headXNorm: telemetry.headXNorm,
				headYNorm: telemetry.headYNorm,
				segmentPoints: telemetry.segmentPoints,
				alive: telemetry.alive
			});
		}
	}
}