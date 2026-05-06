draw_clear(c_black);

// Draw board
for (var xx = 0; xx < gridW; xx++) {
    for (var yy = 0; yy < gridH; yy++) {
        var cell = gameBoard[# xx, yy];

        var px = xx * cellSize;
        var py = yy * cellSize;
        switch(cell){
			case 0:	
				draw_set_color(make_color_rgb(30, 30, 30));
				break;
			case 1:
				draw_set_color(c_lime);
				break;
			case 2:
				draw_set_color(c_red);
				break;
			case 3:
				draw_set_color(c_yellow);
				break;
			case 4:
				draw_set_color(c_aqua);
				break;
		}
		/*
		if (cell == 0) {
            draw_set_color(make_color_rgb(30, 30, 30));
        } else if (cell == 1) {
            draw_set_color(c_lime);
        } else if (cell == 2) {
            draw_set_color(c_red);
        } else if (cell == 3) {
		    draw_set_color(c_yellow);
		} else if (cell == 4) {
		    draw_set_color(c_aqua);
		}
		*/
        draw_rectangle(px, py, px + cellSize - 2, py + cellSize - 2, false);
    }
}

if (gameOver) {
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_text(room_width / 2, room_height / 2, "GAME OVER\nPress Space to Restart");
}
if (!gameStart) {
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_text(room_width / 2, room_height / 2, "DOLLSNEK V0.1\nPress Space to Start");
}
//draw score
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_text(8, 8, "Score: " + string(snakeScore));