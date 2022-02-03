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
	renderer: ^sdl.Renderer,
	
	currentSpriteSheet: ^SpriteSheet,
	idleSpriteSheet: ^SpriteSheet,
	jumpPowerSpriteSheet: ^SpriteSheet,
	jumpSpriteSheet: ^SpriteSheet,
	
	position: Vector2,
	dimensions: Vector2,

	velocity: Vector2,
	acceleration: Vector2,

	jumpPower: f64,
}

create_player :: proc(renderer: ^sdl.Renderer) -> Player {
	player: Player;
	player.renderer = renderer;

	player.dimensions = Vector2 { 45, 75 };
	
	player.idleSpriteSheet = new(SpriteSheet);
	player.jumpPowerSpriteSheet = new(SpriteSheet);
	player.jumpSpriteSheet = new(SpriteSheet);
	init_sprite_sheet(player.idleSpriteSheet, renderer, "res/player/idle_spritesheet.png", Vector2 { 45, 75 },
					  4, { 0, 1, 0, 1, 0, 1, 0, 3, 0, 1, 0, 1, 0, 1, 0, 1, 2, 3, 0, 1, 0, 1, 0, 1, 0, 3 }, 150);
	init_sprite_sheet(player.jumpPowerSpriteSheet, renderer, "res/player/jump_power_spritesheet.png", Vector2 { 45, 75 },
					  10, { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }, 0);
	init_sprite_sheet(player.jumpSpriteSheet, renderer, "res/player/jump_spritesheet.png", Vector2 { 45, 80 }, 2, { 0, 1 }, 0);

	player.currentSpriteSheet = player.idleSpriteSheet;
	
	return player;
}

