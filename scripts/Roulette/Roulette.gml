/// @desc VIEW_W / VIEW_H   — dynamic window dimensions (replaces room_width/room_height for layout)
#macro VIEW_W display_get_gui_width()
#macro VIEW_H display_get_gui_height()

/// @desc Resize the application surface and GUI layer to match the OS window each step.
function viewResize() {
	var _ww = max(100, window_get_width());
	var _wh = max(100, window_get_height());
	if (surface_get_width(application_surface) != _ww || surface_get_height(application_surface) != _wh) {
		surface_resize(application_surface, _ww, _wh);
		display_set_gui_size(_ww, _wh);
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