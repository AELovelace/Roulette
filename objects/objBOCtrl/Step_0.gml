viewResize();

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

var panelX1 = 16;
var panelY1 = 86;
var panelX2 = room_width - 16;
var panelY2 = room_height - 24;
var lobbyLeft = panelX1 + 18;
var lobbyGap = 14;
var headerY1 = panelY1 + 12;
var headerY2 = headerY1 + 64;
var lobbyTop = headerY2 + 22;
var participantsW = clamp(floor(room_width * 0.24), 260, 300);
var participantsX = panelX2 - 18 - participantsW;
var contentW = clamp(participantsX - lobbyLeft - lobbyGap, 260, 680);
var primaryButtonW = floor((contentW - lobbyGap) * 0.5);
var mediumButtonW = 190;
var buttonH = 40;
var listX = lobbyLeft;
var listY = lobbyTop + buttonH + 28;
var listW = contentW;
var listRowH = 34;
var betSectionY = lobbyTop + 88;
var chipRowY = betSectionY + 22;
var chipW = floor((contentW - lobbyGap * 4) / 5);
var chipH = 30;
var betSpotY = chipRowY + chipH + 14;
var betSpotW = floor((contentW - lobbyGap) * 0.5);
var betSpotH = 94;
var claimY = betSpotY + betSpotH + 22;
var rematchY = claimY + 58;

var soloButton = { x1: room_width * 0.5 - 164, y1: room_height * 0.5 - 26, x2: room_width * 0.5 + 164, y2: room_height * 0.5 + 22 };
var showdownButton = { x1: room_width * 0.5 - 164, y1: room_height * 0.5 + 34, x2: room_width * 0.5 + 164, y2: room_height * 0.5 + 82 };
var createLobbyButton = { x1: lobbyLeft, y1: lobbyTop, x2: lobbyLeft + primaryButtonW, y2: lobbyTop + buttonH };
var joinLobbyButton = { x1: lobbyLeft + primaryButtonW + lobbyGap, y1: lobbyTop, x2: lobbyLeft + primaryButtonW * 2 + lobbyGap, y2: lobbyTop + buttonH };
var leaveLobbyButton = { x1: lobbyLeft + primaryButtonW + lobbyGap, y1: lobbyTop, x2: lobbyLeft + primaryButtonW * 2 + lobbyGap, y2: lobbyTop + buttonH };
var startRaceButton = { x1: lobbyLeft, y1: lobbyTop, x2: lobbyLeft + primaryButtonW, y2: lobbyTop + buttonH };
var betChip1Button = { x1: lobbyLeft, y1: chipRowY, x2: lobbyLeft + chipW, y2: chipRowY + chipH };
var betChip5Button = { x1: lobbyLeft + (chipW + lobbyGap) * 1, y1: chipRowY, x2: lobbyLeft + (chipW + lobbyGap) * 1 + chipW, y2: chipRowY + chipH };
var betChip10Button = { x1: lobbyLeft + (chipW + lobbyGap) * 2, y1: chipRowY, x2: lobbyLeft + (chipW + lobbyGap) * 2 + chipW, y2: chipRowY + chipH };
var betChip25Button = { x1: lobbyLeft + (chipW + lobbyGap) * 3, y1: chipRowY, x2: lobbyLeft + (chipW + lobbyGap) * 3 + chipW, y2: chipRowY + chipH };
var betChip100Button = { x1: lobbyLeft + (chipW + lobbyGap) * 4, y1: chipRowY, x2: lobbyLeft + (chipW + lobbyGap) * 4 + chipW, y2: chipRowY + chipH };
var betP1Button = { x1: lobbyLeft, y1: betSpotY, x2: lobbyLeft + betSpotW, y2: betSpotY + betSpotH };
var betP2Button = { x1: lobbyLeft + betSpotW + lobbyGap, y1: betSpotY, x2: lobbyLeft + betSpotW * 2 + lobbyGap, y2: betSpotY + betSpotH };
var claimButton = { x1: lobbyLeft, y1: claimY, x2: lobbyLeft + 270, y2: claimY + buttonH };
var rematchYesButton = { x1: lobbyLeft, y1: rematchY, x2: lobbyLeft + mediumButtonW, y2: rematchY + buttonH };
var rematchNoButton = { x1: lobbyLeft + mediumButtonW + lobbyGap, y1: rematchY, x2: lobbyLeft + mediumButtonW * 2 + lobbyGap, y2: rematchY + buttonH };
var nextChallengerButton = { x1: lobbyLeft + mediumButtonW * 2 + lobbyGap * 2, y1: rematchY, x2: lobbyLeft + mediumButtonW * 2 + lobbyGap * 2 + 220, y2: rematchY + buttonH };

