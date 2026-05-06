// Arcade lobby renderer.
// Matches table lobby visual format for consistency.
function drawLobbyButton(_button, _selected, _hovered) {
	var fill = _selected ? accentColor : buttonColor;
	if (_hovered) fill = _selected ? accentHoverColor : buttonHoverColor;
	draw_set_color(fill);
	draw_roundrect(_button.x, _button.y, _button.x + _button.w, _button.y + _button.h, false);
	draw_set_color(railColor);
	draw_roundrect(_button.x, _button.y, _button.x + _button.w, _button.y + _button.h, true);
}

draw_clear_alpha(backgroundTop, 1);
for (var stripe = 0; stripe < VIEW_H; stripe += 6) {
	var blend = stripe / VIEW_H;
	draw_set_color(merge_color(backgroundTop, backgroundBottom, blend));
	draw_rectangle(0, stripe, VIEW_W, stripe + 6, false);
}

draw_set_color(make_color_rgb(12, 22, 22));
draw_rectangle(0, 0, VIEW_W, 84, false);
draw_set_color(railColor);
draw_line(0, 84, VIEW_W, 84);

draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_color(textColor);
draw_text(30, 34, "DollOS V-3.33 // LumiGames");
draw_set_color(mutedTextColor);
draw_text(30, 64, "> ARCADE NODES // prototype minigames // SGC.WTF live build");

var backButton = { x: VIEW_W - 178, y: 20, w: 148, h: 42, label: "Main Menu" };
drawLobbyButton(backButton, false, hoveredButton == "back");
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(textColor);
draw_text(backButton.x + backButton.w * 0.5, backButton.y + backButton.h * 0.5, backButton.label);

for (var i = 0; i < array_length(arcadeNames); i += 1) {
	var button = arcadeLobbyButton(i);
	var bx = button.x;
	var by = button.y;
	var bw = button.w;
	var selected = selectedArcade == i;
	var hovered = hoveredButton == "arcade_" + string(i);
	drawLobbyButton(button, selected, hovered);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(textColor);
	draw_text(bx + 26, by + 24, arcadeNames[i]);
	draw_set_color(mutedTextColor);
	draw_text(bx + 26, by + 62, arcadeDescriptions[i]);
	draw_set_color(railColor);
	draw_text(bx + bw - 168, by + 92, arcadeIsAvailable(i) ? "ENTER" : "COMING SOON");
}

draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_color(railColor);
draw_text(30, VIEW_H - 28, statusText);
draw_set_halign(fa_right);
draw_set_color(mutedTextColor);
draw_text(VIEW_W - 30, VIEW_H - 28, "Arrows/WASD: select  |  Enter: enter  |  Esc: menu");
