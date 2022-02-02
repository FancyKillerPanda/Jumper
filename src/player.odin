package main;

import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

Vector2 :: distinct [2] f64;

PLAYER_ACCELERATION :: 1800.0;
PLAYER_FRICTION :: 0.92;
PLAYER_GRAVITY :: 4000.0;

PLAYER_MIN_JUMP_POWER :: 1000.0;
PLAYER_MAX_JUMP_POWER :: 2200.0;

SCROLL_SPEED_INCREASE_RATE :: 25;

Player :: struct {
	currentSpriteSheet: ^SpriteSheet,
	idleSpriteSheet: ^SpriteSheet,
	
	position: Vector2,
	dimensions: Vector2,

	velocity: Vector2,
	acceleration: Vector2,

	jumpPower: f64,
}

create_player :: proc(renderer: ^sdl.Renderer) -> Player {
	player: Player;

	player.dimensions = Vector2 { 60, 80 };
	
	player.idleSpriteSheet = new(SpriteSheet);
	init_sprite_sheet(player.idleSpriteSheet, renderer, "res/player/spritesheet.png", player.dimensions,
					  4, { 0, 1, 0, 1, 0, 1, 0, 3, 0, 1, 0, 1, 0, 1, 0, 1, 2, 3, 0, 1, 0, 1, 0, 1, 0, 3 }, 150);

	player.currentSpriteSheet = player.idleSpriteSheet;
	
	return player;
}

update_player :: proc(using player: ^Player, deltaTime: f64) {
	acceleration = { 0, PLAYER_GRAVITY };
	
	isLeftPressed := keysPressed[sdl.Scancode.LEFT];
	isRightPressed := keysPressed[sdl.Scancode.RIGHT];
	if isRightPressed || isLeftPressed {
		ACC :: PLAYER_ACCELERATION;
		acceleration.x = (ACC * cast(f64) cast(i64) isRightPressed) - (ACC * cast(f64) cast(i64) isLeftPressed);
	}
	
	velocity += acceleration * deltaTime;
	velocity.x *= PLAYER_FRICTION;
	position += velocity * deltaTime;

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
			jumpPower += (PLAYER_MAX_JUMP_POWER - PLAYER_MIN_JUMP_POWER) / 60.0;
			if jumpPower > PLAYER_MAX_JUMP_POWER {
				jumpPower = PLAYER_MAX_JUMP_POWER;
			}
		} else {
			jumpPower = PLAYER_MIN_JUMP_POWER;
		}
	} else {
		jumpPower = PLAYER_MIN_JUMP_POWER;
	}

	// Changes the texture if necessary
	update_sprite_sheet(currentSpriteSheet, deltaTime);
}

draw_player :: proc(renderer: ^sdl.Renderer, using player: ^Player) {
	flip := player.velocity.x < 0;
	draw_sprite_sheet(currentSpriteSheet, position, flip);
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
