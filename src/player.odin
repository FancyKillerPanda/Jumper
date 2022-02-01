package main;

import sdl "shared:odin-sdl2"
import sdl_image "shared:odin-sdl2/image"

Vector2 :: distinct [2] f64;

PLAYER_WIDTH :: 45;
PLAYER_HEIGHT :: 60;

PLAYER_ACCELERATION :: 0.5;
PLAYER_FRICTION :: -0.05;

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

update_player :: proc(player: ^Player) {
	player.acceleration += player.velocity * PLAYER_FRICTION;
	player.velocity += player.acceleration;
	player.position += player.velocity + (player.acceleration * 0.5);
}

draw_player :: proc(renderer: ^sdl.Renderer, player: ^Player) {
	rect: sdl.Rect = { cast(i32) player.position.x - (PLAYER_WIDTH / 2), cast(i32) player.position.y - (PLAYER_HEIGHT / 2), PLAYER_WIDTH, PLAYER_HEIGHT };
	
	sdl.set_render_draw_color(renderer, 255, 255, 0, 255);
	sdl.render_fill_rect(renderer, &rect);
}
