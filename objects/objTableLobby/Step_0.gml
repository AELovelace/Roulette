// Table lobby interaction loop.
// Micro-adjust here: navigation model (keyboard vs mouse), selection movement, and room transitions.
var mouseXPos = device_mouse_x_to_gui(0);
var mouseYPos = device_mouse_y_to_gui(0);
hoveredButton = "";

viewResize();
var backButton = { x: VIEW_W - 178, y: 20, w: 148, h: 42, label: "Main Menu" };

if (keyboard_check_pressed(vk_escape)) {
	room_goto(RoomMenu);
}

if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))) {
	selectedTable = max(0, selectedTable - 1);
}

if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) {
	selectedTable = min(array_length(tableNames) - 1, selectedTable + 1);
}

if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
	selectedTable = max(0, selectedTable - 3);
}

if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
	selectedTable = min(array_length(tableNames) - 1, selectedTable + 3);
}

if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
	enterSelectedTable();
}

if (pointInLobbyButton(backButton, mouseXPos, mouseYPos)) {
	hoveredButton = "back";
}

for (var i = 0; i < array_length(tableNames); i += 1) {
	var button = lobbyButton(i);
	if (pointInLobbyButton(button, mouseXPos, mouseYPos)) {
		hoveredButton = "table_" + string(i);
		selectedTable = i;
	}
}

if (mouse_check_button_pressed(mb_left)) {
	if (hoveredButton == "back") {
		room_goto(RoomMenu);
	}
	if (string_copy(hoveredButton, 1, 6) == "table_") {
		enterSelectedTable();
	}
}