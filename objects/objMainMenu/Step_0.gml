var mouseXPos = device_mouse_x_to_gui(0);
var mouseYPos = device_mouse_y_to_gui(0);
hoveredButton = "";

function menuUrlComponent(_value) {
	var out = string(_value);
	out = string_replace_all(out, "%", "%25");
	out = string_replace_all(out, " ", "%20");
	out = string_replace_all(out, "&", "%26");
	out = string_replace_all(out, "?", "%3F");
	out = string_replace_all(out, "#", "%23");
	out = string_replace_all(out, "+", "%2B");
	out = string_replace_all(out, "/", "%2F");
	out = string_replace_all(out, "=", "%3D");
	return out;
}

function menuSaveSgcSession() {
	if (!variable_global_exists("sgcSessionPath")) global.sgcSessionPath = "sgc_session.ini";
	ini_open(global.sgcSessionPath);
	ini_write_real("sgc", "signed_in", global.sgcSignedIn ? 1 : 0);
	ini_write_string("sgc", "display_name", global.sgcDisplayName);
	ini_write_string("sgc", "external_id", global.sgcExternalId);
	ini_write_string("sgc", "link_code", global.sgcLinkCode);
	ini_write_string("sgc", "broker_http_base", global.sgcBrokerHttpBase);
	ini_write_string("sgc", "return_to_url", variable_global_exists("sgcReturnToUrl") ? global.sgcReturnToUrl : "");
	ini_write_real("sgc", "oauth_pending", variable_global_exists("sgcOauthPending") && global.sgcOauthPending ? 1 : 0);
	ini_close();
}

function menuExternalIdFromName(_name) {
	var out = string_lower(string_trim(_name));
	out = string_replace_all(out, " ", "_");
	out = string_replace_all(out, "@", "");
	out = string_replace_all(out, "#", "_");
	out = string_replace_all(out, "/", "_");
	out = string_replace_all(out, "\\", "_");
	out = string_replace_all(out, ":", "_");
	out = string_replace_all(out, "?", "_");
	out = string_replace_all(out, "&", "_");
	out = string_replace_all(out, "=", "_");
	if (out == "") out = "";
	return string_copy(out, 1, 64);
}

function menuOpenSignIn() {
	signInOpen = true;
	statusText = "[SYS] click the button below to authenticate with Discord.";
}

function menuQueueOauthStatusPoll(_delayFrames) {
	oauthPollCooldown = max(0, _delayFrames);
}

function menuOauthReturnUrl() {
	var browserUrl = string_trim(sgc_browser_get_url());
	if (browserUrl != "") return browserUrl;
	if (variable_global_exists("sgcReturnToUrl")) {
		var candidate = string_trim(global.sgcReturnToUrl);
		if (candidate != "") return candidate;
	}
	return "";
}

function menuRequestOauthStatus() {
	if (!oauthAwaitingBrowserLink) return;
	if (oauthPollRequestId != -1) return;
	if (string_trim(global.sgcExternalId) == "") return;

	var baseUrl = variable_global_exists("sgcBrokerHttpBase") ? string_trim(global.sgcBrokerHttpBase) : "https://sadgirlsclub.wtf";
	if (baseUrl == "") baseUrl = "https://sadgirlsclub.wtf";
	var statusUrl = baseUrl + "/sgc/oauth/status?external_id=" + menuUrlComponent(global.sgcExternalId);
	oauthPollRequestId = http_get(statusUrl);
}



function menuStartDiscordOAuth() {
	// Generate a UUID-like external_id if not already set
	if (global.sgcExternalId == "") {
		var timestamp = current_time;
		var random_part = string(irandom_range(100000, 999999));
		global.sgcExternalId = "player_" + string(timestamp) + "_" + random_part;
		menuSaveSgcSession();
	}

	var baseUrl = variable_global_exists("sgcBrokerHttpBase") ? string_trim(global.sgcBrokerHttpBase) : "https://sadgirlsclub.wtf";
	if (baseUrl == "") baseUrl = "https://sadgirlsclub.wtf";
	var outboundName = global.sgcDisplayName;
	var returnUrl = menuOauthReturnUrl();
	if (string_trim(outboundName) == "") outboundName = "";
	var oauthUrl = baseUrl
		+ "/sgc/oauth/start?external_id=" + menuUrlComponent(global.sgcExternalId)
		+ "&external_name=" + menuUrlComponent(outboundName);
	if (returnUrl != "") {
		oauthUrl += "&return_to=" + menuUrlComponent(returnUrl);
	}
	global.sgcOauthPending = true;
	menuSaveSgcSession();
	var popupOpened = sgc_oauth_popup_open(oauthUrl);
	oauthAwaitingBrowserLink = popupOpened > 0;
	if (oauthAwaitingBrowserLink) {
		menuQueueOauthStatusPoll(room_speed div 2);
		statusText = "[SGC] OAuth popup opened. Waiting for confirmation...";
	} else {
		oauthPollRequestId = -1;
		oauthPollCooldown = 0;
		statusText = "[SGC] popup blocked. Allow popups for this page and try again.";
	}
}

