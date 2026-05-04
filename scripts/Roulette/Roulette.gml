// Shared utility script used across menu, roulette, and table scenes.
// Micro-adjust here: resize policy, safe JSON/network helpers, and reusable roulette math helpers.
/// @desc VIEW_W / VIEW_H   — dynamic window dimensions (replaces room_width/room_height for layout)
#macro VIEW_W display_get_gui_width()
#macro VIEW_H display_get_gui_height()

/// @desc Resize the application surface and GUI layer to match the OS window each step.
function viewResize() {
	var _ww, _wh;
	if (os_browser != browser_not_a_browser) {
		// HTML5: resize the canvas element to fill the viewport exactly.
		// CSS overflow:hidden (injected via jsprepend) prevents scrollbars.
		_ww = max(100, browser_width);
		_wh = max(100, browser_height);
		// Different browsers/runners can report different values; prefer the largest
		// to avoid clipping to a stale or constrained dimension source.
		_ww = max(_ww, window_get_width());
		_wh = max(_wh, window_get_height());
		_ww = max(_ww, display_get_width());
		_wh = max(_wh, display_get_height());
		if (window_get_width() != _ww || window_get_height() != _wh) {
			window_set_size(_ww, _wh);
		}
	} else {
		_ww = max(100, window_get_width());
		_wh = max(100, window_get_height());
	}
	if (surface_exists(application_surface)
		&& (surface_get_width(application_surface) != _ww || surface_get_height(application_surface) != _wh)) {
		surface_resize(application_surface, _ww, _wh);
		display_set_gui_size(_ww, _wh);
	}
	// Enable views and sync camera + port so room-space Draw events
	// use the same coordinate space as the resized surface.
	view_enabled = true;
	view_visible[0] = true;
	camera_set_view_pos(view_camera[0], 0, 0);
	camera_set_view_size(view_camera[0], _ww, _wh);
	view_xport[0] = 0;
	view_yport[0] = 0;
	view_wport[0] = _ww;
	view_hport[0] = _wh;
	display_set_gui_size(_ww, _wh);
}

function rouletteGetSfxVolume() {
	if (!variable_global_exists("sgcSfxVolume")) {
		global.sgcSfxVolume = 0.7;
	}
	return clamp(real(global.sgcSfxVolume), 0, 1);
}

function rouletteSetSfxVolume(_volume) {
	global.sgcSfxVolume = clamp(real(_volume), 0, 1);
}

function rouletteEnsureTurnDingSound() {
	if (!variable_global_exists("sgcTurnDingSoundId")) {
		global.sgcTurnDingSoundId = -1;
	}
	if (global.sgcTurnDingSoundId != -1) {
		return global.sgcTurnDingSoundId;
	}

	var _soundId = -1;
	if (file_exists("sounds/ding/ding.wav")) {
		_soundId = audio_create_stream("sounds/ding/ding.wav");
	} else if (file_exists("ding.wav")) {
		_soundId = audio_create_stream("ding.wav");
	}

	global.sgcTurnDingSoundId = _soundId;
	return global.sgcTurnDingSoundId;
}

function roulettePlayTurnDing() {
	var _soundId = rouletteEnsureTurnDingSound();
	if (_soundId == -1) return;
	var _voice = audio_play_sound(_soundId, 0, false);
	if (_voice != -1) {
		audio_sound_gain(_voice, rouletteGetSfxVolume(), 0);
	}
}

function angleNorm(_a){
	return((_a mod 360) + 360) mod 360;
}

function getWinningNumber(_rotation, _ballAngle, _zeroOffset, _order, _segment){
	var local = angleNorm(_rotation - _ballAngle + _zeroOffset);
	
	var idx = floor((local+_segment*0.5)/_segment)mod array_length(_order);
	return _order[idx];
}

function rouletteArrayContains(_values, _target){
	for (var i = 0; i < array_length(_values); i++) {
		if (_values[i] == _target) {
			return true;
		}
	}

	return false;
}

function rouletteIsRed(_number){
	switch (_number) {
		case 1:
		case 3:
		case 5:
		case 7:
		case 9:
		case 12:
		case 14:
		case 16:
		case 18:
		case 19:
		case 21:
		case 23:
		case 25:
		case 27:
		case 30:
		case 32:
		case 34:
		case 36:
			return true;
	}

	return false;
}

function rouletteGetTotalBet(_betAreas){
	var total = 0;

	for (var i = 0; i < array_length(_betAreas); i++) {
		total += _betAreas[i].amount;
	}

	return total;
}

function rouletteSendJson(_socket, _payload){
	if (_socket < 0) {
		return -1;
	}

	var message = json_stringify(_payload);
	var messageBuffer = buffer_create(string_length(message) + 1, buffer_grow, 1);
	buffer_write(messageBuffer, buffer_string, message);
	var sent = network_send_raw(_socket, messageBuffer, buffer_tell(messageBuffer), network_send_text);
	buffer_delete(messageBuffer);
	return sent;
}

function rouletteStructGet(_struct, _key, _default){
	if (is_struct(_struct) && variable_struct_exists(_struct, _key)) {
		return variable_struct_get(_struct, _key);
	}

	return _default;
}

function rouletteApplyBetState(_betAreas, _yourBets, _tableTotals){
	for (var i = 0; i < array_length(_betAreas); i++) {
		var area = _betAreas[i];
		area.amount = rouletteStructGet(_yourBets, area.key, 0);
		area.totalAmount = rouletteStructGet(_tableTotals, area.key, 0);
	}
}