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
	signInOpen = false;
	menuStartDiscordOAuth();
}



function menuStartDiscordOAuth() {
	// Generate a UUID-like external_id if not already set
	if (global.sgcExternalId == "") {
		var timestamp = current_time;
		var random_part = string(irandom_range(100000, 999999));
		global.sgcExternalId = "player_" + string(timestamp) + "_" + random_part;
	}
	menuSaveSgcSession();

	var baseUrl = variable_global_exists("sgcBrokerHttpBase") ? string_trim(global.sgcBrokerHttpBase) : "https://sadgirlsclub.wtf";
	if (baseUrl == "") baseUrl = "https://sadgirlsclub.wtf";
	var outboundName = global.sgcDisplayName;
	if (string_trim(outboundName) == "") outboundName = "";
	var oauthUrl = baseUrl
		+ "/sgc/oauth/start?external_id=" + menuUrlComponent(global.sgcExternalId)
		+ "&external_name=" + menuUrlComponent(outboundName);
	menuOauthPending = true;
	menuOauthStatusRequestId = -1;
	menuOauthNextPollAt = current_time + 750;
	menuOauthDeadlineAt = current_time + 120000;
	url_open(oauthUrl);
	statusText = "[SGC] opening Discord OAuth in browser... return to the game when done.";
}

function menuCancelSignIn() {
	signInOpen = false;
	statusText = "[SYS] sign-in cancelled.";
}

function menuSignOut() {
	if (!variable_global_exists("sgcSessionPath")) global.sgcSessionPath = "sgc_session.ini";
	if (file_exists(global.sgcSessionPath)) {
		file_delete(global.sgcSessionPath);
	}

	global.sgcSignedIn = false;
	global.sgcDisplayName = "";
	global.sgcExternalId = "";
	global.sgcLinkCode = "";
	menuOauthPending = false;
	menuOauthStatusRequestId = -1;
	menuOauthNextPollAt = 0;
	menuOauthDeadlineAt = 0;

	signInOpen = false;
	settingsOpen = false;
	statusText = "[SGC] signed out. saved account data deleted.";
}

function menuActivateSelection() {
	if (selectedButton == 0) menuOpenSignIn();
	if (selectedButton == 1) room_goto(RoomTableLobby);
	if (selectedButton == 2) {
		settingsOpen = true;
		statusText = "[SYS] settings panel is blank for now.";
	}
	if (selectedButton == 3) menuSignOut();
}

if (menuOauthPending && global.sgcExternalId != "") {
	if (current_time >= menuOauthDeadlineAt) {
		menuOauthPending = false;
		menuOauthStatusRequestId = -1;
		statusText = "[SGC] sign-in timed out. click Sign In to try again.";
	}
	else if (menuOauthStatusRequestId < 0 && current_time >= menuOauthNextPollAt) {
		var statusBaseUrl = variable_global_exists("sgcBrokerHttpBase") ? string_trim(global.sgcBrokerHttpBase) : "https://sadgirlsclub.wtf";
		if (statusBaseUrl == "") statusBaseUrl = "https://sadgirlsclub.wtf";
		var statusUrl = statusBaseUrl + "/sgc/oauth/status?external_id=" + menuUrlComponent(global.sgcExternalId);
		menuOauthStatusRequestId = http_get(statusUrl);
		menuOauthNextPollAt = current_time + 1000;
	}
}

if (signInOpen) {
	// Button hover detection - verify structs exist first
	if (!is_struct(signInOAuthButton) || !is_struct(signInCancelButton)) {
		statusText = "[ERROR] Button structs not initialized!";
		exit;
	}
	
	var overOAuth   = point_in_rectangle(mouseXPos, mouseYPos, signInOAuthButton.x,   signInOAuthButton.y,   signInOAuthButton.x   + signInOAuthButton.w,   signInOAuthButton.y   + signInOAuthButton.h);
	var overCancel  = point_in_rectangle(mouseXPos, mouseYPos, signInCancelButton.x,  signInCancelButton.y,  signInCancelButton.x  + signInCancelButton.w,  signInCancelButton.y  + signInCancelButton.h);
	
	if (overOAuth) {
		hoveredButton = "signin_oauth";
		statusText = "Click to authenticate with Discord";
	}
	else if (overCancel) {
		hoveredButton = "signin_cancel";
		statusText = "Cancel sign-in";
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
		selectedButton = min(3, selectedButton + 1);
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

	if (point_in_rectangle(mouseXPos, mouseYPos, signOutButton.x, signOutButton.y, signOutButton.x + signOutButton.w, signOutButton.y + signOutButton.h)) {
		hoveredButton = "signout";
		selectedButton = 3;
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
		else if (hoveredButton == "signout") menuSignOut();
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