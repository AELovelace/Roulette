base_width = 640;
base_height = 360;

if (!variable_global_exists("base_width")) {
	global.base_width = base_width;
}
if (!variable_global_exists("base_height")) {
	global.base_height = base_height;
}

// Ensure runtime uses this object's configured base dimensions.
global.base_width = base_width;
global.base_height = base_height;

viewResize();
