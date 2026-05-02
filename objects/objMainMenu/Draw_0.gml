draw_clear_alpha(backgroundTop, 1);

for (var stripe = 0; stripe < room_height; stripe += 6) {
	var blend = stripe / room_height;
	draw_set_color(merge_color(backgroundTop, backgroundBottom, blend));
	draw_rectangle(0, stripe, room_width, stripe + 6, false);
}

draw_set_alpha(0.92);
draw_set_color(panelColor);
draw_roundrect(room_width * 0.5 - 260, 110, room_width * 0.5 + 260, room_height - 110, false);
draw_set_alpha(1);

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(lineColor);
draw_text(room_width * 0.5, 175, titleText);
draw_text(room_width * 0.5, 215, subtitleText);

var signInSelected   = (hoveredButton == "signin")   || (!settingsOpen && !signInOpen && selectedButton == 0);
var playSelected     = (hoveredButton == "play")     || (!settingsOpen && !signInOpen && selectedButton == 1);
var settingsSelected = (hoveredButton == "settings") || (!settingsOpen && !signInOpen && selectedButton == 2);

var signInFill   = signInSelected   ? buttonHoverColor    : buttonColor;
var playFill     = playSelected     ? buttonHoverColor    : buttonColor;
var settingsFill = settingsSelected ? buttonAltHoverColor : buttonAltColor;

// Sign-in button (with badge showing current state).
draw_set_color(signInFill);
draw_roundrect(signInButton.x, signInButton.y, signInButton.x + signInButton.w, signInButton.y + signInButton.h, false);
draw_set_color(lineColor);
draw_roundrect(signInButton.x, signInButton.y, signInButton.x + signInButton.w, signInButton.y + signInButton.h, true);
draw_set_color(textColor);
draw_text(signInButton.x + signInButton.w * 0.5, signInButton.y + signInButton.h * 0.5 - 8, signInButton.label);
draw_set_color(global.sgcSignedIn ? lineColor : make_color_rgb(180, 180, 180));
var badge = global.sgcSignedIn
	? "linked: " + (global.sgcDisplayName != "" ? global.sgcDisplayName : global.sgcExternalId)
	: "guest mode (click to link)";
draw_text(signInButton.x + signInButton.w * 0.5, signInButton.y + signInButton.h * 0.5 + 14, badge);

// Play button.
draw_set_color(playFill);
draw_roundrect(playButton.x, playButton.y, playButton.x + playButton.w, playButton.y + playButton.h, false);
draw_set_color(lineColor);
draw_roundrect(playButton.x, playButton.y, playButton.x + playButton.w, playButton.y + playButton.h, true);
draw_set_color(textColor);
draw_text(playButton.x + playButton.w * 0.5, playButton.y + playButton.h * 0.5, playButton.label);

// Settings button.
draw_set_color(settingsFill);
draw_roundrect(settingsButton.x, settingsButton.y, settingsButton.x + settingsButton.w, settingsButton.y + settingsButton.h, false);
draw_set_color(lineColor);
draw_roundrect(settingsButton.x, settingsButton.y, settingsButton.x + settingsButton.w, settingsButton.y + settingsButton.h, true);
draw_set_color(textColor);
draw_text(settingsButton.x + settingsButton.w * 0.5, settingsButton.y + settingsButton.h * 0.5, settingsButton.label);

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(lineColor);
draw_text(room_width * 0.5, settingsButton.y + settingsButton.h + 50, statusText);
draw_text(room_width * 0.5, room_height - 78, "> ARROWS/WASD + ENTER // ESC where available");

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

if (signInOpen) {
	draw_set_alpha(0.78);
	draw_set_color(c_black);
	draw_rectangle(0, 0, room_width, room_height, false);
	draw_set_alpha(1);

	draw_set_color(make_color_rgb(22, 14, 32));
	draw_roundrect(signInPanel.x1, signInPanel.y1, signInPanel.x2, signInPanel.y2, false);
	draw_set_color(lineColor);
	draw_roundrect(signInPanel.x1, signInPanel.y1, signInPanel.x2, signInPanel.y2, true);

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(textColor);
	draw_text(room_width * 0.5, signInPanel.y1 + 50, "SIGN IN // SADGIRLCOIN");
	draw_set_color(lineColor);
	draw_text(room_width * 0.5, signInPanel.y1 + 110, "One-click Discord OAuth authentication");

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);

	var oauthFill = (hoveredButton == "signin_oauth") ? buttonHoverColor : make_color_rgb(40, 30, 64);
	var cancelFill  = (hoveredButton == "signin_cancel")  ? buttonAltHoverColor : buttonAltColor;

	// Draw OAuth button
	draw_set_color(oauthFill);
	draw_roundrect(signInOAuthButton.x, signInOAuthButton.y, signInOAuthButton.x + signInOAuthButton.w, signInOAuthButton.y + signInOAuthButton.h, false);
	draw_set_color(lineColor);
	draw_roundrect(signInOAuthButton.x, signInOAuthButton.y, signInOAuthButton.x + signInOAuthButton.w, signInOAuthButton.y + signInOAuthButton.h, true);
	draw_set_color(textColor);
	draw_text(signInOAuthButton.x + signInOAuthButton.w * 0.5, signInOAuthButton.y + signInOAuthButton.h * 0.5, signInOAuthButton.label);

	// Draw Cancel button
	draw_set_color(cancelFill);
	draw_roundrect(signInCancelButton.x, signInCancelButton.y, signInCancelButton.x + signInCancelButton.w, signInCancelButton.y + signInCancelButton.h, false);
	draw_set_color(lineColor);
	draw_roundrect(signInCancelButton.x, signInCancelButton.y, signInCancelButton.x + signInCancelButton.w, signInCancelButton.y + signInCancelButton.h, true);
	draw_set_color(textColor);
	draw_text(signInCancelButton.x + signInCancelButton.w * 0.5, signInCancelButton.y + signInCancelButton.h * 0.5, signInCancelButton.label);
}