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