package main;

import sdl "shared:odin-sdl2"
import sdl_image "shared:odin-sdl2/image"

Vector2 :: distinct [2] f64;

PLAYER_WIDTH :: 45;
PLAYER_HEIGHT :: 60;

// PLAYER_ACCELERATION :: 0.3;
// PLAYER_FRICTION :: -0.1;
// PLAYER_GRAVITY :: 0.3;
PLAYER_ACCELERATION :: 18000.0;
PLAYER_FRICTION :: -6000.0;
PLAYER_GRAVITY :: 15000.0;

// PLAYER_MIN_JUMP_POWER :: 8.0;
// PLAYER_MAX_JUMP_POWER :: 20.0;
PLAYER_MIN_JUMP_POWER :: 1500.0;
PLAYER_MAX_JUMP_POWER :: 4200.0;

Player :: struct {
	position: Vector2,
	velocity: Vector2,
	acceleration: Vector2,

	jumpPower: f64,
}

update_player :: proc(using player: ^Player, deltaTime: f64) {
	acceleration = { 0, PLAYER_GRAVITY };
	
	if keysPressed[sdl.Scancode.Right] {
		acceleration.x = PLAYER_ACCELERATION;
	} else if keysPressed[sdl.Scancode.Left] {
		acceleration.x = -PLAYER_ACCELERATION;
	}
	
	acceleration.x += velocity.x * PLAYER_FRICTION * deltaTime;
	velocity += acceleration * deltaTime;
	position += (velocity * deltaTime) + (acceleration * 0.5 * deltaTime * deltaTime);

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

	// Moves everything on screen downward if we go into the top quarter
	if position.y <= SCREEN_HEIGHT / 4 {
		position.y += abs(velocity.y) * deltaTime;

		for i := 0; i < len(platforms); {
			platform := &platforms[i];
			platform.position.y += abs(velocity.y) * deltaTime;

			if platform.position.y - (platform.dimensions.y / 2) >= SCREEN_HEIGHT {
				ordered_remove(&platforms, i);
				append(&platforms, random_platform());
			} else {
				i += 1;
			}
		}
	}

	// Increases the jump power if we're holding space
	if keysPressed[sdl.Scancode.Space] {
		jumpPower += (PLAYER_MAX_JUMP_POWER - PLAYER_MIN_JUMP_POWER) / 120.0;
		if jumpPower > PLAYER_MAX_JUMP_POWER {
			jumpPower = PLAYER_MAX_JUMP_POWER;
		}
	} else {
		jumpPower = PLAYER_MIN_JUMP_POWER;
	}
}

draw_player :: proc(renderer: ^sdl.Renderer, player: ^Player) {
	// The contration is the proportion of the jump power to the max jump power range,
	// divided by two. This allows the player to contract to half its normal height
	// when in the process of jumping.
	jumpContraction := ((player.jumpPower - PLAYER_MIN_JUMP_POWER) / (PLAYER_MAX_JUMP_POWER - PLAYER_MIN_JUMP_POWER)) / 2;
	
	rect: sdl.Rect = {
		cast(i32) player.position.x - (PLAYER_WIDTH / 2),
		cast(i32) (player.position.y - (PLAYER_HEIGHT / 2) + (PLAYER_HEIGHT * jumpContraction)),
		PLAYER_WIDTH,
		cast(i32) (PLAYER_HEIGHT - (PLAYER_HEIGHT * jumpContraction)),
	};
	
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
		velocity.y = -jumpPower;
	}
}

player_colliding_with_platform :: proc(using player: ^Player, platform: ^Platform) -> bool {
	return position.x + (PLAYER_WIDTH / 2) >= platform.position.x - (platform.dimensions.x / 2) &&
		   position.x - (PLAYER_WIDTH / 2) <= platform.position.x + (platform.dimensions.x / 2) &&
		   position.y + (PLAYER_HEIGHT / 2) >= platform.position.y - (platform.dimensions.y / 2) &&
		   position.y - (PLAYER_HEIGHT / 2) <= platform.position.y + (platform.dimensions.y / 2);
}