hoverSolo = point_in_rectangle(mx, my, soloButton.x1, soloButton.y1, soloButton.x2, soloButton.y2);
hoverShowdown = point_in_rectangle(mx, my, showdownButton.x1, showdownButton.y1, showdownButton.x2, showdownButton.y2);
hoverCreate = point_in_rectangle(mx, my, createLobbyButton.x1, createLobbyButton.y1, createLobbyButton.x2, createLobbyButton.y2);
hoverJoin = point_in_rectangle(mx, my, joinLobbyButton.x1, joinLobbyButton.y1, joinLobbyButton.x2, joinLobbyButton.y2);
hoverLeave = point_in_rectangle(mx, my, leaveLobbyButton.x1, leaveLobbyButton.y1, leaveLobbyButton.x2, leaveLobbyButton.y2);
hoverStartRace = point_in_rectangle(mx, my, startRaceButton.x1, startRaceButton.y1, startRaceButton.x2, startRaceButton.y2);
hoverClaim = point_in_rectangle(mx, my, claimButton.x1, claimButton.y1, claimButton.x2, claimButton.y2);
hoverRematchYes = point_in_rectangle(mx, my, rematchYesButton.x1, rematchYesButton.y1, rematchYesButton.x2, rematchYesButton.y2);
hoverRematchNo = point_in_rectangle(mx, my, rematchNoButton.x1, rematchNoButton.y1, rematchNoButton.x2, rematchNoButton.y2);
hoverNextChallenger = point_in_rectangle(mx, my, nextChallengerButton.x1, nextChallengerButton.y1, nextChallengerButton.x2, nextChallengerButton.y2);
hoverBet1 = point_in_rectangle(mx, my, betChip1Button.x1, betChip1Button.y1, betChip1Button.x2, betChip1Button.y2);
hoverBet5 = point_in_rectangle(mx, my, betChip5Button.x1, betChip5Button.y1, betChip5Button.x2, betChip5Button.y2);
hoverBet10 = point_in_rectangle(mx, my, betChip10Button.x1, betChip10Button.y1, betChip10Button.x2, betChip10Button.y2);
hoverBet25 = point_in_rectangle(mx, my, betChip25Button.x1, betChip25Button.y1, betChip25Button.x2, betChip25Button.y2);
hoverBet100 = point_in_rectangle(mx, my, betChip100Button.x1, betChip100Button.y1, betChip100Button.x2, betChip100Button.y2);
hoverBetP1 = point_in_rectangle(mx, my, betP1Button.x1, betP1Button.y1, betP1Button.x2, betP1Button.y2);
hoverBetP2 = point_in_rectangle(mx, my, betP2Button.x1, betP2Button.y1, betP2Button.x2, betP2Button.y2);
hoverBetSend = false;

var lerpRate = 0.2;
showdownP1BallXDraw = lerp(showdownP1BallXDraw, clamp(rouletteStructGet(showdownP1Breakout, "ballXNorm", 0.5), 0, 1), lerpRate);
showdownP1BallYDraw = lerp(showdownP1BallYDraw, clamp(rouletteStructGet(showdownP1Breakout, "ballYNorm", 0.85), 0, 1), lerpRate);
showdownP2BallXDraw = lerp(showdownP2BallXDraw, clamp(rouletteStructGet(showdownP2Breakout, "ballXNorm", 0.5), 0, 1), lerpRate);
showdownP2BallYDraw = lerp(showdownP2BallYDraw, clamp(rouletteStructGet(showdownP2Breakout, "ballYNorm", 0.85), 0, 1), lerpRate);
showdownP1BatDraw = lerp(showdownP1BatDraw, clamp(rouletteStructGet(showdownP1Breakout, "batNorm", 0.5), 0, 1), lerpRate);
showdownP2BatDraw = lerp(showdownP2BatDraw, clamp(rouletteStructGet(showdownP2Breakout, "batNorm", 0.5), 0, 1), lerpRate);

