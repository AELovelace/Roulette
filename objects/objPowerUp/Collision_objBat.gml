switch(image_index){
	case 0:
		with(objBat){
			image_xscale = 1.5;
			alarm[0] = room_speed * 10;
		}
		break;
	case 1:
		if(instance_number(objBall) <= 0){
			instance_create_layer(objBallExtra.x, objBallExtra.y, layer, objBall)
		}
		else{
			with(objBall){
				instance_create_layer(objBall.x, objBall.y,layer,objBallExtra)
			}
		}
		break;
	case 2:
		if(instance_exists(objBall)){
			with(objBall){
				image_xscale = 2;
				image_yscale = 2;
				alarm[0] = room_speed * 10;
			}
		}
		if(instance_exists(objBallExtra)){
			with(objBallExtra){
				image_xscale = 2;
				image_yscale = 2;
				alarm[0] = room_speed * 10;
			}
		}
		break;
	case 3:
		if(instance_exists(objBall)){
			with(objBall){
				var target = instance_nearest(x, y, objBrick)
				if(instance_exists(target)){
					move_towards_point(target.x, target.y, 5);
					
				}
			}
		}
		if(instance_exists(objBallExtra)){
			with(objBallExtra){
				var target = instance_nearest(x, y, objBrick)
				if(instance_exists(target)){
					move_towards_point(target.x, target.y, 5);
				}
			}
		}
		break;
	case 4:
		if(instance_exists(objBall)){
			with(objBall){
				speed = 3;
			}
		}
		if(instance_exists(objBallExtra)){
			with(objBallExtra){
				speed = 3;
			}
		}
		break;
			
}
instance_destroy();