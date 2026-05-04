//reverse direction if leaving left or right side of room
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

if bbox_left < boundsLeft || bbox_right > boundsRight {
	x = clamp(x, boundsLeft + sprite_get_xoffset(sprite_index), boundsRight - sprite_get_xoffset(sprite_index));
	hspeed *= -1;
}
//reverse direction if hitting top of room
if(bbox_top < boundsTop){
	vspeed *= -1	
}
else{
	if(bbox_bottom > boundsBottom){
	instance_destroy()
	}
}
//increase ball speed up to 12 per step after each bounce
if speed < 12 speed += 0.1;
direction +=2 - random(4);