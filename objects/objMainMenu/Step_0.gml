var mouseXPos = device_mouse_x_to_gui(0);
var mouseYPos = device_mouse_y_to_gui(0);
hoveredButton = "";

function menuActivateSelection() {
	if (selectedButton == 0) {
		room_goto(RoomTableLobby);
	}

	if (selectedButton == 1) {
		settingsOpen = true;
		statusText = "[SYS] settings panel is blank for now.";
	}
}

if (!settingsOpen) {
	if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
		selectedButton = max(0, selectedButton - 1);
	}

	if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
		selectedButton = min(1, selectedButton + 1);
	}

	if (point_in_rectangle(mouseXPos, mouseYPos, playButton.x, playButton.y, playButton.x + playButton.w, playButton.y + playButton.h)) {
		hoveredButton = "play";
		selectedButton = 0;
	}

	if (point_in_rectangle(mouseXPos, mouseYPos, settingsButton.x, settingsButton.y, settingsButton.x + settingsButton.w, settingsButton.y + settingsButton.h)) {
		hoveredButton = "settings";
		selectedButton = 1;
	}

	if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
		menuActivateSelection();
	}

	if (mouse_check_button_pressed(mb_left)) {
		if (hoveredButton == "play") {
			room_goto(RoomTableLobby);
		}

		if (hoveredButton == "settings") {
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