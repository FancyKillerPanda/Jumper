package main;

import "core:fmt"
import "core:time"

import sdl "shared:odin-sdl2"
import sdl_image "shared:odin-sdl2/image"

printf :: fmt.printf;

SCREEN_WIDTH :: 720;
SCREEN_HEIGHT :: 960;

keysPressed: [sdl.Scancode.Num_Scancodes] bool;

main :: proc() {
	if !init_dependencies() do return;
	defer quit_dependencies();

	window, renderer, success := create_window();
	if !success do return;

	player: Player = { position = { SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2 } };
	append(&platforms, Platform { position = { SCREEN_WIDTH / 4, SCREEN_HEIGHT / 2 }, dimensions = { SCREEN_WIDTH / 6, SCREEN_HEIGHT / 16 } });
	
	last_time := time.now();
	running := true;
	
	for running {
		event: sdl.Event;
		for sdl.poll_event(&event) != 0 {
			#partial switch (event.type) {
			case sdl.Event_Type.Quit:
				running = false;

			case sdl.Event_Type.Key_Down:
				keysPressed[event.key.keysym.scancode] = true;

			case sdl.Event_Type.Key_Up:
				keysPressed[event.key.keysym.scancode] = false;
			}
		}

		// Timing
		now := time.now();
		delta_time := cast(f32) time.diff(last_time, now) / cast(f32) time.Second;
		last_time = now;

		update_player(&player);
		
		sdl.set_render_draw_color(renderer, 200, 200, 200, 255);
		sdl.render_clear(renderer);

		draw_player(renderer, &player);
		draw_platforms(renderer);

		sdl.render_present(renderer);
	}
}

init_dependencies :: proc() -> bool {
	if sdl.init(sdl.Init_Flags.Everything) < 0 {
		printf("Failed to initialise SDL2. Message: '{}'\n", sdl.get_error());
		return false;
	}

	if sdl_image.init(sdl_image.Init_Flags.PNG) != sdl_image.Init_Flags.PNG {
		printf("Failed to initialise SDL_image. Message: '{}'\n", sdl.get_error());
		return false;
	}

	return true;
}

quit_dependencies :: proc() {
	sdl_image.quit();
	sdl.quit();
}

create_window :: proc() -> (window: ^sdl.Window, renderer: ^sdl.Renderer, success: bool) {
	window = sdl.create_window("Jumper", 500, 50, SCREEN_WIDTH, SCREEN_HEIGHT, sdl.Window_Flags(0));
	if window == nil {
		printf("Failed to create window. Message: '{}'\n", sdl.get_error());
		return nil, nil, false;
	}
	
	renderer = sdl.create_renderer(window, -1, sdl.Renderer_Flags.Present_VSync | sdl.Renderer_Flags.Accelerated);
	if renderer == nil {
		printf("Failed to create renderer. Message: '{}'\n", sdl.get_error());
		return nil, nil, false;
	}

	return window, renderer, true;
}
