if !go{
		go = true;
		if(instance_exists(objBall)){
			speed = objBall.spd;
			direction = objBall.dir;
		}
		else{
			speed = objBallExtra.spd
			direction = objBallExtra.dir;
		}
}

if (go) {
	var boundsLeft = 0;
	var boundsTop = 0;
	var boundsRight = room_width;
	var boundsBottom = room_height;
	if (variable_global_exists("breakoutBoundsActive") && global.breakoutBoundsActive) {
		boundsLeft = global.breakoutBoundsLeft;
		boundsTop = global.breakoutBoundsTop;
		boundsRight = global.breakoutBoundsRight;
		boundsBottom = global.breakoutBoundsBottom;
	}

	var bounced = false;
	if (bbox_left < boundsLeft || bbox_right > boundsRight) {
		x = clamp(x, boundsLeft + sprite_get_xoffset(sprite_index), boundsRight - sprite_get_xoffset(sprite_index));
		hspeed *= -1;
		bounced = true;
	}
	if (bbox_top < boundsTop) {
		vspeed *= -1;
		bounced = true;
	}
	if (bbox_bottom > boundsBottom) {
		instance_destroy();
		exit;
	}

	if (bounced) {
		if (speed < 12) speed += 0.1;
		direction += 2 - random(4);
	}
}