package main;

import sdl "shared:odin-sdl2"
import sdl_image "shared:odin-sdl2/image"

Vector2 :: distinct [2] f64;

Player :: struct {
	position: Vector2,
	velocity: Vector2,
}

handle_event :: proc(player: ^Player, event: ^sdl.Event) {
	#partial switch event.type {
		case sdl.Event_Type.Key_Down:
			#partial switch event.key.keysym.scancode {
				case sdl.Scancode.Right:
					player.velocity.x = 5;

				case sdl.Scancode.Left:
					player.velocity.x = -5;
			}

		case sdl.Event_Type.Key_Up:
			#partial switch event.key.keysym.scancode {
				case sdl.Scancode.Right: fallthrough;
				case sdl.Scancode.Left:
					player.velocity.x = 0;
			}
	}
}

update_player :: proc(player: ^Player) {
	player.position += player.velocity;
}

draw_player :: proc(renderer: ^sdl.Renderer, player: ^Player) {
	rect: sdl.Rect = { cast(i32) player.position.x, cast(i32) player.position.y, 45, 60 };
	sdl.set_render_draw_color(renderer, 255, 255, 0, 255);
	sdl.render_fill_rect(renderer, &rect);
}
