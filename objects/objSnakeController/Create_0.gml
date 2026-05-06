//ds_grid helper variables. 
gridW = 20;
gridH = 15;
cellSize = 32;

//Board
// 0 = emty
// 1 = snek
// 2 = 1pt
// 3 = 5pt
// 4 = 10pt

gameBoard = ds_grid_create(gridW, gridH);
ds_grid_clear(gameBoard, 0);

//snake is stored as an array in code. 
snakeX = [];
snakeY = [];

//push startersnake into array. 
array_push(snakeX, 10);
array_push(snakeX, 9);
array_push(snakeX, 8);
array_push(snakeY, 7);
array_push(snakeY, 7);
array_push(snakeY, 7);

//Direction
dirX = 1;
dirY = 0;

//nextDir
nextDirX = dirX;
nextDirY = dirY;

//timing
moveDelay = 8;
moveTimer = 0;

//gameState
gameStart = false;
gameOver = false;
snakeScore = 0;
//put the snek on da bord
for(var i = 0; i < array_length(snakeX); i++){
	gameBoard[# snakeX[i], snakeY[i]] = 1;	
}

spawn_food();