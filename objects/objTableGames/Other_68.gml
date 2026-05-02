var eventType = async_load[? "type"];

switch (eventType) {
	case network_type_non_blocking_connect:
		if ((async_load[? "id"]) == tableBrokerSocket) {
			if ((async_load[? "succeeded"]) == 1) {
				tableBrokerConnected = true;
				tableBrokerStatus = "Connected";
				rouletteSendJson(tableBrokerSocket, {
					type: "join",
					name: tablePlayerName
				});
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

				if (messageKind == "table_state" && rouletteStructGet(message, "game", "") == tableGameKey) {
					applyTableSnapshot(message);
					statusText = tableLastEvent;
				}
			}
		}
	break;
}
