var eventType = async_load[? "type"];

switch (eventType) {
	case network_type_non_blocking_connect:
		if ((async_load[? "id"]) == snakeBrokerSocket) {
			if ((async_load[? "succeeded"]) == 1) {
				snakeBrokerConnected = true;
				snakeBrokerStatus = "Connected";
				var joinPayload = {
					type: "join",
					name: snakePlayerName,
					external_id: variable_global_exists("sgcExternalId") ? global.sgcExternalId : "",
					link_code: variable_global_exists("sgcLinkCode") ? global.sgcLinkCode : "",
					signed_in: variable_global_exists("sgcSignedIn") ? global.sgcSignedIn : false
				};
				if (variable_global_exists("sgcDisplayName") && global.sgcDisplayName != "") {
					joinPayload.name = global.sgcDisplayName;
					snakePlayerName = global.sgcDisplayName;
				}
				rouletteSendJson(snakeBrokerSocket, joinPayload);
				rouletteSendJson(snakeBrokerSocket, { type: "table_watch", game: showdownGameKey });
			} else {
				snakeBrokerConnected = false;
				snakeBrokerStatus = "Broker unavailable";
			}
		}
	break;

	case network_type_disconnect:
		if ((async_load[? "id"]) == snakeBrokerSocket || (async_load[? "socket"]) == snakeBrokerSocket) {
			snakeBrokerConnected = false;
			snakeBrokerStatus = "Disconnected";
			showdownCurrentLobbyId = "";
			showdownCurrentLobbyName = "No lobby";
			showdownRole = "spectator";
		}
	break;

	case network_type_data:
		if ((async_load[? "id"]) == snakeBrokerSocket) {
			var messageBuffer = async_load[? "buffer"];
			buffer_seek(messageBuffer, buffer_seek_start, 0);
			var rawMessage = buffer_read(messageBuffer, buffer_string);
			rawMessage = string_replace_all(rawMessage, chr(0), "");
			if (string_length(rawMessage) > 0) {
				var message = json_parse(rawMessage);
				var kind = rouletteStructGet(message, "type", "");

				if (kind == "welcome") {
					snakePlayerId = rouletteStructGet(message, "playerId", "");
					snakeBrokerStatus = "Connected as " + snakePlayerId;
					rouletteSendJson(snakeBrokerSocket, { type: "table_watch", game: showdownGameKey });
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
						snakePlayerName = displayName;
					}
					rouletteSendJson(snakeBrokerSocket, { type: "signed_in_ack" });
				}

				if (kind == "state") {
					global.sgcArcadeBalance = rouletteStructGet(message, "yourBankroll", global.sgcArcadeBalance);
				}

				if (kind == "snake_single_start_result") {
					soloStartPending = false;
					global.sgcArcadeBalance = rouletteStructGet(message, "balance", global.sgcArcadeBalance);
					if (rouletteStructGet(message, "ok", false)) {
						runCharged = true;
						snakeBeginRun(id);
					} else {
						statusText = "[SGC] " + rouletteStructGet(message, "message", "Entry failed.");
					}
				}

				if (kind == "snake_single_settle_result") {
					soloSettlePending = false;
					global.sgcArcadeBalance = rouletteStructGet(message, "balance", global.sgcArcadeBalance);
					statusText = "[SGC] " + rouletteStructGet(message, "message", "Payout posted.");
				}

				if (kind == "table_state" && rouletteStructGet(message, "game", "") == showdownGameKey) {
					showdownLobbyList = rouletteStructGet(message, "lobbies", []);
					var selectedStillExists = false;
					for (var lobbyIndex = 0; lobbyIndex < array_length(showdownLobbyList); lobbyIndex++) {
						if (rouletteStructGet(showdownLobbyList[lobbyIndex], "id", "") == showdownSelectedLobbyId) {
							selectedStillExists = true;
							break;
						}
					}
					if (!selectedStillExists) showdownSelectedLobbyId = array_length(showdownLobbyList) > 0 ? rouletteStructGet(showdownLobbyList[0], "id", "") : "";
					showdownCurrentLobbyId = rouletteStructGet(message, "currentLobbyId", showdownCurrentLobbyId);
					showdownCurrentLobbyName = rouletteStructGet(message, "currentLobbyName", showdownCurrentLobbyName);
					showdownParticipants = rouletteStructGet(message, "participants", []);
					showdownHostPlayerId = rouletteStructGet(message, "hostPlayerId", showdownHostPlayerId);
					showdownYouAreHost = showdownHostPlayerId == snakePlayerId;
					global.sgcArcadeBalance = rouletteStructGet(message, "bankroll", global.sgcArcadeBalance);

					var snakeData = rouletteStructGet(message, "snake", undefined);
					if (is_struct(snakeData)) {
						showdownState = rouletteStructGet(snakeData, "state", showdownState);
						showdownRaceSeed = rouletteStructGet(snakeData, "raceSeed", showdownRaceSeed);
						showdownWinnerId = rouletteStructGet(snakeData, "winnerId", showdownWinnerId);
						showdownLoserId = rouletteStructGet(snakeData, "loserId", showdownLoserId);
						showdownPlayer1Id = rouletteStructGet(snakeData, "player1Id", showdownPlayer1Id);
						showdownPlayer2Id = rouletteStructGet(snakeData, "player2Id", showdownPlayer2Id);
						showdownPromptOpen = rouletteStructGet(snakeData, "challengerPromptOpen", showdownPromptOpen);
						showdownAllowBets = rouletteStructGet(snakeData, "allowBets", showdownAllowBets);
						showdownSummary = rouletteStructGet(snakeData, "showdownSummary", showdownSummary);
						showdownRematchVotes = rouletteStructGet(snakeData, "rematchVotes", showdownRematchVotes);
						showdownSnakeBets = rouletteStructGet(snakeData, "bets", showdownSnakeBets);
					} else {
						showdownSnakeBets = [];
					}

					showdownRole = "spectator";
					showdownP1Name = "Player 1";
					showdownP2Name = "Player 2";
					showdownP1Snake = { score: 0, length: 3, distance: 0, headXNorm: 0.5, headYNorm: 0.5, alive: true };
					showdownP2Snake = { score: 0, length: 3, distance: 0, headXNorm: 0.5, headYNorm: 0.5, alive: true };

					for (var i = 0; i < array_length(showdownParticipants); i++) {
						var participant = showdownParticipants[i];
						var pid = rouletteStructGet(participant, "playerId", "");
						var pname = rouletteStructGet(participant, "name", "Player");
						var role = rouletteStructGet(participant, "role", "spectator");
						var snakeTelemetry = rouletteStructGet(participant, "snake", undefined);
						if (pid == snakePlayerId) showdownRole = role;
						if (pid == showdownPlayer1Id) {
							showdownP1Name = pname;
							if (is_struct(snakeTelemetry)) showdownP1Snake = snakeTelemetry;
						} else if (pid == showdownPlayer2Id) {
							showdownP2Name = pname;
							if (is_struct(snakeTelemetry)) showdownP2Snake = snakeTelemetry;
						}
					}

					if (mode == "showdown") {
						if (showdownState == "racing" && showdownRole == "racer" && !showdownLocalFinished) {
							var newRaceSeed = max(0, showdownRaceSeed);
							var startedSeed = max(0, localRaceSeedStarted);
							if (state != "PLAYING" || startedSeed != newRaceSeed) snakeBeginRun(id);
						}
						if (showdownState == "racing" && showdownRole != "racer") state = "SHOWDOWN_WATCH";
						if (showdownState == "racing" && showdownRole == "racer" && showdownLocalFinished) state = "SHOWDOWN_WATCH";
						if (showdownState != "racing" && state == "PLAYING") state = "SHOWDOWN_WATCH";
						if (showdownState != "racing") showdownLocalFinished = false;
						if (showdownState != "racing" && state == "SHOWDOWN_WATCH") state = "SHOWDOWN_LOBBY";
						statusText = showdownSummary;
					}
				}
			}
		}
	break;
}
