titleText = "SADGIRLSCLUB.WTF";
subtitleText = "DollOS V-3.0 // LumiGames Casino";
statusText = "[SYS] choose a node.";
settingsOpen = false;
selectedButton = 0;

backgroundTop = make_color_rgb(5, 6, 10);
backgroundBottom = make_color_rgb(34, 15, 38);
panelColor = make_color_rgb(16, 15, 25);
lineColor = make_color_rgb(93, 228, 207);
buttonColor = make_color_rgb(30, 24, 43);
buttonHoverColor = make_color_rgb(213, 43, 102);
buttonAltColor = make_color_rgb(18, 25, 34);
buttonAltHoverColor = make_color_rgb(42, 64, 72);
textColor = c_white;

buttonWidth = 320;
buttonHeight = 64;
buttonGap = 24;
buttonX = room_width * 0.5 - (buttonWidth * 0.5);
buttonY = room_height * 0.5 - buttonHeight;

playButton = {
	x: buttonX,
	y: buttonY,
	w: buttonWidth,
	h: buttonHeight,
	label: "Play Roulette"
};

tableGamesButton = {
	x: buttonX,
	y: buttonY + buttonHeight + buttonGap,
	w: buttonWidth,
	h: buttonHeight,
	label: "Table Games"
};

settingsButton = {
	x: buttonX,
	y: buttonY + (buttonHeight + buttonGap) * 2,
	w: buttonWidth,
	h: buttonHeight,
	label: "Settings"
};

settingsPanel = {
	x1: room_width * 0.5 - 290,
	y1: 150,
	x2: room_width * 0.5 + 290,
	y2: room_height - 130
};

settingsCloseButton = {
	x: room_width * 0.5 - 110,
	y: room_height - 220,
	w: 220,
	h: 52,
	label: "Back"
};

hoveredButton = "";