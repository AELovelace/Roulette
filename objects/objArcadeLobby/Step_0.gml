// Arcade lobby interaction loop.
var mouseXPos = device_mouse_x_to_gui(0);
var mouseYPos = device_mouse_y_to_gui(0);
hoveredButton = "";

viewResize();
var backButton = { x: VIEW_W - 178, y: 20, w: 148, h: 42, label: "Main Menu" };

if (keyboard_check_pressed(vk_escape)) {
	room_goto(RoomMenu);
}

if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))) {
	selectedArcade = max(0, selectedArcade - 1);
	statusText = arcadeStatusFor(selectedArcade);
}

if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) {
	selectedArcade = min(array_length(arcadeNames) - 1, selectedArcade + 1);
	statusText = arcadeStatusFor(selectedArcade);
}

if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
	selectedArcade = max(0, selectedArcade - 3);
	statusText = arcadeStatusFor(selectedArcade);
}

if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
	selectedArcade = min(array_length(arcadeNames) - 1, selectedArcade + 3);
	statusText = arcadeStatusFor(selectedArcade);
}

if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
	enterSelectedArcade();
}

if (pointInArcadeLobbyButton(backButton, mouseXPos, mouseYPos)) {
	hoveredButton = "back";
}

for (var i = 0; i < array_length(arcadeNames); i += 1) {
	var button = arcadeLobbyButton(i);
	if (pointInArcadeLobbyButton(button, mouseXPos, mouseYPos)) {
		hoveredButton = "arcade_" + string(i);
		selectedArcade = i;
		statusText = arcadeStatusFor(selectedArcade);
	}
}

if (mouse_check_button_pressed(mb_left)) {
	if (hoveredButton == "back") {
		room_goto(RoomMenu);
	}
	if (string_copy(hoveredButton, 1, 7) == "arcade_") {
		enterSelectedArcade();
	}
}
