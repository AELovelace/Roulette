//key left
if(keyboard_check(vk_left)){
	if(x > sprite_get_xoffset(sprite_index) + spd){
		x-= spd	//move bat
	}
	else {
		x = sprite_get_xoffset(sprite_index); //clamp left	
	}
}
if(keyboard_check(vk_right)){
	if(x < room_width - sprite_get_xoffset(sprite_index) - spd){
		x+= spd	//move bat
	}
	else {
		x = room_width - sprite_get_xoffset(sprite_index); //clamp left	
	}
}
if(instance_number(objBall) <= 0 && instance_number(objBallExtra) <=0) {
	instance_create_layer(xstart, ystart, layer, objBall);
	go = false;
}
with (objBall){
	if !go x = other.x;
}