if (state == "START") {
	if (keyboard_check_pressed(vk_escape)) {
		room_goto(RoomArcadeLobby);
	}

	if (mouse_check_button_pressed(mb_left) && hoverSolo) {
		breakoutRequestSoloStart(id);
	}
	if (mouse_check_button_pressed(mb_left) && hoverShowdown) {
		breakoutRequestShowdownWatch(id);
	}
	if (keyboard_check_pressed(ord("S"))) {
		breakoutRequestSoloStart(id);
	}
	if (keyboard_check_pressed(ord("M"))) {
		breakoutRequestShowdownWatch(id);
	}
	exit;
}

if (state == "SHOWDOWN_LOBBY") {
	if (keyboard_check_pressed(vk_escape)) {
		state = "START";
		mode = "menu";
		statusText = "Choose Solo or Showdown.";
		breakoutHideBoard();
		exit;
	}

	if (breakoutBrokerConnected) {
		var inCurrentLobby = showdownCurrentLobbyId != "";

		if (!inCurrentLobby) {
			for (var lobbyRow = 0; lobbyRow < min(6, array_length(showdownLobbyList)); lobbyRow++) {
				var rowY = listY + lobbyRow * (listRowH + 8);
				if (mouse_check_button_pressed(mb_left) && point_in_rectangle(mx, my, listX, rowY, listX + listW, rowY + listRowH)) {
					showdownSelectedLobbyId = rouletteStructGet(showdownLobbyList[lobbyRow], "id", showdownSelectedLobbyId);
				}
			}

			if (mouse_check_button_pressed(mb_left) && hoverCreate) {
				rouletteSendJson(breakoutBrokerSocket, { type: "table_create_lobby", game: showdownGameKey });
			}
			if (mouse_check_button_pressed(mb_left) && hoverJoin && showdownSelectedLobbyId != "") {
				rouletteSendJson(breakoutBrokerSocket, { type: "table_join_lobby", game: showdownGameKey, lobbyId: showdownSelectedLobbyId });
			}
		}

		if (inCurrentLobby) {
			var myBreakoutBetAmount = 0;
			for (var betIndex = 0; betIndex < array_length(showdownBreakoutBets); betIndex++) {
				var betRow = showdownBreakoutBets[betIndex];
				if (rouletteStructGet(betRow, "bettorId", "") == breakoutPlayerId) {
					myBreakoutBetAmount = max(0, floor(rouletteStructGet(betRow, "amount", 0)));
					break;
				}
			}

			if (mouse_check_button_pressed(mb_left) && hoverLeave) {
				rouletteSendJson(breakoutBrokerSocket, { type: "table_leave_lobby", game: showdownGameKey });
			}
			if (mouse_check_button_pressed(mb_left) && hoverStartRace && showdownRole == "racer") {
				rouletteSendJson(breakoutBrokerSocket, { type: "table_breakout_start" });
			}

			if (mouse_check_button_pressed(mb_left) && hoverClaim && showdownPromptOpen && showdownRole == "spectator") {
				rouletteSendJson(breakoutBrokerSocket, { type: "table_breakout_claim_player2" });
			}

			if (mouse_check_button_pressed(mb_left) && hoverBet1) selectedBetAmount = 1;
			if (mouse_check_button_pressed(mb_left) && hoverBet5) selectedBetAmount = 5;
			if (mouse_check_button_pressed(mb_left) && hoverBet10) selectedBetAmount = 10;
			if (mouse_check_button_pressed(mb_left) && hoverBet25) selectedBetAmount = 25;
			if (mouse_check_button_pressed(mb_left) && hoverBet100) selectedBetAmount = 100;

			if (showdownRole == "spectator" && showdownAllowBets && myBreakoutBetAmount <= 0) {
				if (mouse_check_button_pressed(mb_left) && (hoverBetP1 || hoverBetP2)) {
					selectedBetTarget = hoverBetP1 ? 1 : 2;
					var targetId = selectedBetTarget == 1 ? showdownPlayer1Id : showdownPlayer2Id;
					if (targetId != "") {
						rouletteSendJson(breakoutBrokerSocket, {
							type: "table_breakout_place_bet",
							targetPlayerId: targetId,
							amount: selectedBetAmount
						});
					}
				}
			}

			if (mouse_check_button_pressed(mb_left) && hoverRematchYes && showdownRole == "racer" && showdownState == "showdown") {
				rouletteSendJson(breakoutBrokerSocket, { type: "table_breakout_vote_rematch", accept: true });
			}
			if (mouse_check_button_pressed(mb_left) && hoverRematchNo && showdownRole == "racer" && showdownState == "showdown") {
				rouletteSendJson(breakoutBrokerSocket, { type: "table_breakout_vote_rematch", accept: false });
			}
			if (mouse_check_button_pressed(mb_left) && hoverNextChallenger && showdownRole == "racer" && showdownState == "showdown") {
				rouletteSendJson(breakoutBrokerSocket, { type: "table_breakout_next_challenger" });
			}
		}
	}

	exit;
}

