var eventType = async_load[? "type"];

switch (eventType) {
	case network_type_non_blocking_connect:
		if ((async_load[? "id"]) == brokerSocket) {
			if ((async_load[? "succeeded"]) == 1) {
				brokerConnected = true;
				brokerPhase = "betting";
				brokerStatus = "Connected";
				rouletteSendJson(brokerSocket, {
					type: "join",
					name: playerName
				});
			} else {
				brokerConnected = false;
				brokerStatus = "Broker unavailable";
			}
		}
	break;

	case network_type_disconnect:
		if ((async_load[? "id"]) == brokerSocket || (async_load[? "socket"]) == brokerSocket) {
			brokerConnected = false;
			brokerPhase = "local";
			brokerStatus = "Disconnected";
			brokerPlayerCount = 1;
		}
	break;

	case network_type_data:
		if ((async_load[? "id"]) == brokerSocket) {
			var messageBuffer = async_load[? "buffer"];
			buffer_seek(messageBuffer, buffer_seek_start, 0);
			var rawMessage = buffer_read(messageBuffer, buffer_string);
			rawMessage = string_replace_all(rawMessage, chr(0), "");
			if (string_length(rawMessage) > 0) {
				var message = json_parse(rawMessage);
				var messageKind = rouletteStructGet(message, "type", "");

				if (messageKind == "welcome") {
					brokerPlayerId = rouletteStructGet(message, "playerId", "");
					brokerStatus = "Connected as " + brokerPlayerId;
				}

				if (messageKind == "state") {
					brokerPhase = rouletteStructGet(message, "phase", brokerPhase);
					brokerPlayerCount = rouletteStructGet(message, "playerCount", brokerPlayerCount);
					currentLobbyId = rouletteStructGet(message, "currentLobbyId", currentLobbyId);
					currentLobbyName = rouletteStructGet(message, "currentLobbyName", currentLobbyName);
					lobbyList = rouletteStructGet(message, "lobbies", []);
					bankroll = rouletteStructGet(message, "yourBankroll", bankroll);
					lastWager = rouletteStructGet(message, "lastWager", lastWager);
					lastPayout = rouletteStructGet(message, "lastPayout", lastPayout);
					winningNumber = rouletteStructGet(message, "winningNumber", winningNumber);
					lastSpinSummary = rouletteStructGet(message, "lastSpinSummary", lastSpinSummary);
					var yourBets = rouletteStructGet(message, "yourBets", {});
					var tableTotals = rouletteStructGet(message, "tableTotals", {});
					rouletteApplyBetState(betAreas, yourBets, tableTotals);

					var incomingSpinPlan = rouletteStructGet(message, "spinPlan", undefined);
					if (is_struct(incomingSpinPlan) && rouletteStructGet(incomingSpinPlan, "spinId", -1) != activeSpinId) {
						pendingSpinPlan = incomingSpinPlan;
					}

					if (array_length(lobbyList) > 0) {
						var foundSelected = false;
						for (var lobbyIndex = 0; lobbyIndex < array_length(lobbyList); lobbyIndex++) {
							if (rouletteStructGet(lobbyList[lobbyIndex], "id", "") == selectedLobbyId) {
								foundSelected = true;
								break;
							}
						}

						if (!foundSelected) {
							selectedLobbyId = rouletteStructGet(lobbyList[0], "id", "");
						}
					} else {
						selectedLobbyId = "";
					}

					lobbyBrowserOpen = brokerConnected && (currentLobbyId == "" || lobbyBrowserOpen);
					if (currentLobbyId != "") {
						lobbyBrowserOpen = false;
					}

					if (!is_struct(incomingSpinPlan) && brokerPhase != "spinning") {
						rotation = rouletteStructGet(message, "rotation", rotation);
						ballAngle = rouletteStructGet(message, "ballAngle", ballAngle);
						finalBallAngle = ballAngle;
						spinSpeed = 0;
						ballSpeed = 0;
						fullSpeedTimer = 0;
						spinActive = false;
						ballState = 0;
						resultLocked = winningNumber != -1;
						betsResolved = true;
					}
				}
			}
		}
	break;
}