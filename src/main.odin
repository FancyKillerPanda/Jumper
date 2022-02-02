package main;

import "core:fmt"
import "core:time"

import sdl "shared:odin-sdl2"
import sdl_image "shared:odin-sdl2/image"
import sdl_ttf "shared:odin-sdl2/ttf"

printf :: fmt.printf;

SCREEN_WIDTH :: 720;
SCREEN_HEIGHT :: 960;

keysPressed: [sdl.Scancode.Num_Scancodes] bool;

GameState :: enum {
	StartScreen,
	PlayingNormal,
	PlayingContinuousScrolling,
}

currentState: GameState;
scrollSpeed: f64;

main :: proc() {
	if !init_dependencies() do return;
	defer quit_dependencies();

	window, renderer, success := create_window();
	if !success do return;

	titleFont := sdl_ttf.open_font("res/Cyber.ttf", 128);
	helpFont := sdl_ttf.open_font("res/LTWaveUI.ttf", 32);
	if titleFont == nil || helpFont == nil {
		printf("Error: Failed to open font. Message: '{}'\n", sdl.get_error());
		return;
	}

	jumperText := create_text(renderer, titleFont, "JUMPER");
	helpText := create_text(renderer, helpFont, "Left/right arrows to move, space to jump!");
	modeButtons := create_button_group(renderer, helpFont, { "Normal Mode", "Continuous Scrolling" });
	
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

			case sdl.Event_Type.Key_Up:
				keysPressed[event.key.keysym.scancode] = false;

				#partial switch event.key.keysym.scancode {
					case sdl.Scancode.Space:
						if currentState == .PlayingNormal || currentState == .PlayingContinuousScrolling {
							player_jump(&player);
						}
				}

			case sdl.Event_Type.Mouse_Motion:
				button_group_handle_mouse_motion(&modeButtons, &event);
				
			case sdl.Event_Type.Mouse_Button_Down:
				button_group_handle_mouse_down(&modeButtons, &event);
				
			case sdl.Event_Type.Mouse_Button_Up:
				result := button_group_handle_mouse_up(&modeButtons, &event);
				if result == 0 {
					currentState = .PlayingNormal;
				} else if result == 1 {
					currentState = .PlayingContinuousScrolling;
				}
			}
		}

		// Timing
		now := time.now();
		deltaTime := cast(f64) time.diff(lastTime, now) / cast(f64) time.Second;
		lastTime = now;

		if currentState == .PlayingNormal || currentState == .PlayingContinuousScrolling {
			update_player(&player, deltaTime);
		}

		sdl.set_render_draw_color(renderer, 200, 200, 200, 255);
		sdl.render_clear(renderer);

		draw_platforms(renderer);
		draw_player(renderer, &player);

		// Draws a dark overlay
		if currentState == .StartScreen {
			fillRect: sdl.Rect = { 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT }
			
			sdl.set_render_draw_color(renderer, 50, 50, 50, 200);
			sdl.render_fill_rect(renderer, &fillRect);
			
			draw_text(renderer, &jumperText, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 4);
			draw_text(renderer, &helpText, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 3);
			draw_button_group(&modeButtons, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2);
		}

		sdl.render_present(renderer);
	}
}

reset_game :: proc(player: ^Player) {
	clear(&platforms);
	append(&platforms, Platform {
		position = { SCREEN_WIDTH / 2, SCREEN_HEIGHT - (SCREEN_HEIGHT / 32) },
		dimensions = { SCREEN_WIDTH + (PLAYER_WIDTH * 2), SCREEN_HEIGHT / 16 },
	});

	for i in 0..<3 {
		append(&platforms, random_platform_on_screen());
	}

	player.position = { SCREEN_WIDTH / 2, platforms[0].position.y - (platforms[0].dimensions.y / 2) - (PLAYER_HEIGHT / 2)};

	currentState = .StartScreen;
	scrollSpeed = 0;
}

init_dependencies :: proc() -> bool {
	if sdl.init(sdl.Init_Flags.Everything) < 0 {
		printf("Error: Failed to initialise SDL2. Message: '{}'\n", sdl.get_error());
		return false;
	}

	if sdl_image.init(sdl_image.Init_Flags.PNG) != sdl_image.Init_Flags.PNG {
		printf("Error: Failed to initialise SDL_image. Message: '{}'\n", sdl.get_error());
		return false;
	}

	if sdl_ttf.init() < 0 {
		printf("Error: Failed to initialise SDL_ttf. Message: '{}'\n", sdl.get_error());
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
		printf("Error: Failed to create window. Message: '{}'\n", sdl.get_error());
		return nil, nil, false;
	}
	
	renderer = sdl.create_renderer(window, -1, sdl.Renderer_Flags.Present_VSync | sdl.Renderer_Flags.Accelerated);
	if renderer == nil {
		printf("Error: Failed to create renderer. Message: '{}'\n", sdl.get_error());
		return nil, nil, false;
	}

	sdl.set_render_draw_blend_mode(renderer, sdl.Blend_Mode.Blend);

	return window, renderer, true;
}