if (state == "SHOWDOWN_WATCH") {
	if (keyboard_check_pressed(vk_escape)) {
		if (showdownState != "racing") {
			state = "SHOWDOWN_LOBBY";
			statusText = showdownSummary;
		}
	}
	exit;
}

if (state == "GAMEOVER") {
	if (mode == "solo") {
		if (!payoutSettled) {
			lastRunPayout = floor(max(0, global.BOPScore) * scoreToSgcRate);
			runNet = lastRunPayout - entryCost;
			if (global.BOPScore > global.highScore) global.highScore = global.BOPScore;
			if (breakoutBrokerConnected) {
				soloSettlePending = true;
				rouletteSendJson(breakoutBrokerSocket, {
					type: "breakout_single_settle",
					score: global.BOPScore,
					level: level,
					distance: breakoutDistance(id)
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
			breakoutHideBoard();
		}
	} else if (mode == "showdown") {
		showdownLocalFinished = true;
		if (!localRaceSubmitted && breakoutBrokerConnected) {
			var finishTelemetry = breakoutReadTelemetry(id);
			localRaceSubmitted = true;
			rouletteSendJson(breakoutBrokerSocket, {
				type: "table_breakout_finish",
				score: global.BOPScore,
				level: level,
				lives: max(0, global.BOPLives),
				distance: breakoutDistance(id),
				"batNorm": finishTelemetry.batNorm,
				"ballXNorm": finishTelemetry.ballXNorm,
				"ballYNorm": finishTelemetry.ballYNorm,
				"brickCount": finishTelemetry.brickCount,
				"brickMask": finishTelemetry.brickMask,
				"brickColorMask": finishTelemetry.brickColorMask
			});
			statusText = "Waiting for showdown result...";
		}
		state = "SHOWDOWN_WATCH";
		breakoutHideBoard();
	}
	exit;
}

if (state == "PLAYING") {
	if (instance_number(objBrick) <= 0) {
		breakoutAdvanceLevel(id);
	}

	if (mode == "showdown" && breakoutBrokerConnected) {
		progressSendCooldown += 1;
		if (progressSendCooldown >= 10) {
			var telemetry = breakoutReadTelemetry(id);
			progressSendCooldown = 0;
			rouletteSendJson(breakoutBrokerSocket, {
				type: "table_breakout_progress",
				score: global.BOPScore,
				level: level,
				lives: max(0, global.BOPLives),
				distance: breakoutDistance(id),
				"batNorm": telemetry.batNorm,
				"ballXNorm": telemetry.ballXNorm,
				"ballYNorm": telemetry.ballYNorm,
				"brickCount": telemetry.brickCount,
				"brickMask": telemetry.brickMask,
				"brickColorMask": telemetry.brickColorMask
			});
		}
	}
}