update_player :: proc(using player: ^Player, deltaTime: f64) -> bool {
	acceleration = { 0, PLAYER_GRAVITY };
	
	isLeftPressed := keysPressed[sdl.Scancode.LEFT];
	isRightPressed := keysPressed[sdl.Scancode.RIGHT];
	if isRightPressed || isLeftPressed {
		ACC :: PLAYER_ACCELERATION;
		acceleration.x = (ACC * cast(f64) cast(i64) isRightPressed) - (ACC * cast(f64) cast(i64) isLeftPressed);
	}
	
	velocity += acceleration * deltaTime;
	velocity.x *= PLAYER_FRICTION;

	// If we're moving downward, check for platform collisions
	if velocity.y >= 0 {
		oldPosition := position;

		// y-axis
		position.y += velocity.y * deltaTime;
		for platform in &platforms {
			if oldPosition.y - (dimensions.y / 2) < platform.position.y - (platform.dimensions.y / 2) &&
			   player_colliding_with_platform(player, &platform) {
				// Move the player to be above the platform, not inside it
				position.y = platform.position.y - (platform.dimensions.y / 2) - (dimensions.y / 2);
				velocity.y = 0;
			}
		}
		
		// x-axis
		position.x += velocity.x * deltaTime;
		for platform in &platforms {
			if oldPosition.y - (dimensions.y / 2) < platform.position.y - (platform.dimensions.y / 2) &&
			   player_colliding_with_platform(player, &platform) {
				// Move the player to be touching the vertical boundary of the platform, not inside it
				if velocity.x > 0 {
					position.x = platform.position.x - (platform.dimensions.x / 2) - (dimensions.x / 2);
				} else {
					position.x = platform.position.x + (platform.dimensions.x / 2) + (dimensions.x / 2);
				}

				velocity.x = 0;
			}
		}
	}
	else {
		position += velocity * deltaTime;
	}

	// Wraps the x-axis around
	if position.x + (dimensions.x / 2.0) < 0.0 {
		position.x = SCREEN_WIDTH + (dimensions.x / 2.0);
	} else if position.x > SCREEN_WIDTH + (dimensions.x / 2.0) {
		position.x = -dimensions.x / 2.0;
	}

	// Player can't go below the screen
	if position.y > SCREEN_HEIGHT - (dimensions.y / 2) {
		return false;
	}

	// Moves everything on screen downward if we go into the top quarter
	if currentState == .PlayingNormal {
		if position.y <= SCREEN_HEIGHT / 4 {
			position.y += abs(velocity.y) * deltaTime;

			for platform in &platforms {
				platform.position.y += abs(velocity.y) * deltaTime;
			}

			delete_off_screen_platforms_and_regenerate(player.renderer);
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

		delete_off_screen_platforms_and_regenerate(player.renderer);
	}

	// Increases the jump power if we're holding space and on a platform
	if is_player_standing_on_platform(player) {
		if keysPressed[sdl.Scancode.SPACE] {
			jumpPower += (PLAYER_MAX_JUMP_POWER - PLAYER_MIN_JUMP_POWER) / 60.0;
			if jumpPower > PLAYER_MAX_JUMP_POWER {
				jumpPower = PLAYER_MAX_JUMP_POWER;
			}

			// Changes the animation
			jumpPowerFraction := (jumpPower - PLAYER_MIN_JUMP_POWER) / (PLAYER_MAX_JUMP_POWER - PLAYER_MIN_JUMP_POWER);
			currentSpriteSheet = jumpPowerSpriteSheet;

			if 		jumpPowerFraction <= 0.1 	do sprite_sheet_set_frame(jumpPowerSpriteSheet, 0);
			else if	jumpPowerFraction <= 0.2 	do sprite_sheet_set_frame(jumpPowerSpriteSheet, 1);
			else if	jumpPowerFraction <= 0.3 	do sprite_sheet_set_frame(jumpPowerSpriteSheet, 2);
			else if	jumpPowerFraction <= 0.4 	do sprite_sheet_set_frame(jumpPowerSpriteSheet, 3);
			else if	jumpPowerFraction <= 0.5 	do sprite_sheet_set_frame(jumpPowerSpriteSheet, 4);
			else if	jumpPowerFraction <= 0.6 	do sprite_sheet_set_frame(jumpPowerSpriteSheet, 5);
			else if	jumpPowerFraction <= 0.7 	do sprite_sheet_set_frame(jumpPowerSpriteSheet, 6);
			else if	jumpPowerFraction <= 0.8 	do sprite_sheet_set_frame(jumpPowerSpriteSheet, 7);
			else if	jumpPowerFraction <= 0.9 	do sprite_sheet_set_frame(jumpPowerSpriteSheet, 8);
			else 								do sprite_sheet_set_frame(jumpPowerSpriteSheet, 9);
		} else {
			jumpPower = PLAYER_MIN_JUMP_POWER;
			currentSpriteSheet = idleSpriteSheet;
		}
	} else {
		jumpPower = PLAYER_MIN_JUMP_POWER;

		if velocity.y > 0 {
			currentSpriteSheet = jumpSpriteSheet;
			sprite_sheet_set_frame(jumpSpriteSheet, 1);
		}
	}

	// Changes the texture if necessary
	update_sprite_sheet(currentSpriteSheet, deltaTime);

	return true;
}

draw_player :: proc(using player: ^Player) {
	flip := player.velocity.x < 0;
	draw_sprite_sheet(currentSpriteSheet, position, flip);
}

player_jump :: proc(using player: ^Player) {
	if is_player_standing_on_platform(player) {
		velocity.y = -jumpPower;
		jumpPower = PLAYER_MIN_JUMP_POWER;

		// TODO(fkp): Jumping animation
		currentSpriteSheet = jumpSpriteSheet;
		sprite_sheet_set_frame(jumpSpriteSheet, 0);
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
	return position.x + (dimensions.x / 2) > platform.position.x - (platform.dimensions.x / 2) &&
		   position.x - (dimensions.x / 2) < platform.position.x + (platform.dimensions.x / 2) &&
		   position.y + (dimensions.y / 2) > platform.position.y - (platform.dimensions.y / 2) &&
		   position.y - (dimensions.y / 2) < platform.position.y + (platform.dimensions.y / 2);
}
