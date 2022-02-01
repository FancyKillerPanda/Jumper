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

handle_event :: proc(player: ^Player, event: ^sdl.Event) {
	#partial switch event.type {
		case sdl.Event_Type.Key_Down:
			#partial switch event.key.keysym.scancode {
				case sdl.Scancode.Right:
					player.acceleration.x = PLAYER_ACCELERATION;

				case sdl.Scancode.Left:
					player.acceleration.x = -PLAYER_ACCELERATION;
			}

		case sdl.Event_Type.Key_Up:
			#partial switch event.key.keysym.scancode {
				case sdl.Scancode.Right: fallthrough;
				case sdl.Scancode.Left:
					player.acceleration.x = 0;
			}
	}
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

	if position.x < 0 {
		position.x = SCREEN_WIDTH;
	} else if position.x > SCREEN_WIDTH {
		position.x = 0;
	}

	if position.y > SCREEN_HEIGHT - (PLAYER_HEIGHT / 2) {
		position.y = SCREEN_HEIGHT - (PLAYER_HEIGHT / 2);
	}

	for platform in &platforms {
		if player_colliding_with_platform(player, &platform) {
			position.y = platform.position.y - (platform.dimensions.y / 2) - (PLAYER_HEIGHT / 2);
			velocity.y = 0;
		}
	}
}

draw_player :: proc(renderer: ^sdl.Renderer, player: ^Player) {
	rect: sdl.Rect = { cast(i32) player.position.x - (PLAYER_WIDTH / 2), cast(i32) player.position.y - (PLAYER_HEIGHT / 2), PLAYER_WIDTH, PLAYER_HEIGHT };
	
	sdl.set_render_draw_color(renderer, 255, 255, 0, 255);
	sdl.render_fill_rect(renderer, &rect);
}

player_colliding_with_platform :: proc(using player: ^Player, platform: ^Platform) -> bool {
	return position.x + (PLAYER_WIDTH / 2) >= platform.position.x - (platform.dimensions.x / 2) &&
		   position.x - (PLAYER_WIDTH / 2) <= platform.position.x + (platform.dimensions.x / 2) &&
		   position.y + (PLAYER_HEIGHT / 2) >= platform.position.y - (platform.dimensions.y / 2) &&
		   position.y - (PLAYER_HEIGHT / 2) <= platform.position.y + (platform.dimensions.y / 2);
}
