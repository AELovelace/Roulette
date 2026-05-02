var requestId = async_load[? "id"];
if (requestId != tableOAuthLinkHttpId) {
	exit;
}

tableOAuthLinkHttpId = -1;
tableOAuthLinkCheckedAt = current_time;

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
	tableOAuthLinkStatus = linked ? "linked" : "unlinked";
	if (linked) {
		show_debug_message("[table] OAuth link status: linked");
	} else {
		if (source == "sgc_api") {
			show_debug_message("[table] OAuth link status: NOT linked");
			tableBrokerStatus = "Account link expired. Sign in again.";
			if (variable_global_exists("sgcSignedIn")) global.sgcSignedIn = false;
			if (variable_global_exists("sgcDisplayName")) global.sgcDisplayName = "";
		} else {
			tableOAuthLinkStatus = "unknown";
			show_debug_message("[table] OAuth link status could not be verified (source=" + string(source) + ")");
		}
	}
} else {
	tableOAuthLinkStatus = "error";
	show_debug_message("[table] OAuth link check failed: HTTP " + string(httpStatus));
}
