draw_clear_alpha(backgroundTop, 1);

for (var stripe = 0; stripe < room_height; stripe += 6) {
	var blend = stripe / room_height;
	draw_set_color(merge_color(backgroundTop, backgroundBottom, blend));
	draw_rectangle(0, stripe, room_width, stripe + 6, false);
}

draw_set_alpha(0.92);
draw_set_color(panelColor);
draw_roundrect(room_width * 0.5 - 250, 120, room_width * 0.5 + 250, room_height - 120, false);
draw_set_alpha(1);

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(lineColor);
draw_text(room_width * 0.5, 185, titleText);
draw_text(room_width * 0.5, 225, subtitleText);

var playSelected = (hoveredButton == "play") || (!settingsOpen && selectedButton == 0);
var tablesSelected = (hoveredButton == "tables") || (!settingsOpen && selectedButton == 1);
var settingsSelected = (hoveredButton == "settings") || (!settingsOpen && selectedButton == 2);
var playFill = playSelected ? buttonHoverColor : buttonColor;
var tablesFill = tablesSelected ? buttonHoverColor : buttonColor;
var settingsFill = settingsSelected ? buttonAltHoverColor : buttonAltColor;

draw_set_color(playFill);
draw_roundrect(playButton.x, playButton.y, playButton.x + playButton.w, playButton.y + playButton.h, false);
draw_set_color(lineColor);
draw_roundrect(playButton.x, playButton.y, playButton.x + playButton.w, playButton.y + playButton.h, true);
draw_set_color(textColor);
draw_text(playButton.x + playButton.w * 0.5, playButton.y + playButton.h * 0.5, playButton.label);

draw_set_color(tablesFill);
draw_roundrect(tableGamesButton.x, tableGamesButton.y, tableGamesButton.x + tableGamesButton.w, tableGamesButton.y + tableGamesButton.h, false);
draw_set_color(lineColor);
draw_roundrect(tableGamesButton.x, tableGamesButton.y, tableGamesButton.x + tableGamesButton.w, tableGamesButton.y + tableGamesButton.h, true);
draw_set_color(textColor);
draw_text(tableGamesButton.x + tableGamesButton.w * 0.5, tableGamesButton.y + tableGamesButton.h * 0.5, tableGamesButton.label);

draw_set_color(settingsFill);
draw_roundrect(settingsButton.x, settingsButton.y, settingsButton.x + settingsButton.w, settingsButton.y + settingsButton.h, false);
draw_set_color(lineColor);
draw_roundrect(settingsButton.x, settingsButton.y, settingsButton.x + settingsButton.w, settingsButton.y + settingsButton.h, true);
draw_set_color(textColor);
draw_text(settingsButton.x + settingsButton.w * 0.5, settingsButton.y + settingsButton.h * 0.5, settingsButton.label);

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(lineColor);
draw_text(room_width * 0.5, settingsButton.y + settingsButton.h + 60, statusText);
draw_text(room_width * 0.5, room_height - 90, "> ARROWS/WASD + ENTER // ESC where available");

if (settingsOpen) {
	draw_set_alpha(0.68);
	draw_set_color(c_black);
	draw_rectangle(0, 0, room_width, room_height, false);
	draw_set_alpha(1);

	draw_set_color(make_color_rgb(20, 51, 44));
	draw_roundrect(settingsPanel.x1, settingsPanel.y1, settingsPanel.x2, settingsPanel.y2, false);
	draw_set_color(lineColor);
	draw_roundrect(settingsPanel.x1, settingsPanel.y1, settingsPanel.x2, settingsPanel.y2, true);

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(textColor);
	draw_text(room_width * 0.5, settingsPanel.y1 + 52, "SETTINGS // NOTICE BOARD");
	draw_set_color(lineColor);
	draw_text(room_width * 0.5, settingsPanel.y1 + 118, "[SYS] blank config panel for now.");
	draw_text(room_width * 0.5, settingsPanel.y1 + 154, "LumiGames options can land here later.");

	var closeFill = (hoveredButton == "settings_close") ? buttonAltHoverColor : buttonAltColor;
	draw_set_color(closeFill);
	draw_roundrect(settingsCloseButton.x, settingsCloseButton.y, settingsCloseButton.x + settingsCloseButton.w, settingsCloseButton.y + settingsCloseButton.h, false);
	draw_set_color(lineColor);
	draw_roundrect(settingsCloseButton.x, settingsCloseButton.y, settingsCloseButton.x + settingsCloseButton.w, settingsCloseButton.y + settingsCloseButton.h, true);
	draw_set_color(textColor);
	draw_text(settingsCloseButton.x + settingsCloseButton.w * 0.5, settingsCloseButton.y + settingsCloseButton.h * 0.5, settingsCloseButton.label);

	draw_set_color(lineColor);
	draw_text(room_width * 0.5, settingsCloseButton.y + settingsCloseButton.h + 46, "Press Esc to close.");
}