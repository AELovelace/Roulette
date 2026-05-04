
draw_set_colour(c_white);
// Draw the player score
draw_set_halign(fa_left);
draw_text(8, 8, "Score: " + string(instance_number(objBall)));
// Draw the high score
draw_set_halign(fa_right);
draw_text(room_width - 8, 8, "Hi Score: " + string(instance_number(objBallExtra)));
// Draw the player lives as sprites
var _x = (room_width / 2) - (32 * (global.BOPLives - 1));
repeat(global.BOPLives)	{
	draw_sprite_ext(sprBat, 0, _x, room_height - 16, 0.75, 0.75, 1, c_white, 0.5);
	_x += 64;
	}