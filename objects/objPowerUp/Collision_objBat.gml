switch(image_index){
	case 0:
		with(objBat){
			image_xscale = 1.5;
			alarm[0] = room_speed * 10;
		}
		break;
	case 1:
		if(instance_number(objBall) <= 0){
			instance_create_layer(objBallExtra.x, objBallExtra.y, layer, objBallExtra)
		}
		else{
			with(objBall){
				instance_create_layer(objBall.x, objBall.y,layer,objBallExtra)
			}
		}
		break;
}
instance_destroy();