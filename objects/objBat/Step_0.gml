//key left
var boundsLeft = 0;
var boundsRight = room_width;
if (variable_global_exists("breakoutBoundsActive") && global.breakoutBoundsActive) {
	boundsLeft = global.breakoutBoundsLeft;
	boundsRight = global.breakoutBoundsRight;
}

if(keyboard_check(vk_left)){
	if(x > boundsLeft + sprite_get_xoffset(sprite_index) + spd){
		x-= spd	//move bat
	}
	else {
		x = boundsLeft + sprite_get_xoffset(sprite_index); //clamp left	
	}
}
if(keyboard_check(vk_right)){
	if(x < boundsRight - sprite_get_xoffset(sprite_index) - spd){
		x+= spd	//move bat
	}
	else {
		x = boundsRight - sprite_get_xoffset(sprite_index); //clamp left	
	}
}
if(instance_number(objBall) <= 0 && instance_number(objBallExtra) <=0) {
	instance_create_layer(xstart, ystart, layer, objBall);
	go = false;
}
with (objBall){
	if !go x = other.x;
}
