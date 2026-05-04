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
	instance_destroy()
	}
}
//increase ball speed up to 12 per step after each bounce
if speed < 12 speed += 0.1;
direction +=2 - random(4);