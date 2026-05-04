//reverse direction if leaving left or right side of room
if bbox_left < 0 || bbox_right > room_width {
	x = clamp(x, sprite_get_xoffset(sprite_index), room_width + sprite_get_xoffset(sprite_index));
	hspeed *= -1;
}
//reverse direction if hitting top of room
if(bbox_top < 0){
	vspeed *= -1	
}
else{
	if(bbox_bottom > room_height){
		global.BOPLives -=1;
		if(global.BOPLives <= 0){
			if(global.BOPScore > global.highScore) {
				global.highScore = global.BOPScore;
			}
			with (objBOCtrl){
				state = "GAMEOVER"
			}
		}
	else if(instance_number(objBall) <= 0 && instance_number(objBallExtra) <=0) {
		instance_create_layer(xstart, ystart, layer, objBall);
	}
	instance_destroy()
	}
}
//increase ball speed up to 12 per step after each bounce
if speed < 12 speed += 0.1;
direction +=2 - random(4);