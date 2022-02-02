package main;

import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

Vector2 :: distinct [2] f64;

PLAYER_WIDTH :: 45;
PLAYER_HEIGHT :: 60;

PLAYER_ACCELERATION :: 18000.0;
PLAYER_FRICTION :: -6000.0;
PLAYER_GRAVITY :: 15000.0;

PLAYER_MIN_JUMP_POWER :: 1200.0;
PLAYER_MAX_JUMP_POWER :: 4200.0;

SCROLL_SPEED_INCREASE_RATE :: 25;

Player :: struct {
	position: Vector2,
	velocity: Vector2,
	acceleration: Vector2,

	jumpPower: f64,
}

update_player :: proc(using player: ^Player, deltaTime: f64) {
	acceleration = { 0, PLAYER_GRAVITY };
	
	isLeftPressed := keysPressed[sdl.Scancode.LEFT];
	isRightPressed := keysPressed[sdl.Scancode.RIGHT];
	if isRightPressed || isLeftPressed {
		ACC :: PLAYER_ACCELERATION;
		acceleration.x = (ACC * cast(f64) cast(i64) isRightPressed) - (ACC * cast(f64) cast(i64) isLeftPressed);
	}
	
	acceleration.x += velocity.x * PLAYER_FRICTION * deltaTime;
	velocity += acceleration * deltaTime;
	position += (velocity * deltaTime) + (acceleration * 0.5 * deltaTime * deltaTime);

	// Wraps the x-axis around
	if position.x + (PLAYER_WIDTH / 2.0) < 0.0 {
		position.x = SCREEN_WIDTH + (PLAYER_WIDTH / 2.0);
	} else if position.x > SCREEN_WIDTH + (PLAYER_WIDTH / 2.0) {
		position.x = -PLAYER_WIDTH / 2.0;
	}

	// Player can't go below the screen
	if position.y > SCREEN_HEIGHT - (PLAYER_HEIGHT / 2) {
		reset_game(player);
		return;
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
	if currentState == .PlayingNormal {
		if position.y <= SCREEN_HEIGHT / 4 {
			position.y += abs(velocity.y) * deltaTime;

			for platform in &platforms {
				platform.position.y += abs(velocity.y) * deltaTime;
			}

			delete_off_screen_platforms_and_regenerate();
		}
	} else if currentState == .PlayingContinuousScrolling {
		// We only start scrolling when we first reach the top quarter of the screen
		if scrollSpeed > 0 || position.y <= SCREEN_HEIGHT / 4 {
			scrollSpeed += SCROLL_SPEED_INCREASE_RATE * deltaTime;
		}

		position.y += scrollSpeed * deltaTime;
		for platform in &platforms {
			platform.position.y += scrollSpeed * deltaTime;
		}

		delete_off_screen_platforms_and_regenerate();
	}

	// Increases the jump power if we're holding space and on a platform
	if is_player_standing_on_platform(player) {
		if keysPressed[sdl.Scancode.SPACE] {
			jumpPower += (PLAYER_MAX_JUMP_POWER - PLAYER_MIN_JUMP_POWER) / 120.0;
			if jumpPower > PLAYER_MAX_JUMP_POWER {
				jumpPower = PLAYER_MAX_JUMP_POWER;
			}
		} else {
			jumpPower = PLAYER_MIN_JUMP_POWER;
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
	
	sdl.SetRenderDrawColor(renderer, 255, 255, 0, 255);
	sdl.RenderFillRect(renderer, &rect);
}

player_jump :: proc(using player: ^Player) {
	if is_player_standing_on_platform(player) {
		velocity.y = -jumpPower;
	}
}

is_player_standing_on_platform :: proc(using player: ^Player) -> bool {
	position.y += 1;
	defer position.y -= 1;

	for platform in &platforms {
		if player_colliding_with_platform(player, &platform) {
			return true;
		}
	}

	return false;
}

player_colliding_with_platform :: proc(using player: ^Player, platform: ^Platform) -> bool {
	return position.x + (PLAYER_WIDTH / 2) >= platform.position.x - (platform.dimensions.x / 2) &&
		   position.x - (PLAYER_WIDTH / 2) <= platform.position.x + (platform.dimensions.x / 2) &&
		   position.y + (PLAYER_HEIGHT / 2) >= platform.position.y - (platform.dimensions.y / 2) &&
		   position.y - (PLAYER_HEIGHT / 2) <= platform.position.y + (platform.dimensions.y / 2);
}
