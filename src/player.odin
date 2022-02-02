package main;

import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

Vector2 :: distinct [2] f64;

PLAYER_ACCELERATION :: 18000.0;
PLAYER_FRICTION :: -6000.0;
PLAYER_GRAVITY :: 15000.0;

PLAYER_MIN_JUMP_POWER :: 1200.0;
PLAYER_MAX_JUMP_POWER :: 4200.0;

SCROLL_SPEED_INCREASE_RATE :: 25;

Player :: struct {
	texture: ^sdl.Texture,
	
	position: Vector2,
	dimensions: Vector2,

	velocity: Vector2,
	acceleration: Vector2,

	jumpPower: f64,
}

create_player :: proc(renderer: ^sdl.Renderer) -> (Player, bool) {
	player: Player;
	player.texture = img.LoadTexture(renderer, "res/player.png");
	if player.texture == nil {
		printf("Error: Failed to load player texture.\n");
		return player, false;
	}

	x, y: i32;
	if sdl.QueryTexture(player.texture, nil, nil, &x, &y) < 0 {
		printf("Error: Player texture is invalid.\n");
		return player, false;
	}

	player.dimensions.x = cast(f64) x;
	player.dimensions.y = cast(f64) y;
	
	return player, true;
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
	if position.x + (dimensions.x / 2.0) < 0.0 {
		position.x = SCREEN_WIDTH + (dimensions.x / 2.0);
	} else if position.x > SCREEN_WIDTH + (dimensions.x / 2.0) {
		position.x = -dimensions.x / 2.0;
	}

	// Player can't go below the screen
	if position.y > SCREEN_HEIGHT - (dimensions.y / 2) {
		reset_game(player);
		return;
	}

	// If we're moving downward, check for platform collisions
	if velocity.y >= 0 {
		for platform in &platforms {
			if player_colliding_with_platform(player, &platform) {
				position.y = platform.position.y - (platform.dimensions.y / 2) - (dimensions.y / 2);
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

draw_player :: proc(renderer: ^sdl.Renderer, using player: ^Player) {
	/*
	// The contration is the proportion of the jump power to the max jump power range,
	// divided by two. This allows the player to contract to half its normal height
	// when in the process of jumping.
	jumpContraction := ((jumpPower - PLAYER_MIN_JUMP_POWER) / (PLAYER_MAX_JUMP_POWER - PLAYER_MIN_JUMP_POWER)) / 2;
	
	rect: sdl.Rect = {
		cast(i32) (position.x - (dimensions.x / 2)),
		cast(i32) (position.y - (dimensions.y / 2) + (dimensions.y * jumpContraction)),
		cast(i32) dimensions.x,
		cast(i32) (dimensions.y - (dimensions.y * jumpContraction)),
	};
	*/
	
	rect: sdl.Rect = {
		cast(i32) (position.x - (dimensions.x / 2)),
		cast(i32) (position.y - (dimensions.y / 2)),
		cast(i32) dimensions.x,
		cast(i32) dimensions.y,
	};
	
	sdl.RenderCopy(renderer, texture, nil, &rect);
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
	return position.x + (dimensions.x / 2) >= platform.position.x - (platform.dimensions.x / 2) &&
		   position.x - (dimensions.x / 2) <= platform.position.x + (platform.dimensions.x / 2) &&
		   position.y + (dimensions.y / 2) >= platform.position.y - (platform.dimensions.y / 2) &&
		   position.y - (dimensions.y / 2) <= platform.position.y + (platform.dimensions.y / 2);
}
