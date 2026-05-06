// Shared utility script used across menu, roulette, and table scenes.
// Micro-adjust here: resize policy, safe JSON/network helpers, and reusable roulette math helpers.
/// @desc VIEW_W / VIEW_H   — dynamic window dimensions (replaces room_width/room_height for layout)
#macro VIEW_W display_get_gui_width()
#macro VIEW_H display_get_gui_height()

/// @desc Resize the application surface and GUI layer to match the OS window each step.
function viewResize() {
	var _ww, _wh;
	if (os_browser != browser_not_a_browser) {
		// In embedded HTML5 builds, browser_* tracks the iframe viewport.
		// Using the host display size here causes the canvas to overshoot its container.
		var _browserW = browser_width;
		var _browserH = browser_height;
		var _windowW = window_get_width();
		var _windowH = window_get_height();
		if (_browserW > 0 && _browserH > 0) {
			_ww = _browserW;
			_wh = _browserH;
		} else {
			_ww = _windowW;
			_wh = _windowH;
		}
		_ww = max(100, _ww);
		_wh = max(100, _wh);
		if (_windowW != _ww || _windowH != _wh) {
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

function breakoutHideBoard() {
	with (objBrick) { instance_destroy(); }
	with (objBall) { instance_destroy(); }
	with (objBallExtra) { instance_destroy(); }
	with (objPowerUp) { instance_destroy(); }
	breakoutClearBounds();
}

function breakoutSetBounds(_x, _y, _w, _h) {
	global.breakoutBoundsActive = true;
	global.breakoutBoundsLeft = _x;
	global.breakoutBoundsTop = _y;
	global.breakoutBoundsRight = _x + _w;
	global.breakoutBoundsBottom = _y + _h;
	global.breakoutSpawnX = _x + _w * 0.5;
	global.breakoutSpawnY = _y + _h - 64;
}

function breakoutClearBounds() {
	global.breakoutBoundsActive = false;
	global.breakoutBoundsLeft = 0;
	global.breakoutBoundsTop = 0;
	global.breakoutBoundsRight = room_width;
	global.breakoutBoundsBottom = room_height;
	global.breakoutSpawnX = room_width * 0.5;
	global.breakoutSpawnY = room_height - 64;
}

function breakoutResetBat() {
	if (!instance_exists(objBat)) return;
	var left = variable_global_exists("breakoutBoundsLeft") ? global.breakoutBoundsLeft : 0;
	var right = variable_global_exists("breakoutBoundsRight") ? global.breakoutBoundsRight : room_width;
	var bottom = variable_global_exists("breakoutBoundsBottom") ? global.breakoutBoundsBottom : room_height;
	with (objBat) {
		x = (left + right) * 0.5;
		y = bottom - 16;
		xstart = x;
		ystart = y;
		image_xscale = 1;
	}
}

function breakoutResetBallStack() {
	with (objBall) { instance_destroy(); }
	with (objBallExtra) { instance_destroy(); }
	with (objPowerUp) { instance_destroy(); }
	var spawnX = variable_global_exists("breakoutSpawnX") ? global.breakoutSpawnX : room_width * 0.5;
	var spawnY = variable_global_exists("breakoutSpawnY") ? global.breakoutSpawnY : room_height - 64;
	instance_create_layer(spawnX, spawnY, "Instances", objBall);
}

function breakoutBuildRandomField(_gridCols, _gridRows, _gridCell, _gridStartX, _gridStartY) {
	function _markCell(_grid, _col, _row, _cols, _rows) {
		if (_col < 0 || _col >= _cols) return;
		if (_row < 0 || _row >= _rows) return;
		_grid[_row][_col] = true;
	}

	function _stampPattern(_grid, _cells, _baseCol, _baseRow, _cols, _rows) {
		for (var i = 0; i < array_length(_cells); i++) {
			var cell = _cells[i];
			_markCell(_grid, _baseCol + cell[0], _baseRow + cell[1], _cols, _rows);
		}
	}

	function _countCells(_grid, _cols, _rows) {
		var total = 0;
		for (var r = 0; r < _rows; r++) {
			for (var c = 0; c < _cols; c++) {
				if (_grid[r][c]) total += 1;
			}
		}
		return total;
	}

	var heart = [
		[1, 0], [2, 0], [4, 0], [5, 0],
		[0, 1], [1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [6, 1],
		[1, 2], [2, 2], [3, 2], [4, 2], [5, 2],
		[2, 3], [3, 3], [4, 3],
		[3, 4]
	];
	var star = [
		[3, 0],
		[2, 1], [3, 1], [4, 1],
		[0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2],
		[1, 3], [2, 3], [3, 3], [4, 3], [5, 3],
		[2, 4], [4, 4],
		[2, 5], [4, 5]
	];
	var box = [
		[0, 0], [1, 0], [2, 0], [3, 0], [4, 0], [5, 0],
		[0, 1], [5, 1],
		[0, 2], [5, 2],
		[0, 3], [5, 3],
		[0, 4], [1, 4], [2, 4], [3, 4], [4, 4], [5, 4]
	];
	var rectangle = [
		[0, 0], [1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0], [7, 0],
		[0, 1], [1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [6, 1], [7, 1],
		[0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2]
	];

	var grid = array_create(_gridRows);
	for (var r = 0; r < _gridRows; r++) grid[r] = array_create(_gridCols, false);

	var shapeCount = irandom_range(2, 3);
	for (var s = 0; s < shapeCount; s++) {
		var roll = irandom(15);
		var pattern = rectangle;
		var patternW = 8;
		var patternH = 3;
		if (roll <= 4) {
			pattern = rectangle;
			patternW = 8;
			patternH = 3;
		} else if (roll <= 8) {
			pattern = box;
			patternW = 6;
			patternH = 5;
		} else if (roll <= 11) {
			pattern = heart;
			patternW = 7;
			patternH = 5;
		} else {
			pattern = star;
			patternW = 7;
			patternH = 6;
		}
		var baseCol = irandom_range(0, max(0, _gridCols - patternW));
		var baseRow = irandom_range(0, max(0, _gridRows - patternH));
		_stampPattern(grid, pattern, baseCol, baseRow, _gridCols, _gridRows);
	}

	while (_countCells(grid, _gridCols, _gridRows) < 30) {
		var fillW = irandom_range(3, 6);
		var fillH = irandom_range(1, 2);
		var fillCol = irandom_range(0, max(0, _gridCols - fillW));
		var fillRow = irandom_range(0, max(0, _gridRows - fillH));
		for (var fy = 0; fy < fillH; fy++) {
			for (var fx = 0; fx < fillW; fx++) {
				_markCell(grid, fillCol + fx, fillRow + fy, _gridCols, _gridRows);
			}
		}
	}

	with (objBrick) { instance_destroy(); }
	for (var row = 0; row < _gridRows; row++) {
		for (var col = 0; col < _gridCols; col++) {
			if (grid[row][col]) {
				instance_create_layer(_gridStartX + col * _gridCell, _gridStartY + row * _gridCell, "Instances", objBrick);
			}
		}
	}
}

function breakoutBuildSeededField(_gridCols, _gridRows, _gridCell, _gridStartX, _gridStartY, _seed) {
	var previousSeed = random_get_seed();
	random_set_seed(max(1, floor(abs(_seed))));
	breakoutBuildRandomField(_gridCols, _gridRows, _gridCell, _gridStartX, _gridStartY);
	random_set_seed(previousSeed);
}

function breakoutLevelSeed(_ctrl, _level) {
	var raceSeed = max(1, floor(abs(_ctrl.showdownRaceSeed)));
	var levelIndex = max(1, floor(_level));
	var mix = (raceSeed * 1664525 + levelIndex * 1013904223) mod 2147483647;
	if (mix <= 0) mix += 2147483646;
	return mix;
}

function breakoutDistance(_ctrl) {
	return (max(1, _ctrl.level) - 1) * 100 + max(0, global.BOPScore);
}

function breakoutBeginRun(_ctrl) {
	global.BOPScore = 0;
	global.BOPLives = 3;
	_ctrl.level = 1;
	_ctrl.payoutSettled = false;
	_ctrl.lastRunPayout = 0;
	_ctrl.runNet = -_ctrl.entryCost;
	_ctrl.localRaceSubmitted = false;
	_ctrl.showdownLocalFinished = false;
	if (_ctrl.mode == "showdown") {
		_ctrl.localRaceSeedStarted = _ctrl.showdownRaceSeed;
		_ctrl.gridRows = _ctrl.showdownGridRows;
		_ctrl.currentArenaX = (_ctrl.breakoutPlayerId != "" && _ctrl.breakoutPlayerId == _ctrl.showdownPlayer2Id) ? _ctrl.showdownArenaRightX : _ctrl.showdownArenaLeftX;
		_ctrl.currentArenaY = _ctrl.showdownArenaY;
	} else {
		_ctrl.gridRows = _ctrl.defaultGridRows;
		_ctrl.currentArenaX = _ctrl.soloArenaX;
		_ctrl.currentArenaY = _ctrl.soloArenaY;
	}
	_ctrl.gridStartX = _ctrl.currentArenaX + 32;
	_ctrl.gridStartY = _ctrl.currentArenaY + 32;
	breakoutSetBounds(_ctrl.currentArenaX, _ctrl.currentArenaY, _ctrl.arenaW, _ctrl.arenaH);
	breakoutResetBat();
	if (_ctrl.mode == "showdown" && _ctrl.showdownRaceSeed > 0) {
		breakoutBuildSeededField(_ctrl.gridCols, _ctrl.gridRows, _ctrl.gridCell, _ctrl.gridStartX, _ctrl.gridStartY, breakoutLevelSeed(_ctrl, _ctrl.level));
	} else {
		breakoutBuildRandomField(_ctrl.gridCols, _ctrl.gridRows, _ctrl.gridCell, _ctrl.gridStartX, _ctrl.gridStartY);
	}
	breakoutResetBallStack();
	_ctrl.state = "PLAYING";
	_ctrl.statusText = _ctrl.mode == "showdown" ? "Showdown race live." : "[SGC] Run started.";
}

function breakoutAdvanceLevel(_ctrl) {
	_ctrl.level += 1;
	_ctrl.statusText = "[LEVEL] Cleared. Generating level " + string(_ctrl.level) + ".";
	if (_ctrl.mode == "showdown" && _ctrl.showdownRaceSeed > 0) {
		breakoutBuildSeededField(_ctrl.gridCols, _ctrl.gridRows, _ctrl.gridCell, _ctrl.gridStartX, _ctrl.gridStartY, breakoutLevelSeed(_ctrl, _ctrl.level));
	} else {
		breakoutBuildRandomField(_ctrl.gridCols, _ctrl.gridRows, _ctrl.gridCell, _ctrl.gridStartX, _ctrl.gridStartY);
	}
	breakoutResetBallStack();
}

function breakoutRequestSoloStart(_ctrl) {
	_ctrl.mode = "solo";
	if (_ctrl.breakoutBrokerConnected) {
		_ctrl.soloStartPending = true;
		_ctrl.statusText = "[SGC] Requesting 25-coin deposit...";
		rouletteSendJson(_ctrl.breakoutBrokerSocket, { type: "breakout_single_start" });
	} else {
		if (global.sgcArcadeBalance < _ctrl.entryCost) {
			_ctrl.statusText = "[SGC] Need " + string(_ctrl.entryCost) + " coins to start.";
			return;
		}
		global.sgcArcadeBalance -= _ctrl.entryCost;
		_ctrl.runCharged = true;
		breakoutBeginRun(_ctrl);
	}
}

function breakoutRequestShowdownWatch(_ctrl) {
	_ctrl.mode = "showdown";
	_ctrl.state = "SHOWDOWN_LOBBY";
	_ctrl.statusText = "Joining Breakout showdown...";
	breakoutHideBoard();
	if (_ctrl.breakoutBrokerConnected) {
		rouletteSendJson(_ctrl.breakoutBrokerSocket, { type: "table_watch", game: _ctrl.showdownGameKey });
	}
}

function breakoutReadTelemetry(_ctrl) {
	var out = {
		batNorm: 0.5,
		ballXNorm: 0.5,
		ballYNorm: 0.85,
		brickCount: instance_number(objBrick),
		brickMask: "",
		brickColorMask: ""
	};
	var ax = _ctrl.currentArenaX;
	var ay = _ctrl.currentArenaY;
	var aw = max(1, _ctrl.arenaW);
	var ah = max(1, _ctrl.arenaH);

	if (instance_exists(objBat)) {
		out.batNorm = clamp((objBat.x - ax) / aw, 0, 1);
	}
	if (instance_exists(objBall)) {
		out.ballXNorm = clamp((objBall.x - ax) / aw, 0, 1);
		out.ballYNorm = clamp((objBall.y - ay) / ah, 0, 1);
	} else if (instance_exists(objBallExtra)) {
		out.ballXNorm = clamp((objBallExtra.x - ax) / aw, 0, 1);
		out.ballYNorm = clamp((objBallExtra.y - ay) / ah, 0, 1);
	}

	var marks = array_create(_ctrl.gridCols * _ctrl.gridRows, 0);
	var colors = array_create(_ctrl.gridCols * _ctrl.gridRows, 0);
	for (var i = 0; i < instance_number(objBrick); i++) {
		var b = instance_find(objBrick, i);
		if (!instance_exists(b)) continue;
		var c = round((b.x - _ctrl.gridStartX) / _ctrl.gridCell);
		var r = round((b.y - _ctrl.gridStartY) / _ctrl.gridCell);
		if (c >= 0 && c < _ctrl.gridCols && r >= 0 && r < _ctrl.gridRows) {
			var idx = r * _ctrl.gridCols + c;
			marks[idx] = 1;
			var blend = b.image_blend;
			var colorCode = 6;
			if (blend == c_red) colorCode = 1;
			else if (blend == c_yellow) colorCode = 2;
			else if (blend == c_blue) colorCode = 3;
			else if (blend == c_green) colorCode = 4;
			else if (blend == c_fuchsia) colorCode = 5;
			colors[idx] = colorCode;
		}
	}

	for (var m = 0; m < array_length(marks); m++) {
		out.brickMask += string(marks[m]);
		out.brickColorMask += string(colors[m]);
	}
	return out;
}