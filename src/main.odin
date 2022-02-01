package main;

import "core:fmt"
import "core:time"

import sdl "shared:odin-sdl2"
import sdl_image "shared:odin-sdl2/image"
import sdl_ttf "shared:odin-sdl2/ttf"

printf :: fmt.printf;

SCREEN_WIDTH :: 720;
SCREEN_HEIGHT :: 960;

JUMPER_TEXT :: "JUMPER";
HELP_TEXT_LINE_0 :: "Left/right arrows to move, space to jump!";
HELP_TEXT_LINE_1 :: "Press any key to begin...";

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

	titleFont := sdl_ttf.open_font("res/Cyber.ttf", 128);
	helpFont := sdl_ttf.open_font("res/LTWaveUI.ttf", 32);
	if titleFont == nil || helpFont == nil {
		printf("Error: Failed to open font. Message: '{}'\n", sdl.get_error());
		return;
	}

	jumperSurface := sdl_ttf.render_text_solid(titleFont, JUMPER_TEXT, { 255, 255, 255, 255 });
	jumperTexture := sdl.create_texture_from_surface(renderer, jumperSurface);
	helpTextLine0Surface := sdl_ttf.render_text_solid(helpFont, HELP_TEXT_LINE_0, { 255, 255, 255, 255 });
	helpTextLine0Texture := sdl.create_texture_from_surface(renderer, helpTextLine0Surface);
	helpTextLine1Surface := sdl_ttf.render_text_solid(helpFont, HELP_TEXT_LINE_1, { 255, 255, 255, 255 });
	helpTextLine1Texture := sdl.create_texture_from_surface(renderer, helpTextLine1Surface);
	
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
			fillRect: sdl.Rect = { 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT }
			
			sdl.set_render_draw_color(renderer, 50, 50, 50, 200);
			sdl.render_fill_rect(renderer, &fillRect);
			
			jumperTextRect: sdl.Rect;
			sdl_ttf.size_text(titleFont, JUMPER_TEXT, &jumperTextRect.w, &jumperTextRect.h);
			jumperTextRect.x = (SCREEN_WIDTH / 2) - (jumperTextRect.w / 2);
			jumperTextRect.y = (SCREEN_HEIGHT / 3) - (jumperTextRect.h / 2);

			sdl.render_copy(renderer, jumperTexture, nil, &jumperTextRect);

			helpTextLine0Rect: sdl.Rect;
			sdl_ttf.size_text(helpFont, HELP_TEXT_LINE_0, &helpTextLine0Rect.w, &helpTextLine0Rect.h);
			helpTextLine0Rect.x = (SCREEN_WIDTH / 2) - (helpTextLine0Rect.w / 2);
			helpTextLine0Rect.y = (SCREEN_HEIGHT / 2) - (helpTextLine0Rect.h / 2);

			sdl.render_copy(renderer, helpTextLine0Texture, nil, &helpTextLine0Rect);

			helpTextLine1Rect: sdl.Rect;
			sdl_ttf.size_text(helpFont, HELP_TEXT_LINE_1, &helpTextLine1Rect.w, &helpTextLine1Rect.h);
			helpTextLine1Rect.x = (SCREEN_WIDTH / 2) - (helpTextLine1Rect.w / 2);
			helpTextLine1Rect.y = (SCREEN_HEIGHT * 5 / 8) - (helpTextLine1Rect.h / 2);

			sdl.render_copy(renderer, helpTextLine1Texture, nil, &helpTextLine1Rect);
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
