function spawn_food(_board, _gridW, _gridH) {
    var empty_cells = [];

    for (var xx = 0; xx < _gridW; xx++) {
        for (var yy = 0; yy < _gridH; yy++) {
            if (_board[# xx, yy] == 0) {
                array_push(empty_cells, [xx, yy]);
            }
        }
    }

    if (array_length(empty_cells) <= 0) {
        return false;
    }

    var chosen = empty_cells[irandom(array_length(empty_cells) - 1)];
    var fx = chosen[0];
    var fy = chosen[1];
    var roll = irandom(99);

    if (roll < 70) {
        _board[# fx, fy] = 2;
    } else if (roll < 92) {
        _board[# fx, fy] = 3;
    } else {
        _board[# fx, fy] = 4;
    }

    return true;
}