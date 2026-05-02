var asyncId = async_load[? "id"];
if (asyncId != oauthPollRequestId) {
	exit;
}

oauthPollRequestId = -1;

var requestStatus = async_load[? "status"];
if (requestStatus < 0) {
	menuQueueOauthStatusPoll(room_speed);
	statusText = "[SGC] waiting for broker confirmation...";
	exit;
}

var responseBody = async_load[? "result"];
var parsed = undefined;
if (is_string(responseBody) && string_length(responseBody) > 0) {
	parsed = json_parse(responseBody);
}

if (!is_struct(parsed)) {
	menuQueueOauthStatusPoll(room_speed);
	statusText = "[SGC] waiting for broker confirmation...";
	exit;
}

if (rouletteStructGet(parsed, "linked", false)) {
	global.sgcSignedIn = true;
	global.sgcExternalId = rouletteStructGet(parsed, "external_id", global.sgcExternalId);
	var linkedDisplayName = rouletteStructGet(parsed, "display_name", "");
	if (linkedDisplayName != "") {
		global.sgcDisplayName = linkedDisplayName;
	}
	global.sgcOauthPending = false;
	global.sgcOauthSessionId = "";
	menuSaveSgcSession();
	oauthAwaitingBrowserLink = false;
	signInOpen = false;
	statusText = (global.sgcDisplayName != "")
		? ("[SGC] signed in as " + global.sgcDisplayName + ".")
		: "[SGC] account linked. Discord name will appear after identity:read is enabled.";
	exit;
}

menuQueueOauthStatusPoll(room_speed div 2);
global.sgcOauthPending = true;
statusText = "[SGC] waiting for broker confirmation...";
