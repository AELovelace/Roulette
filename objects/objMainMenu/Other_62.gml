var requestId = async_load[? "id"];
if (requestId != menuOauthStatusRequestId) {
	exit;
}

menuOauthStatusRequestId = -1;

var httpStatus = async_load[? "status"];
var resultText = async_load[? "result"];

if (httpStatus != 200) {
	show_debug_message("[menu] OAuth status check failed: HTTP " + string(httpStatus));
	if (menuOauthPending) {
		menuOauthNextPollAt = current_time + 1500;
	}
	exit;
}

var parsed = undefined;
try {
	parsed = json_parse(resultText);
} catch (_err) {
	parsed = undefined;
}

var linked = rouletteStructGet(parsed, "linked", false);
if (!linked) {
	if (menuOauthPending) {
		menuOauthNextPollAt = current_time + 1000;
	}
	exit;
}

menuOauthPending = false;
global.sgcSignedIn = true;
var displayName = rouletteStructGet(parsed, "display_name", "");
if (displayName != "") {
	global.sgcDisplayName = displayName;
}
menuSaveSgcSession();
statusText = (global.sgcDisplayName != "")
	? ("[SGC] signed in as " + global.sgcDisplayName + ".")
	: "[SGC] sign-in complete.";
show_debug_message("[menu] OAuth sign-in completed for " + global.sgcExternalId);
