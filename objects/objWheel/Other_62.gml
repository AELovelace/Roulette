var requestId = async_load[? "id"];
if (requestId != oauthLinkHttpId) {
	exit;
}

oauthLinkHttpId = -1;
oauthLinkCheckedAt = current_time;

var httpStatus = async_load[? "status"];
var resultText = async_load[? "result"];

if (httpStatus == 200) {
	var parsed = undefined;
	try {
		parsed = json_parse(resultText);
	} catch (_err) {
		parsed = undefined;
	}
	var linked = rouletteStructGet(parsed, "linked", false);
	var source = rouletteStructGet(parsed, "source", "unknown");
	oauthLinkStatus = linked ? "linked" : "unlinked";
	if (linked) {
		show_debug_message("[wheel] OAuth link status: linked");
	} else {
		if (source == "sgc_api") {
			show_debug_message("[wheel] OAuth link status: NOT linked");
			brokerStatus = "Account link expired. Sign in again.";
			if (variable_global_exists("sgcSignedIn")) global.sgcSignedIn = false;
			if (variable_global_exists("sgcDisplayName")) global.sgcDisplayName = "";
		} else {
			oauthLinkStatus = "unknown";
			show_debug_message("[wheel] OAuth link status could not be verified (source=" + string(source) + ")");
		}
	}
} else {
	oauthLinkStatus = "error";
	show_debug_message("[wheel] OAuth link check failed: HTTP " + string(httpStatus));
}
