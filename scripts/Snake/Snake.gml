function spawn_food() {
    var empty_cells = [];

    for (var xx = 0; xx < gridW; xx++) {
        for (var yy = 0; yy < gridH; yy++) {
            if (gameBoard[# xx, yy] == 0) {
                array_push(empty_cells, [xx, yy]);
            }
        }
    }

    if (array_length(empty_cells) <= 0) {
        gameOver = true;
        return;
    }

    var chosen = empty_cells[irandom(array_length(empty_cells) - 1)];

    var fx = chosen[0];
    var fy = chosen[1];
	    // Pick food type
    var roll = irandom(99);

    if (roll < 70) {
        gameBoard[# fx, fy] = 2; // 1-point food
    } else if (roll < 92) {
        gameBoard[# fx, fy] = 3; // 5-point food
    } else {
        gameBoard[# fx, fy] = 4; // 10-point food
    }
}