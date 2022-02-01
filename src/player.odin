package main;

import sdl "shared:odin-sdl2"
import sdl_image "shared:odin-sdl2/image"

Vector2 :: distinct [2] f64;

PLAYER_WIDTH :: 45;
PLAYER_HEIGHT :: 60;

PLAYER_ACCELERATION :: 0.3;
PLAYER_FRICTION :: -0.1;
PLAYER_GRAVITY :: 0.3;

Player :: struct {
	position: Vector2,
	velocity: Vector2,
	acceleration: Vector2,
}

update_player :: proc(using player: ^Player) {
	acceleration = { 0, PLAYER_GRAVITY };
	
	if keysPressed[sdl.Scancode.Right] {
		acceleration.x = PLAYER_ACCELERATION;
	} else if keysPressed[sdl.Scancode.Left] {
		acceleration.x = -PLAYER_ACCELERATION;
	}
	
	acceleration.x += velocity.x * PLAYER_FRICTION;
	velocity += acceleration;
	position += velocity + (acceleration * 0.5);

	// Wraps the x-axis around
	if position.x < 0 {
		position.x = SCREEN_WIDTH;
	} else if position.x > SCREEN_WIDTH {
		position.x = 0;
	}

	// Player can't go below the screen
	if position.y > SCREEN_HEIGHT - (PLAYER_HEIGHT / 2) {
		position.y = SCREEN_HEIGHT - (PLAYER_HEIGHT / 2);
	}

	// If we're moving downward, check for platform collisions
	if velocity.y >= 0 {
		for platform in &platforms {
			if player_colliding_with_platform(player, &platform) {
				position.y = platform.position.y - (platform.dimensions.y / 2) - (PLAYER_HEIGHT / 2);
				velocity.y = 0;
			}
		}
	}
}

draw_player :: proc(renderer: ^sdl.Renderer, player: ^Player) {
	rect: sdl.Rect = { cast(i32) player.position.x - (PLAYER_WIDTH / 2), cast(i32) player.position.y - (PLAYER_HEIGHT / 2), PLAYER_WIDTH, PLAYER_HEIGHT };
	
	sdl.set_render_draw_color(renderer, 255, 255, 0, 255);
	sdl.render_fill_rect(renderer, &rect);
}

player_jump :: proc(using player: ^Player) {
	position.y += 1;
	isStandingOnPlatform := false;

	for platform in &platforms {
		if player_colliding_with_platform(player, &platform) {
			isStandingOnPlatform = true;
			break;
		}
	}

	position.y -= 1;

	if isStandingOnPlatform {
		velocity.y = -18;
	}
}

player_colliding_with_platform :: proc(using player: ^Player, platform: ^Platform) -> bool {
	return position.x + (PLAYER_WIDTH / 2) >= platform.position.x - (platform.dimensions.x / 2) &&
		   position.x - (PLAYER_WIDTH / 2) <= platform.position.x + (platform.dimensions.x / 2) &&
		   position.y + (PLAYER_HEIGHT / 2) >= platform.position.y - (platform.dimensions.y / 2) &&
		   position.y - (PLAYER_HEIGHT / 2) <= platform.position.y + (platform.dimensions.y / 2);
}
