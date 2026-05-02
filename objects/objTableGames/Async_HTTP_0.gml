// Handle OAuth link status check response
if (async_load[? "id"] == tableOAuthLinkHttpId) {
	tableOAuthLinkHttpId = -1;
	
	if (async_load[? "http_status"] == 0 || async_load[? "http_status"] == 200) {
		var response_str = async_load[? "result"];
		try {
			var response = json_parse(response_str);
			var linked = response?.linked ?? false;
			if (linked) {
				tableOAuthLinkStatus = "linked";
				var linked_at = response?.linked_at ?? 0;
				var linkedDate = date_create_from_datetime(linked_at / 1000);
				var dateStr = date_format(linkedDate, "%Y-%m-%d %H:%M");
				tableBrokerStatus = "OAuth linked (since " + dateStr + ")";
				show_debug_message("[table] OAuth link verified - account is linked");
			} else {
				tableOAuthLinkStatus = "unlinked";
				tableBrokerStatus = "OAuth link not found - please re-authenticate";
				show_debug_message("[table] OAuth link check: account is NOT linked");
			}
		} catch (e) {
			tableOAuthLinkStatus = "error";
			show_debug_message("[table] Failed to parse OAuth link response: " + string(e));
		}
	} else {
		tableOAuthLinkStatus = "error";
		var http_status = async_load[? "http_status"];
		tableBrokerStatus = "OAuth link check failed (HTTP " + string(http_status) + ")";
		show_debug_message("[table] OAuth link check HTTP error: " + string(http_status));
	}
}
