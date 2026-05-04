viewResize();

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

var soloButton = { x1: room_width * 0.5 - 164, y1: room_height * 0.5 - 26, x2: room_width * 0.5 + 164, y2: room_height * 0.5 + 22 };
var showdownButton = { x1: room_width * 0.5 - 164, y1: room_height * 0.5 + 34, x2: room_width * 0.5 + 164, y2: room_height * 0.5 + 82 };
var createLobbyButton = { x1: 34, y1: 140, x2: 214, y2: 178 };
var joinLobbyButton = { x1: 224, y1: 140, x2: 404, y2: 178 };
var startRaceButton = { x1: 414, y1: 140, x2: 594, y2: 178 };
var claimButton = { x1: 34, y1: 370, x2: 274, y2: 406 };
var rematchYesButton = { x1: 34, y1: 412, x2: 204, y2: 448 };
var rematchNoButton = { x1: 214, y1: 412, x2: 384, y2: 448 };
var nextChallengerButton = { x1: 394, y1: 412, x2: 594, y2: 448 };
var betP1Button = { x1: 34, y1: 324, x2: 184, y2: 358 };
var betP2Button = { x1: 194, y1: 324, x2: 344, y2: 358 };
var betSendButton = { x1: 354, y1: 324, x2: 594, y2: 358 };

hoverSolo = point_in_rectangle(mx, my, soloButton.x1, soloButton.y1, soloButton.x2, soloButton.y2);
hoverShowdown = point_in_rectangle(mx, my, showdownButton.x1, showdownButton.y1, showdownButton.x2, showdownButton.y2);
hoverCreate = point_in_rectangle(mx, my, createLobbyButton.x1, createLobbyButton.y1, createLobbyButton.x2, createLobbyButton.y2);
hoverJoin = point_in_rectangle(mx, my, joinLobbyButton.x1, joinLobbyButton.y1, joinLobbyButton.x2, joinLobbyButton.y2);
hoverStartRace = point_in_rectangle(mx, my, startRaceButton.x1, startRaceButton.y1, startRaceButton.x2, startRaceButton.y2);
hoverClaim = point_in_rectangle(mx, my, claimButton.x1, claimButton.y1, claimButton.x2, claimButton.y2);
hoverRematchYes = point_in_rectangle(mx, my, rematchYesButton.x1, rematchYesButton.y1, rematchYesButton.x2, rematchYesButton.y2);
hoverRematchNo = point_in_rectangle(mx, my, rematchNoButton.x1, rematchNoButton.y1, rematchNoButton.x2, rematchNoButton.y2);
hoverNextChallenger = point_in_rectangle(mx, my, nextChallengerButton.x1, nextChallengerButton.y1, nextChallengerButton.x2, nextChallengerButton.y2);
hoverBetP1 = point_in_rectangle(mx, my, betP1Button.x1, betP1Button.y1, betP1Button.x2, betP1Button.y2);
hoverBetP2 = point_in_rectangle(mx, my, betP2Button.x1, betP2Button.y1, betP2Button.x2, betP2Button.y2);
hoverBetSend = point_in_rectangle(mx, my, betSendButton.x1, betSendButton.y1, betSendButton.x2, betSendButton.y2);

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
		if (showdownCurrentLobbyId == "" && array_length(showdownLobbyList) == 0 && mouse_check_button_pressed(mb_left) && hoverCreate) {
			rouletteSendJson(breakoutBrokerSocket, { type: "table_create_lobby", game: showdownGameKey });
		}
		if (showdownCurrentLobbyId == "" && array_length(showdownLobbyList) > 0 && mouse_check_button_pressed(mb_left) && hoverJoin) {
			showdownSelectedLobbyId = rouletteStructGet(showdownLobbyList[0], "id", "");
			if (showdownSelectedLobbyId != "") {
				rouletteSendJson(breakoutBrokerSocket, { type: "table_join_lobby", game: showdownGameKey, lobbyId: showdownSelectedLobbyId });
			}
		}

		if (mouse_check_button_pressed(mb_left) && hoverStartRace && showdownRole == "racer") {
			rouletteSendJson(breakoutBrokerSocket, { type: "table_breakout_start" });
		}

		if (mouse_check_button_pressed(mb_left) && hoverClaim && showdownPromptOpen && showdownRole == "spectator") {
			rouletteSendJson(breakoutBrokerSocket, { type: "table_breakout_claim_player2" });
		}

		if (mouse_check_button_pressed(mb_left) && hoverBetP1) selectedBetTarget = 1;
		if (mouse_check_button_pressed(mb_left) && hoverBetP2) selectedBetTarget = 2;
		if (mouse_check_button_pressed(mb_left) && hoverBetSend && showdownRole == "spectator" && showdownAllowBets) {
			var racerIds = [];
			for (var i = 0; i < array_length(showdownParticipants); i++) {
				var row = showdownParticipants[i];
				if (rouletteStructGet(row, "role", "spectator") == "racer") {
					array_push(racerIds, rouletteStructGet(row, "playerId", ""));
				}
			}
			var targetIndex = clamp(selectedBetTarget - 1, 0, max(0, array_length(racerIds) - 1));
			var targetId = array_length(racerIds) > 0 ? racerIds[targetIndex] : "";
			if (targetId != "") {
				rouletteSendJson(breakoutBrokerSocket, {
					type: "table_breakout_place_bet",
					targetPlayerId: targetId,
					amount: selectedBetAmount
				});
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

	exit;
}

if (state == "SHOWDOWN_WATCH") {
	if (keyboard_check_pressed(vk_escape)) {
		state = "SHOWDOWN_LOBBY";
		statusText = showdownSummary;
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
		if (!localRaceSubmitted && breakoutBrokerConnected) {
			var finishTelemetry = breakoutReadTelemetry(id);
			localRaceSubmitted = true;
			rouletteSendJson(breakoutBrokerSocket, {
				type: "table_breakout_finish",
				score: global.BOPScore,
				level: level,
				lives: max(0, global.BOPLives),
				distance: breakoutDistance(id),
				batNorm: finishTelemetry.batNorm,
				ballXNorm: finishTelemetry.ballXNorm,
				ballYNorm: finishTelemetry.ballYNorm,
				brickCount: finishTelemetry.brickCount,
				brickMask: finishTelemetry.brickMask,
				brickColorMask: finishTelemetry.brickColorMask
			});
			statusText = "Waiting for showdown result...";
		}
		state = "SHOWDOWN_LOBBY";
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
				batNorm: telemetry.batNorm,
				ballXNorm: telemetry.ballXNorm,
				ballYNorm: telemetry.ballYNorm,
				brickCount: telemetry.brickCount,
				brickMask: telemetry.brickMask,
				brickColorMask: telemetry.brickColorMask
			});
		}
	}
}