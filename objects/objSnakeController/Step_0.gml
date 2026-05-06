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
	var panelY1 = 120;
	var panelX2 = room_width - 16;
	var listX = panelX1 + 18;
	var listW = panelX2 - panelX1 - 36;
	var rowH = 36;
	var listY = panelY1 + 72;
	var createButton = { x1: panelX1 + 18, y1: panelY1 + 14, x2: panelX1 + 210, y2: panelY1 + 52 };
	var joinButton = { x1: panelX1 + 222, y1: panelY1 + 14, x2: panelX1 + 414, y2: panelY1 + 52 };
	var leaveButton = { x1: panelX1 + 426, y1: panelY1 + 14, x2: panelX1 + 618, y2: panelY1 + 52 };
	var startButton = { x1: panelX1 + 630, y1: panelY1 + 14, x2: panelX1 + 822, y2: panelY1 + 52 };
	var betY = panelY1 + 330;
	var chipW = 88;
	var chipGap = 10;
	var betP1Button = { x1: panelX1 + 18, y1: betY + 54, x2: panelX1 + 280, y2: betY + 118 };
	var betP2Button = { x1: panelX1 + 296, y1: betY + 54, x2: panelX1 + 558, y2: betY + 118 };
	var claimButton = { x1: panelX1 + 18, y1: betY + 132, x2: panelX1 + 280, y2: betY + 170 };
	var rematchYesButton = { x1: panelX1 + 18, y1: betY + 184, x2: panelX1 + 210, y2: betY + 222 };
	var rematchNoButton = { x1: panelX1 + 222, y1: betY + 184, x2: panelX1 + 414, y2: betY + 222 };
	var nextChallengerButton = { x1: panelX1 + 426, y1: betY + 184, x2: panelX1 + 680, y2: betY + 222 };

	hoverCreate = point_in_rectangle(mx, my, createButton.x1, createButton.y1, createButton.x2, createButton.y2);
	hoverJoin = point_in_rectangle(mx, my, joinButton.x1, joinButton.y1, joinButton.x2, joinButton.y2);
	hoverLeave = point_in_rectangle(mx, my, leaveButton.x1, leaveButton.y1, leaveButton.x2, leaveButton.y2);
	hoverStartRace = point_in_rectangle(mx, my, startButton.x1, startButton.y1, startButton.x2, startButton.y2);
	hoverBet1 = point_in_rectangle(mx, my, panelX1 + 18, betY + 12, panelX1 + 18 + chipW, betY + 42);
	hoverBet5 = point_in_rectangle(mx, my, panelX1 + 18 + (chipW + chipGap), betY + 12, panelX1 + 18 + (chipW + chipGap) + chipW, betY + 42);
	hoverBet10 = point_in_rectangle(mx, my, panelX1 + 18 + (chipW + chipGap) * 2, betY + 12, panelX1 + 18 + (chipW + chipGap) * 2 + chipW, betY + 42);
	hoverBet25 = point_in_rectangle(mx, my, panelX1 + 18 + (chipW + chipGap) * 3, betY + 12, panelX1 + 18 + (chipW + chipGap) * 3 + chipW, betY + 42);
	hoverBet100 = point_in_rectangle(mx, my, panelX1 + 18 + (chipW + chipGap) * 4, betY + 12, panelX1 + 18 + (chipW + chipGap) * 4 + chipW, betY + 42);
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
				var rowY = listY + i * (rowH + 8);
				if (mouse_check_button_pressed(mb_left) && point_in_rectangle(mx, my, listX, rowY, listX + listW, rowY + rowH)) {
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
			if (!spawn_food(gameBoard, gridW, gridH)) {
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
				alive: telemetry.alive
			});
		}
	}
}