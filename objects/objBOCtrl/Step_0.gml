if instance_number(objBrick) <= 0{
	room_restart();
}
else{
	if state == "GAMEOVER"
		{
		if keyboard_check(vk_anykey){
			global.BOPScore = 0;
			global.BOPLives = 3;
			room_restart();
			}
		}
}