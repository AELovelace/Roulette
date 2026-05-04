// Main menu boot/setup.
// Micro-adjust here: default status copy, persisted SGC identity fields, and menu panel sizing/colors.
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
if (!variable_global_exists("sgcReturnToUrl")) global.sgcReturnToUrl = "";
if (!variable_global_exists("sgcOauthPending")) global.sgcOauthPending = false;
if (!variable_global_exists("sgcOauthSessionId")) global.sgcOauthSessionId = "";
if (!variable_global_exists("sgcSfxVolume")) global.sgcSfxVolume = 0.7;
if (!variable_global_exists("sgcSessionPath")) global.sgcSessionPath = "sgc_session.ini";

if (file_exists(global.sgcSessionPath)) {
	ini_open(global.sgcSessionPath);
	global.sgcSignedIn = ini_read_real("sgc", "signed_in", global.sgcSignedIn ? 1 : 0) == 1;
	global.sgcDisplayName = ini_read_string("sgc", "display_name", global.sgcDisplayName);
	global.sgcExternalId = ini_read_string("sgc", "external_id", global.sgcExternalId);
	global.sgcLinkCode = ini_read_string("sgc", "link_code", global.sgcLinkCode);
	global.sgcBrokerHttpBase = ini_read_string("sgc", "broker_http_base", global.sgcBrokerHttpBase);
	global.sgcReturnToUrl = ini_read_string("sgc", "return_to_url", global.sgcReturnToUrl);
	global.sgcOauthPending = ini_read_real("sgc", "oauth_pending", global.sgcOauthPending ? 1 : 0) == 1;
	global.sgcOauthSessionId = ini_read_string("sgc", "oauth_session_id", global.sgcOauthSessionId);
	global.sgcSfxVolume = clamp(ini_read_real("sgc", "sfx_volume", global.sgcSfxVolume), 0, 1);
	ini_close();
}

if (string_pos("player_", string_lower(string_trim(global.sgcExternalId))) == 1) {
	global.sgcExternalId = "";
	global.sgcSignedIn = false;
}

oauthPollRequestId = -1;
oauthPollCooldown = 0;
oauthAwaitingBrowserLink = global.sgcOauthPending && string_trim(global.sgcOauthSessionId) != "";
if (oauthAwaitingBrowserLink) {
	signInOpen = true;
	statusText = "[SGC] resuming OAuth sign-in...";
	oauthPollCooldown = 1;
}

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
buttonX = VIEW_W * 0.5 - buttonWidth * 0.5;
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

arcadeButton = {
	x: buttonX,
	y: buttonY + (buttonHeight + buttonGap) * 2,
	w: buttonWidth,
	h: buttonHeight,
	label: "Arcade Games"
};

settingsButton = {
	x: buttonX,
	y: buttonY + (buttonHeight + buttonGap) * 3,
	w: buttonWidth,
	h: buttonHeight,
	label: "Settings"
};

settingsPanel = {
	x1: VIEW_W * 0.5 - 290,
	y1: 150,
	x2: VIEW_W * 0.5 + 290,
	y2: VIEW_H - 130
};

// Sign In modal layout.
signInPanel = {
	x1: VIEW_W * 0.5 - 320,
	y1: 80,
	x2: VIEW_W * 0.5 + 320,
	y2: VIEW_H - 80
};



signInOAuthButton = {
	x: signInPanel.x1 + 40,
	y: signInPanel.y1 + 140,
	w: (signInPanel.x2 - signInPanel.x1) - 80,
	h: 80,
	label: "Continue with Discord OAuth"
};
signInSignOutButton = {
	x: signInPanel.x1 + 40,
	y: signInPanel.y1 + 240,
	w: (signInPanel.x2 - signInPanel.x1) - 80,
	h: 64,
	label: "Sign Out On This Device"
};
signInCancelButton = {
	x: VIEW_W * 0.5 - 100,
	y: signInPanel.y2 - 80,
	w: 200,
	h: 56,
	label: "Cancel"
};

settingsCloseButton = {
	x: VIEW_W * 0.5 - 110,
	y: VIEW_H - 220,
	w: 220,
	h: 52,
	label: "Back"
};

hoveredButton = "";