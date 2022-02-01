package main;

import "core:fmt"
import "core:time"

import sdl "shared:odin-sdl2"
import sdl_image "shared:odin-sdl2/image"

printf :: fmt.printf;

SCREEN_WIDTH :: 720;
SCREEN_HEIGHT :: 960;

keysPressed: [sdl.Scancode.Num_Scancodes] bool;

GameState :: enum {
	StartScreen,
	Playing,
}

currentState: GameState;

main :: proc() {
	if !init_dependencies() do return;
	defer quit_dependencies();

	window, renderer, success := create_window();
	if !success do return;

	player: Player;
	reset_game(&player);
	
	lastTime := time.now();
	running := true;
	
	for running {
		event: sdl.Event;
		for sdl.poll_event(&event) != 0 {
			#partial switch (event.type) {
			case sdl.Event_Type.Quit:
				running = false;

			case sdl.Event_Type.Key_Down:
				keysPressed[event.key.keysym.scancode] = true;

				if currentState == .StartScreen {
					currentState = .Playing;
				}

			case sdl.Event_Type.Key_Up:
				keysPressed[event.key.keysym.scancode] = false;

				#partial switch event.key.keysym.scancode {
					case sdl.Scancode.Space:
						if currentState == .Playing {
							player_jump(&player);
						}
				}
			}
		}

		// Timing
		now := time.now();
		deltaTime := cast(f64) time.diff(lastTime, now) / cast(f64) time.Second;
		lastTime = now;

		if currentState == .Playing {
			update_player(&player, deltaTime);
		}

		sdl.set_render_draw_color(renderer, 200, 200, 200, 255);
		sdl.render_clear(renderer);

		draw_platforms(renderer);
		draw_player(renderer, &player);

		// Draws a dark overlay
		if currentState == .StartScreen {
			rect: sdl.Rect = { 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT }

			sdl.set_render_draw_color(renderer, 50, 50, 50, 200);
			sdl.render_fill_rect(renderer, &rect);
		}

		sdl.render_present(renderer);
	}
}

reset_game :: proc(player: ^Player) {
	clear(&platforms);
	
	append(&platforms, Platform { position = { SCREEN_WIDTH / 2, SCREEN_HEIGHT - (SCREEN_HEIGHT / 32) }, dimensions = { SCREEN_WIDTH, SCREEN_HEIGHT / 16 } });
	for i in 0..<3 {
		append(&platforms, random_platform_on_screen());
	}

	player.position = { SCREEN_WIDTH / 2, platforms[0].position.y - (platforms[0].dimensions.y / 2) - (PLAYER_HEIGHT / 2)};

	currentState = .StartScreen;
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

	sdl.set_render_draw_blend_mode(renderer, sdl.Blend_Mode.Blend);

	return window, renderer, true;
}
