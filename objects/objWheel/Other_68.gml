var eventType = async_load[? "type"];

switch (eventType) {
	case network_type_non_blocking_connect:
		if ((async_load[? "id"]) == brokerSocket) {
			if ((async_load[? "succeeded"]) == 1) {
				brokerConnected = true;
				brokerPhase = "betting";
				brokerStatus = "Connected";
				var joinPayload = {
					type: "join",
					name: playerName,
					external_id: variable_global_exists("sgcExternalId") ? global.sgcExternalId : "",
					link_code:   variable_global_exists("sgcLinkCode")    ? global.sgcLinkCode    : "",
					signed_in:   variable_global_exists("sgcSignedIn")    ? global.sgcSignedIn    : false
				};
				if (variable_global_exists("sgcDisplayName") && global.sgcDisplayName != "") {
					joinPayload.name = global.sgcDisplayName;
					playerName = global.sgcDisplayName;
				}
				rouletteSendJson(brokerSocket, joinPayload);
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
					   // Check OAuth link status if user has an external_id
					   if (variable_global_exists("sgcExternalId") && global.sgcExternalId != "") {
						   var baseUrl = variable_global_exists("sgcBrokerHttpBase") ? string_trim(global.sgcBrokerHttpBase) : "https://sadgirlsclub.wtf";
						   if (baseUrl == "") baseUrl = "https://sadgirlsclub.wtf";
						   var statusUrl = baseUrl + "/sgc/oauth/status?external_id=" + string_url_encode(global.sgcExternalId);
						   oauthLinkHttpId = http_get(statusUrl);
						   oauthLinkStatus = "checking";
						   show_debug_message("[wheel] checking OAuth link status for " + global.sgcExternalId);
					   }
				}

				if (messageKind == "signed_in") {
					var signedState = rouletteStructGet(message, "signedIn", false);
					var externalId = rouletteStructGet(message, "externalId", "");
					var displayName = rouletteStructGet(message, "displayName", "");
					show_debug_message("[wheel] signed_in payload -> signedIn=" + string(signedState) + " externalId=" + externalId + " displayName=" + displayName);
					global.sgcSignedIn = signedState;
					global.sgcExternalId = externalId;
					if (displayName != "") {
						global.sgcDisplayName = displayName;
						playerName = displayName;
					}
					if (!variable_global_exists("sgcSessionPath")) global.sgcSessionPath = "sgc_session.ini";
					ini_open(global.sgcSessionPath);
					ini_write_real("sgc", "signed_in", global.sgcSignedIn ? 1 : 0);
					ini_write_string("sgc", "display_name", global.sgcDisplayName);
					ini_write_string("sgc", "external_id", global.sgcExternalId);
					ini_write_string("sgc", "link_code", variable_global_exists("sgcLinkCode") ? global.sgcLinkCode : "");
					ini_write_string("sgc", "broker_http_base", variable_global_exists("sgcBrokerHttpBase") ? global.sgcBrokerHttpBase : "https://sadgirlsclub.wtf");
					ini_close();
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