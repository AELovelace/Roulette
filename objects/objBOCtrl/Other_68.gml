var eventType = async_load[? "type"];

switch (eventType) {
	case network_type_non_blocking_connect:
		if ((async_load[? "id"]) == breakoutBrokerSocket) {
			if ((async_load[? "succeeded"]) == 1) {
				breakoutBrokerConnected = true;
				breakoutBrokerStatus = "Connected";
				var joinPayload = {
					type: "join",
					name: breakoutPlayerName,
					external_id: variable_global_exists("sgcExternalId") ? global.sgcExternalId : "",
					link_code: variable_global_exists("sgcLinkCode") ? global.sgcLinkCode : "",
					signed_in: variable_global_exists("sgcSignedIn") ? global.sgcSignedIn : false
				};
				if (variable_global_exists("sgcDisplayName") && global.sgcDisplayName != "") {
					joinPayload.name = global.sgcDisplayName;
					breakoutPlayerName = global.sgcDisplayName;
				}
				rouletteSendJson(breakoutBrokerSocket, joinPayload);
				rouletteSendJson(breakoutBrokerSocket, { type: "table_watch", game: showdownGameKey });
			} else {
				breakoutBrokerConnected = false;
				breakoutBrokerStatus = "Broker unavailable";
			}
		}
	break;

	case network_type_disconnect:
		if ((async_load[? "id"]) == breakoutBrokerSocket || (async_load[? "socket"]) == breakoutBrokerSocket) {
			breakoutBrokerConnected = false;
			breakoutBrokerStatus = "Disconnected";
			showdownCurrentLobbyId = "";
			showdownCurrentLobbyName = "No lobby";
			showdownRole = "spectator";
		}
	break;

	case network_type_data:
		if ((async_load[? "id"]) == breakoutBrokerSocket) {
			var messageBuffer = async_load[? "buffer"];
			buffer_seek(messageBuffer, buffer_seek_start, 0);
			var rawMessage = buffer_read(messageBuffer, buffer_string);
			rawMessage = string_replace_all(rawMessage, chr(0), "");
			if (string_length(rawMessage) > 0) {
				var message = json_parse(rawMessage);
				var kind = rouletteStructGet(message, "type", "");

				if (kind == "welcome") {
					breakoutPlayerId = rouletteStructGet(message, "playerId", "");
					breakoutBrokerStatus = "Connected as " + breakoutPlayerId;
					rouletteSendJson(breakoutBrokerSocket, { type: "table_watch", game: showdownGameKey });
				}

				if (kind == "signed_in") {
					var signedState = rouletteStructGet(message, "signedIn", false);
					var externalId = rouletteStructGet(message, "externalId", "");
					var displayName = rouletteStructGet(message, "displayName", "");
					global.sgcSignedIn = signedState;
					if (externalId != "") global.sgcExternalId = externalId;
					if (!signedState) {
						global.sgcDisplayName = "";
						global.sgcLinkCode = "";
					} else if (displayName != "") {
						global.sgcDisplayName = displayName;
						breakoutPlayerName = displayName;
					}
					rouletteSendJson(breakoutBrokerSocket, { type: "signed_in_ack" });
				}

				if (kind == "state") {
					global.sgcArcadeBalance = rouletteStructGet(message, "yourBankroll", global.sgcArcadeBalance);
				}

				if (kind == "breakout_single_start_result") {
					soloStartPending = false;
					global.sgcArcadeBalance = rouletteStructGet(message, "balance", global.sgcArcadeBalance);
					if (rouletteStructGet(message, "ok", false)) {
						runCharged = true;
						breakoutBeginRun(id);
					} else {
						statusText = "[SGC] " + rouletteStructGet(message, "message", "Entry failed.");
					}
				}

				if (kind == "breakout_single_settle_result") {
					soloSettlePending = false;
					global.sgcArcadeBalance = rouletteStructGet(message, "balance", global.sgcArcadeBalance);
					statusText = "[SGC] " + rouletteStructGet(message, "message", "Payout posted.");
				}

				if (kind == "table_state" && rouletteStructGet(message, "game", "") == showdownGameKey) {
					showdownLobbyList = rouletteStructGet(message, "lobbies", []);
					showdownCurrentLobbyId = rouletteStructGet(message, "currentLobbyId", showdownCurrentLobbyId);
					showdownCurrentLobbyName = rouletteStructGet(message, "currentLobbyName", showdownCurrentLobbyName);
					showdownParticipants = rouletteStructGet(message, "participants", []);
					showdownHostPlayerId = rouletteStructGet(message, "hostPlayerId", showdownHostPlayerId);
					showdownYouAreHost = showdownHostPlayerId == breakoutPlayerId;
					global.sgcArcadeBalance = rouletteStructGet(message, "bankroll", global.sgcArcadeBalance);
					var breakoutData = rouletteStructGet(message, "breakout", undefined);
					if (is_struct(breakoutData)) {
						showdownState = rouletteStructGet(breakoutData, "state", showdownState);
						showdownWinnerId = rouletteStructGet(breakoutData, "winnerId", showdownWinnerId);
						showdownLoserId = rouletteStructGet(breakoutData, "loserId", showdownLoserId);
						showdownPlayer1Id = rouletteStructGet(breakoutData, "player1Id", showdownPlayer1Id);
						showdownPlayer2Id = rouletteStructGet(breakoutData, "player2Id", showdownPlayer2Id);
						showdownPromptOpen = rouletteStructGet(breakoutData, "challengerPromptOpen", showdownPromptOpen);
						showdownAllowBets = rouletteStructGet(breakoutData, "allowBets", showdownAllowBets);
						showdownSummary = rouletteStructGet(breakoutData, "showdownSummary", showdownSummary);
						showdownRematchVotes = rouletteStructGet(breakoutData, "rematchVotes", showdownRematchVotes);
					}

					showdownRole = "spectator";
					showdownP1Name = "Player 1";
					showdownP2Name = "Player 2";
					showdownP1Breakout = { score: 0, level: 1, lives: 3, distance: 0, batNorm: 0.5, ballXNorm: 0.5, ballYNorm: 0.85, brickCount: 0 };
					showdownP2Breakout = { score: 0, level: 1, lives: 3, distance: 0, batNorm: 0.5, ballXNorm: 0.5, ballYNorm: 0.85, brickCount: 0 };
					opponentName = "Waiting...";
					opponentScore = 0;
					opponentLevel = 1;
					opponentLives = 3;
					opponentDistance = 0;
					opponentBatNorm = 0.5;
					opponentBallXNorm = 0.5;
					opponentBallYNorm = 0.85;
					opponentBrickCount = 0;
					for (var i = 0; i < array_length(showdownParticipants); i++) {
						var participant = showdownParticipants[i];
						var pid = rouletteStructGet(participant, "playerId", "");
						var pname = rouletteStructGet(participant, "name", "Player");
						var role = rouletteStructGet(participant, "role", "spectator");
						var bo = rouletteStructGet(participant, "breakout", undefined);
						if (pid == breakoutPlayerId) {
							showdownRole = role;
						}
						if (pid == showdownPlayer1Id) {
							showdownP1Name = pname;
							if (is_struct(bo)) showdownP1Breakout = bo;
						} else if (pid == showdownPlayer2Id) {
							showdownP2Name = pname;
							if (is_struct(bo)) showdownP2Breakout = bo;
						}
						if (role == "racer" && pid != breakoutPlayerId) {
							opponentName = pname;
							if (is_struct(bo)) {
								opponentScore = rouletteStructGet(bo, "score", 0);
								opponentLevel = rouletteStructGet(bo, "level", 1);
								opponentLives = rouletteStructGet(bo, "lives", 3);
								opponentDistance = rouletteStructGet(bo, "distance", 0);
								opponentBatNorm = rouletteStructGet(bo, "batNorm", 0.5);
								opponentBallXNorm = rouletteStructGet(bo, "ballXNorm", 0.5);
								opponentBallYNorm = rouletteStructGet(bo, "ballYNorm", 0.85);
								opponentBrickCount = rouletteStructGet(bo, "brickCount", 0);
							}
						}
					}

					if (mode == "showdown") {
						if (showdownState == "racing" && showdownRole == "racer" && state != "PLAYING") {
							breakoutBeginRun(id);
						}
						if (showdownState == "racing" && showdownRole != "racer") {
							state = "SHOWDOWN_WATCH";
							breakoutHideBoard();
						}
						if (showdownState != "racing" && state == "PLAYING") {
							state = "SHOWDOWN_LOBBY";
							breakoutHideBoard();
						}
						if (showdownState != "racing" && state == "SHOWDOWN_WATCH") {
							state = "SHOWDOWN_LOBBY";
						}
						if (state == "SHOWDOWN_LOBBY") {
							statusText = showdownSummary;
						}
					}
				}
			}
		}
	break;
}
