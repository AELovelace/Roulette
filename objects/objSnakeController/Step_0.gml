if(!gameStart){
	if(keyboard_check_pressed(vk_space)) {
		gameStart = true;
	}
}
if(gameOver){
	if(keyboard_check_pressed(vk_space)) {
		room_restart()
	}
	exit;
}
if(gameStart){
	// Input
	if (keyboard_check_pressed(vk_right) && dirX != -1) {
	    nextDirX = 1;
	    nextDirY = 0;
	}

	if (keyboard_check_pressed(vk_left) && dirX != 1) {
	    nextDirX = -1;
	    nextDirY = 0;
	}

	if (keyboard_check_pressed(vk_down) && dirY != -1) {
	    nextDirX = 0;
	    nextDirY = 1;
	}

	if (keyboard_check_pressed(vk_up) && dirY != 1) {
	    nextDirX = 0;
	    nextDirY = -1;
	}

	//increment moveTimer
	moveTimer++;

	if(moveTimer >= moveDelay){
		//reset move timer
		moveTimer=0;
		//set moveDir
		dirX = nextDirX;
		dirY = nextDirY;
		//find head of snake
		var headX = snakeX[0];
		var headY = snakeY[0];
		//find next location of head of snake
		var newX = headX + dirX;
		var newY = headY + dirY;
		//wall detection
		if(newX < 0 || newX >= gridW || newY < 0 || newY >= gridH){
			gameOver = true;
			exit;
		}

	
		//collect cell Value
		var cell_value = gameBoard[# newX, newY]
		//helper function to check for food eaten
		var ate_food = (cell_value == 2 || cell_value == 3 || cell_value == 4);
		var foodPoints = 0;
		switch(cell_value){
			case 2:
				foodPoints = 1;
				break;
			case 3:
				foodPoints = 5;
				break;
			case 4:
				foodPoints = 10;
				break;
		}
	
		//position tail before moving
		var tail_x = snakeX[array_length(snakeX)-1];
		var tail_y = snakeY[array_length(snakeY)-1];
	
		if (gameBoard[# newX, newY] == 1 && !(newX == tail_x && newY == tail_y && !ate_food)){
			gameOver = true;
			exit;
		}
	
		array_insert(snakeX, 0, newX);
		array_insert(snakeY, 0, newY);
	
		gameBoard[# newX, newY] = 1;
	    if (ate_food) {
			snakeScore += foodPoints;
	        spawn_food();
	    } 
		else {
			gameBoard[# tail_x, tail_y] = 0;
			array_delete(snakeX, array_length(snakeX)-1, 1);
			array_delete(snakeY, array_length(snakeY)-1, 1);
		}
	}
}