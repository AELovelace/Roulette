var eventType = async_load[? "type"];

switch (eventType) {
	case network_type_non_blocking_connect:
		if ((async_load[? "id"]) == tableBrokerSocket) {
			if ((async_load[? "succeeded"]) == 1) {
				tableBrokerConnected = true;
				tableBrokerStatus = "Connected";
				var tableJoinPayload = {
					type: "join",
					name: tablePlayerName,
					external_id: variable_global_exists("sgcExternalId") ? global.sgcExternalId : "",
					link_code:   variable_global_exists("sgcLinkCode")    ? global.sgcLinkCode    : "",
					signed_in:   variable_global_exists("sgcSignedIn")    ? global.sgcSignedIn    : false
				};
				if (variable_global_exists("sgcDisplayName") && global.sgcDisplayName != "") {
					tableJoinPayload.name = global.sgcDisplayName;
					tablePlayerName = global.sgcDisplayName;
				}
				rouletteSendJson(tableBrokerSocket, tableJoinPayload);
				rouletteSendJson(tableBrokerSocket, {
					type: "table_watch",
					game: tableGameKey
				});
			} else {
				tableBrokerConnected = false;
				tableBrokerStatus = "Broker unavailable";
			}
		}
	break;

	case network_type_disconnect:
		if ((async_load[? "id"]) == tableBrokerSocket || (async_load[? "socket"]) == tableBrokerSocket) {
			tableBrokerConnected = false;
			tableBrokerStatus = "Disconnected";
			tableCurrentLobbyId = "";
			tableCurrentLobbyName = "No lobby";
			tableLobbyBrowserOpen = tableMultiplayerEnabled;
		}
	break;

	case network_type_data:
		if ((async_load[? "id"]) == tableBrokerSocket) {
			var messageBuffer = async_load[? "buffer"];
			buffer_seek(messageBuffer, buffer_seek_start, 0);
			var rawMessage = buffer_read(messageBuffer, buffer_string);
			rawMessage = string_replace_all(rawMessage, chr(0), "");
			if (string_length(rawMessage) > 0) {
				var message = json_parse(rawMessage);
				var messageKind = rouletteStructGet(message, "type", "");

				if (messageKind == "welcome") {
					tablePlayerId = rouletteStructGet(message, "playerId", "");
					tableBrokerStatus = "Connected as " + tablePlayerId;
					rouletteSendJson(tableBrokerSocket, {
						type: "table_watch",
						game: tableGameKey
					});
				}

				if (messageKind == "signed_in") {
					var signedState = rouletteStructGet(message, "signedIn", false);
					var externalId = rouletteStructGet(message, "externalId", "");
					var displayName = rouletteStructGet(message, "displayName", "");
					show_debug_message("[table] signed_in payload -> signedIn=" + string(signedState) + " externalId=" + externalId + " displayName=" + displayName);
					global.sgcSignedIn = signedState;
					if (externalId != "") global.sgcExternalId = externalId;
					if (!signedState) {
						global.sgcDisplayName = "";
						global.sgcLinkCode = "";
					} else if (displayName != "") {
						global.sgcDisplayName = displayName;
						tablePlayerName = displayName;
					}
					if (!variable_global_exists("sgcSessionPath")) global.sgcSessionPath = "sgc_session.ini";
					ini_open(global.sgcSessionPath);
					ini_write_real("sgc", "signed_in", global.sgcSignedIn ? 1 : 0);
					ini_write_string("sgc", "display_name", global.sgcDisplayName);
					ini_write_string("sgc", "external_id", global.sgcExternalId);
					ini_write_string("sgc", "link_code", variable_global_exists("sgcLinkCode") ? global.sgcLinkCode : "");
					ini_write_string("sgc", "broker_http_base", variable_global_exists("sgcBrokerHttpBase") ? global.sgcBrokerHttpBase : "https://sadgirlsclub.wtf");
					ini_write_real("sgc", "oauth_pending", variable_global_exists("sgcOauthPending") && global.sgcOauthPending ? 1 : 0);
					ini_write_string("sgc", "oauth_session_id", variable_global_exists("sgcOauthSessionId") ? global.sgcOauthSessionId : "");
					ini_close();
					rouletteSendJson(tableBrokerSocket, {
						type: "signed_in_ack"
					});
				}

				if (messageKind == "table_state" && rouletteStructGet(message, "game", "") == tableGameKey) {
					applyTableSnapshot(message);
					statusText = tableLastEvent;
				}
			}
		}
	break;
}
