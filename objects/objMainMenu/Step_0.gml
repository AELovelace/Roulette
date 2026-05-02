var mouseXPos = device_mouse_x_to_gui(0);
var mouseYPos = device_mouse_y_to_gui(0);
hoveredButton = "";

function menuOpenSignIn() {
	signInOpen = true;
	signInActiveField = 0;
	signInFields[0].value = global.sgcDisplayName;
	signInFields[1].value = global.sgcExternalId;
	signInFields[2].value = global.sgcLinkCode;
	keyboard_string = signInFields[signInActiveField].value;
	statusText = "[SYS] enter your Sadgirlcoin identity.";
}

function menuConfirmSignIn() {
	// Pull whatever is currently typed in the focused field.
	signInFields[signInActiveField].value = keyboard_string;

	var newName     = string_trim(signInFields[0].value);
	var newExternal = string_trim(signInFields[1].value);
	var newCode     = string_trim(signInFields[2].value);

	if (newName == "") newName = "Player " + string(irandom_range(1000, 9999));

	global.sgcDisplayName = string_copy(newName,     1, min(string_length(newName),     24));
	global.sgcExternalId  = string_copy(newExternal, 1, min(string_length(newExternal), 64));
	global.sgcLinkCode    = string_copy(newCode,     1, min(string_length(newCode),     16));
	global.sgcSignedIn    = (global.sgcExternalId != "");

	signInOpen = false;
	keyboard_string = "";
	statusText = global.sgcSignedIn
		? "[SGC] signed in as " + global.sgcDisplayName + " (" + global.sgcExternalId + ")."
		: "[SYS] guest mode active. add an external_id to link Sadgirlcoin.";
}

function menuCancelSignIn() {
	signInOpen = false;
	keyboard_string = "";
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
	if (keyboard_check_pressed(vk_tab)) {
		signInFields[signInActiveField].value = keyboard_string;
		signInActiveField = (signInActiveField + 1) mod array_length(signInFields);
		keyboard_string = signInFields[signInActiveField].value;
	}

	for (var i = 0; i < array_length(signInFields); i++) {
		var rowY = signInFirstRowY + i * signInRowHeight;
		if (point_in_rectangle(mouseXPos, mouseYPos, signInFieldX, rowY + 22, signInFieldX + signInFieldW, rowY + 64)) {
			if (mouse_check_button_pressed(mb_left)) {
				signInFields[signInActiveField].value = keyboard_string;
				signInActiveField = i;
				keyboard_string = signInFields[signInActiveField].value;
			}
		}
	}

	var overConfirm = point_in_rectangle(mouseXPos, mouseYPos, signInConfirmButton.x, signInConfirmButton.y, signInConfirmButton.x + signInConfirmButton.w, signInConfirmButton.y + signInConfirmButton.h);
	var overCancel  = point_in_rectangle(mouseXPos, mouseYPos, signInCancelButton.x,  signInCancelButton.y,  signInCancelButton.x  + signInCancelButton.w,  signInCancelButton.y  + signInCancelButton.h);
	if (overConfirm) hoveredButton = "signin_confirm";
	else if (overCancel) hoveredButton = "signin_cancel";

	var maxLen = signInFields[signInActiveField].max;
	if (string_length(keyboard_string) > maxLen) keyboard_string = string_copy(keyboard_string, 1, maxLen);

	if (keyboard_check_pressed(vk_enter)) menuConfirmSignIn();
	if (keyboard_check_pressed(vk_escape)) menuCancelSignIn();

	if (mouse_check_button_pressed(mb_left)) {
		if (overConfirm) menuConfirmSignIn();
		else if (overCancel) menuCancelSignIn();
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