function menuCancelSignIn() {
	signInOpen = false;
	oauthAwaitingBrowserLink = false;
	oauthPollRequestId = -1;
	oauthPollCooldown = 0;
	global.sgcOauthPending = false;
	menuSaveSgcSession();
	statusText = "[SYS] sign-in cancelled.";
}

function menuActivateSelection() {
	if (selectedButton == 0) menuOpenSignIn();
	if (selectedButton == 1) room_goto(RoomTableLobby);
	if (selectedButton == 2) {
		settingsOpen = true;
		statusText = "[SYS] settings panel is blank for now.";
	}
}

if (signInOpen) {
	if (oauthAwaitingBrowserLink) {
		if (sgc_oauth_complete_consume() > 0) {
			oauthPollCooldown = 0;
			statusText = "[SGC] browser confirmed OAuth completion...";
			menuRequestOauthStatus();
		}

		if (oauthPollCooldown > 0) {
			oauthPollCooldown -= 1;
		} else {
			menuRequestOauthStatus();
			if (oauthPollRequestId == -1) {
				menuQueueOauthStatusPoll(room_speed div 2);
			}
		}
	}

	// Button hover detection - verify structs exist first
	if (!is_struct(signInOAuthButton) || !is_struct(signInCancelButton)) {
		statusText = "[ERROR] Button structs not initialized!";
		exit;
	}
	
	var overOAuth   = point_in_rectangle(mouseXPos, mouseYPos, signInOAuthButton.x,   signInOAuthButton.y,   signInOAuthButton.x   + signInOAuthButton.w,   signInOAuthButton.y   + signInOAuthButton.h);
	var overCancel  = point_in_rectangle(mouseXPos, mouseYPos, signInCancelButton.x,  signInCancelButton.y,  signInCancelButton.x  + signInCancelButton.w,  signInCancelButton.y  + signInCancelButton.h);
	
	if (overOAuth) {
		hoveredButton = "signin_oauth";
		if (!oauthAwaitingBrowserLink) statusText = "Click to authenticate with Discord";
	}
	else if (overCancel) {
		hoveredButton = "signin_cancel";
		if (!oauthAwaitingBrowserLink) statusText = "Cancel sign-in";
	}

	if (keyboard_check_pressed(ord("O"))) menuStartDiscordOAuth();
	if (keyboard_check_pressed(vk_escape)) menuCancelSignIn();

	// Button click handling
	if (mouse_check_button_pressed(mb_left)) {
		var clickedOAuth = point_in_rectangle(mouseXPos, mouseYPos, signInOAuthButton.x, signInOAuthButton.y, signInOAuthButton.x + signInOAuthButton.w, signInOAuthButton.y + signInOAuthButton.h);
		var clickedCancel = point_in_rectangle(mouseXPos, mouseYPos, signInCancelButton.x, signInCancelButton.y, signInCancelButton.x + signInCancelButton.w, signInCancelButton.y + signInCancelButton.h);
		
		if (clickedOAuth) {
			menuStartDiscordOAuth();
		} else if (clickedCancel) {
			menuCancelSignIn();
		}
	}
	exit;
}

if (!settingsOpen) {
	if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
		selectedButton = max(0, selectedButton - 1);
	}

	if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
		selectedButton = min(2, selectedButton + 1);
	}

	if (point_in_rectangle(mouseXPos, mouseYPos, signInButton.x, signInButton.y, signInButton.x + signInButton.w, signInButton.y + signInButton.h)) {
		hoveredButton = "signin";
		selectedButton = 0;
	}

	if (point_in_rectangle(mouseXPos, mouseYPos, playButton.x, playButton.y, playButton.x + playButton.w, playButton.y + playButton.h)) {
		hoveredButton = "play";
		selectedButton = 1;
	}

	if (point_in_rectangle(mouseXPos, mouseYPos, settingsButton.x, settingsButton.y, settingsButton.x + settingsButton.w, settingsButton.y + settingsButton.h)) {
		hoveredButton = "settings";
		selectedButton = 2;
	}

	if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
		menuActivateSelection();
	}

	if (mouse_check_button_pressed(mb_left)) {
		if (hoveredButton == "signin") menuOpenSignIn();
		else if (hoveredButton == "play") room_goto(RoomTableLobby);
		else if (hoveredButton == "settings") {
			settingsOpen = true;
			statusText = "[SYS] settings panel is blank for now.";
		}
	}
} else {
	var overClose = point_in_rectangle(mouseXPos, mouseYPos, settingsCloseButton.x, settingsCloseButton.y, settingsCloseButton.x + settingsCloseButton.w, settingsCloseButton.y + settingsCloseButton.h);
	hoveredButton = overClose ? "settings_close" : "";

	if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
		settingsOpen = false;
	}

	if (mouse_check_button_pressed(mb_left) && overClose) {
		settingsOpen = false;
	}
}