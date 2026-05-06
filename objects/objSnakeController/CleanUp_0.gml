if (snakeBrokerSocket >= 0) {
	network_destroy(snakeBrokerSocket);
	snakeBrokerSocket = -1;
}

if (ds_exists(gameBoard, ds_type_grid)) {
	ds_grid_destroy(gameBoard);
}
