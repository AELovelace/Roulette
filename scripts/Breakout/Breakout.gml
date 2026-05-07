function bounce_sound(){
	var bounceSnd = choose(0, 1, 2, 3, 4, 5, 6, 7);
	
	switch(bounceSnd){
		case 0:
			audio_play_sound(DT_02_Perc_Shot, 10, false, 0.5)
			break;
		case 1:
			audio_play_sound(DT_03_Perc_Shot, 10, false, 0.5)
			break;
		case 2:
			audio_play_sound(DT_04_Perc_Shot, 10, false, 0.5)
			break;
		case 3:
			audio_play_sound(DT_05_Perc_Shot, 10, false, 0.5)
			break;
		case 4:
			audio_play_sound(DT_06_Perc_Shot, 10, false, 0.5)
			break;	
		case 5:
			audio_play_sound(DT_07_Perc_Shot, 10, false, 0.5)
			break;	
		case 6:
			audio_play_sound(DT_08_Perc_Shot, 10, false, 0.5)
			break;
		case 7:
			audio_play_sound(DT_09_Perc_Shot, 10, false, 0.5)
			break;
	}
		
}
function bo_particle_init(){
	//to be called in Create Event of BO Controller. 
	global.bops = part_system_create();
	part_system_automatic_update(global.bops, true);
	part_system_automatic_draw(global.bops, true);
	part_system_depth(global.bops, -100)
	//create tail
	global.bops_trail = part_type_create();
	//shape
	part_type_shape(global.bops_trail, pt_shape_circle);
	//size
	part_type_size(global.bops_trail, 0.1, 0.3, 0, 0);
	//Color
	part_type_colour1(global.bops_trail, c_yellow);
	//Alpha Fade
	part_type_alpha3(global.bops_trail, 0.8, 0.4, 0);
	//Lifetime
	part_type_life(global.bops_trail, 15, 25);
	//speed
	part_type_speed(global.bops_trail, 0, 0, 0, 0);
	//Direction
	part_type_direction(global.bops_trail, 0, 360, 0, 0);
	//Gravity
	part_type_gravity(global.bops_trail, 0, 0);
	//BlendMode
	part_type_blend(global.bops_trail, true);
}

function bo_particle_emit(_ball){
	if (!variable_global_exists("bops") || !part_system_exists(global.bops)) return;
	if (!variable_global_exists("bops_trail") || !part_type_exists(global.bops_trail)) return;

	var _spd = point_distance(0, 0, _ball.hspeed, _ball.vspeed);
	var _count = clamp(round(_spd * 0.4), 1, 4);
	part_particles_create(global.bops, _ball.x, _ball.y, global.bops_trail, _count);
	
	_ball.trail_timer++;

	if (_ball.trail_timer >= _ball.trail_spacing)
	{
	    _ball.trail_timer = 0;

	    array_insert(_ball.trail_x, 0, x);
	    array_insert(_ball.trail_y, 0, y);
	    array_insert(_ball.trail_alpha, 0, 1);

	    if (array_length(_ball.trail_x) > _ball.trail_length)
	    {
	        array_pop(_ball.trail_x);
	        array_pop(_ball.trail_y);
	        array_pop(_ball.trail_alpha);
	    }
	}	
}

function bo_particle_tail(_ball){
	for (var i = array_length(_ball.trail_x) - 1; i >= 0; i--){
		var a = 1 - (i / _ball.trail_length);
		draw_set_alpha(a * 0.45);
		draw_sprite_ext(_ball.sprite_index, _ball.image_index, _ball.trail_x[i], _ball.trail_y[i], _ball.image_xscale, _ball.image_yscale, _ball.image_angle, _ball.image_blend, a);
	}

	draw_set_alpha(1);
	draw_self();
}