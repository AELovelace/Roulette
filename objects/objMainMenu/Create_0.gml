titleText = "SADGIRLSCLUB.WTF";
subtitleText = "DollOS V-3.0 // LumiGames Casino";
statusText = "[SYS] choose a node.";
settingsOpen = false;
signInOpen = false;
selectedButton = 0;

// Persistent SGC identity globals (consumed by objWheel / objTableGames on connect).
if (!variable_global_exists("sgcSignedIn"))    global.sgcSignedIn    = false;
if (!variable_global_exists("sgcDisplayName")) global.sgcDisplayName = "";
if (!variable_global_exists("sgcExternalId")) global.sgcExternalId  = "";
if (!variable_global_exists("sgcLinkCode"))    global.sgcLinkCode    = "";
if (!variable_global_exists("sgcBrokerHttpBase")) global.sgcBrokerHttpBase = "https://sadgirlsclub.wtf";

backgroundTop = make_color_rgb(5, 6, 10);
backgroundBottom = make_color_rgb(34, 15, 38);
panelColor = make_color_rgb(16, 15, 25);
lineColor = make_color_rgb(93, 228, 207);
textColor = make_color_rgb(241, 238, 246);
buttonColor = make_color_rgb(30, 24, 43);
buttonHoverColor = make_color_rgb(213, 43, 102);
buttonAltColor = make_color_rgb(18, 25, 34);
buttonAltHoverColor = make_color_rgb(43, 62, 84);

buttonWidth = 360;
buttonHeight = 64;
buttonGap = 20;
buttonX = room_width * 0.5 - buttonWidth * 0.5;
buttonY = 280;

signInButton = {
	x: buttonX,
	y: buttonY,
	w: buttonWidth,
	h: buttonHeight,
	label: "Sign In with Sadgirlcoin"
};

playButton = {
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

// Sign In modal layout.
signInPanel = {
	x1: room_width * 0.5 - 320,
	y1: 80,
	x2: room_width * 0.5 + 320,
	y2: room_height - 80
};

signInFields = [
	{ key: "external", label: "external_id (app user key)",            value: global.sgcExternalId,  max: 64 },
	{ key: "code",     label: "Link Code (optional, e.g. H7K-4QZ)",    value: global.sgcLinkCode,    max: 16 }
];
signInActiveField = 0;
signInRowHeight = 78;
signInFieldX = signInPanel.x1 + 40;
signInFieldW = (signInPanel.x2 - signInPanel.x1) - 80;
signInFirstRowY = signInPanel.y1 + 112;

signInConfirmButton = {
	x: room_width * 0.5 - 220,
	y: signInPanel.y2 - 84,
	w: 200,
	h: 56,
	label: "Confirm"
};
signInOAuthButton = {
	x: room_width * 0.5 - 220,
	y: signInPanel.y2 - 156,
	w: 440,
	h: 52,
	label: "Continue with Discord OAuth"
};
signInCancelButton = {
	x: room_width * 0.5 + 20,
	y: signInPanel.y2 - 84,
	w: 200,
	h: 56,
	label: "Cancel"
};

settingsCloseButton = {
	x: room_width * 0.5 - 110,
	y: room_height - 220,
	w: 220,
	h: 52,
	label: "Back"
};

hoveredButton = "";