package main;

import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"

import sdl "vendor:sdl2"
import img "vendor:sdl2/image"
import ttf "vendor:sdl2/ttf"

printf :: fmt.printf;

SCREEN_WIDTH :: 720;
SCREEN_HEIGHT :: 960;

HIGH_SCORE_FILEPATH :: "res/high_score.txt";

keysPressed: [sdl.Scancode.NUM_SCANCODES] bool;

GameState :: enum {
	StartScreen,
	PlayingNormal,
	PlayingContinuousScrolling,
	Paused,
	GameOverScreen,
}

currentState: GameState;
gameMode: GameState = .PlayingNormal;
scrollSpeed: f64;

currentScore: u64;
highScoreNormalMode: u64;
highScoreContinuousScrolling: u64;

main :: proc() {
	rand.set_global_seed(time.read_cycle_counter());
	
	if !init_dependencies() do return;
	defer quit_dependencies();

	window, renderer, success := create_window();
	if !success do return;

	titleFont := ttf.OpenFont("res/fonts/Cyber.ttf", 100);
	helpFont := ttf.OpenFont("res/fonts/LTWaveUI.ttf", 32);
	if titleFont == nil || helpFont == nil {
		printf("Error: Failed to open font. Message: '{}'\n", sdl.GetError());
		return;
	}

	jumperText := create_text(renderer, titleFont, "JUMPER");
	helpText := create_text(renderer, helpFont, "Left/right arrows to move, space to jump!");
	modeButtons := create_button_group(renderer, helpFont, { "Normal Mode", "Continuous Scrolling" });
	set_button_group_colours(&modeButtons, { 255, 255, 255, 255 }, { 180, 0, 255, 255 }, { 90, 0, 127, 255 });
	
	pausedText := create_text(renderer, titleFont, "PAUSED");
	pausedHelpText := create_text(renderer, helpFont, "Press enter/escape to resume...");
	
	gameOverText := create_text(renderer, titleFont, "GAME OVER");
	gameOverScoreText := new(Text); // Will be initialised later
	playAgainText := create_text(renderer, helpFont, "Play again: Enter    |    Main menu: Escape");
	
	// Loads the highscore if possible
	highScoreData, openSuccess := os.read_entire_file(HIGH_SCORE_FILEPATH);
	if openSuccess {
		lastSpaceIndex := strings.last_index_byte(cast(string) highScoreData, ' ');

		if lastSpaceIndex != -1 {
			value, convertSuccess := strconv.parse_u64(cast(string) highScoreData[: lastSpaceIndex], 10);
			if convertSuccess {
				highScoreNormalMode = value;
			}

			value, convertSuccess = strconv.parse_u64(cast(string) highScoreData[lastSpaceIndex + 1 :], 10);
			if convertSuccess {
				highScoreContinuousScrolling = value;
			}
		}
	}

	init_clouds(renderer);
	
	player := create_player(renderer);
	reset_game(renderer, &player);
	
	lastTime := time.now();
	running := true;
	
	for running {
		event: sdl.Event;
		for sdl.PollEvent(&event) != 0 {
			#partial switch (event.type) {
			case sdl.EventType.QUIT:
				running = false;

			case sdl.EventType.KEYDOWN:
				keysPressed[event.key.keysym.scancode] = true;

			case sdl.EventType.KEYUP:
				keysPressed[event.key.keysym.scancode] = false;

				#partial switch event.key.keysym.scancode {
					case sdl.Scancode.SPACE:
						if currentState == .PlayingNormal || currentState == .PlayingContinuousScrolling {
							player_jump(&player);
						}

					case sdl.Scancode.ESCAPE:
						if currentState == .Paused {
							currentState = gameMode;
						} else if currentState == gameMode {
							currentState = .Paused;
						} else if currentState == .GameOverScreen {
							reset_game(renderer, &player);
							currentState = .StartScreen;
						}
						
					case sdl.Scancode.RETURN:
						if currentState == .Paused {
							currentState = gameMode;
						} else if currentState == .GameOverScreen {
							reset_game(renderer, &player);
							currentState = gameMode;
						}
				}

			case sdl.EventType.MOUSEMOTION:
				button_group_handle_mouse_motion(&modeButtons, &event);
				
			case sdl.EventType.MOUSEBUTTONDOWN:
				button_group_handle_mouse_down(&modeButtons, &event);
				
			case sdl.EventType.MOUSEBUTTONUP:
				result := button_group_handle_mouse_up(&modeButtons, &event);
				if result == 0 {
					currentState = .PlayingNormal;
				} else if result == 1 {
					currentState = .PlayingContinuousScrolling;
				}

				gameMode = currentState;
			}
		}

		// Timing
		now := time.now();
		deltaTime := cast(f64) time.diff(lastTime, now) / cast(f64) time.Second;
		
		if deltaTime >= 0.016 {
			lastTime = now;
			
			if currentState != .Paused {
				update_clouds(deltaTime);
			}

			if currentState == .PlayingNormal || currentState == .PlayingContinuousScrolling {
				update_platforms(deltaTime);
				
				if !update_player(&player, deltaTime) {
					currentState = .GameOverScreen;
					free_text(gameOverScoreText);
					gameOverScoreText^ = create_text(renderer, helpFont, strings.clone_to_cstring(fmt.tprintf("Score: {} (Highscore: {})", currentScore, get_current_mode_high_score())));
				}
			}
		}

		sdl.SetRenderDrawColor(renderer, 0, 255, 255, 255);
		sdl.RenderClear(renderer);

		highScore := get_current_mode_high_score();
		currentScoreText := create_text(renderer, helpFont, strings.clone_to_cstring(fmt.tprintf("Score: {} (Highscore: {})", currentScore, highScore), context.temp_allocator), { 180, 0, 255, 255 });
		defer free_text(&currentScoreText);
		
		draw_clouds();
		draw_platforms(renderer);
		draw_text(renderer, &currentScoreText, SCREEN_WIDTH / 2, currentScoreText.rect.h);
		draw_player(&player);

		// Draws a dark overlay
		if currentState == .StartScreen || currentState == .Paused || currentState == .GameOverScreen {
			fillRect: sdl.Rect = { 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT }
			
			sdl.SetRenderDrawColor(renderer, 50, 50, 50, 200);
			sdl.RenderFillRect(renderer, &fillRect);
		}

		// Text for the various splash screens
		if currentState == .StartScreen {
			draw_text(renderer, &jumperText, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 4);
			draw_text(renderer, &helpText, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 3);
			draw_button_group(&modeButtons, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2);
		} else if currentState == .Paused {
			draw_text(renderer, &pausedText, SCREEN_WIDTH / 2, SCREEN_HEIGHT * 4 / 9);
			draw_text(renderer, &pausedHelpText, SCREEN_WIDTH / 2, SCREEN_HEIGHT * 5 / 9);
		} else if currentState == .GameOverScreen {
			draw_text(renderer, &gameOverText, SCREEN_WIDTH / 2, SCREEN_HEIGHT * 3 / 9);
			draw_text(renderer, gameOverScoreText, SCREEN_WIDTH / 2, SCREEN_HEIGHT * 4 / 9);
			draw_text(renderer, &playAgainText, SCREEN_WIDTH / 2, SCREEN_HEIGHT * 6 / 9);
		}

		sdl.RenderPresent(renderer);
	}

	if !os.write_entire_file(HIGH_SCORE_FILEPATH, transmute([] u8) fmt.tprintf("{} {}", highScoreNormalMode, highScoreContinuousScrolling)) {
		printf("Error: Failed to write high score to file.\n");
	}
}

reset_game :: proc(renderer: ^sdl.Renderer, player: ^Player) {
	clear(&platforms);
	append(&platforms, create_platform(
		renderer,
		{ SCREEN_WIDTH / 2, SCREEN_HEIGHT - (SCREEN_HEIGHT / 32) },
		{ SCREEN_WIDTH + (player.dimensions.x * 2), SCREEN_HEIGHT / 16 },
		false,
	));

	for i in 0..3 {
		append(&platforms, random_platform_on_screen(renderer));
	}

	player.position = { SCREEN_WIDTH / 2, platforms[0].position.y - (platforms[0].dimensions.y / 2) - (player.dimensions.y / 2)};

	currentState = .StartScreen;
	scrollSpeed = 0;
	currentScore = 0;
}

add_to_score :: proc(amount: u64) {
	currentScore += amount;
	
	if gameMode == .PlayingNormal {
		if currentScore > highScoreNormalMode {
			highScoreNormalMode = currentScore;
		}
	} else if gameMode == .PlayingContinuousScrolling {
		if currentScore > highScoreContinuousScrolling {
			highScoreContinuousScrolling = currentScore;
		}
	} else {
		assert(false);
	}
}

get_current_mode_high_score :: proc() -> (highScore: u64) {
	if gameMode == .PlayingNormal {
		highScore = highScoreNormalMode;
	} else if gameMode == .PlayingContinuousScrolling {
		highScore = highScoreContinuousScrolling;
	}

	return;
}

init_dependencies :: proc() -> bool {
	if sdl.Init(sdl.INIT_EVERYTHING) < 0 {
		printf("Error: Failed to initialise SDL2. Message: '{}'\n", sdl.GetError());
		return false;
	}

	if img.Init(img.INIT_PNG) != img.INIT_PNG {
		printf("Error: Failed to initialise SDL_image. Message: '{}'\n", sdl.GetError());
		return false;
	}

	if ttf.Init() < 0 {
		printf("Error: Failed to initialise SDL_ttf. Message: '{}'\n", sdl.GetError());
		return false;
	}

	return true;
}

quit_dependencies :: proc() {
	img.Quit();
	sdl.Quit();
}

create_window :: proc() -> (window: ^sdl.Window, renderer: ^sdl.Renderer, success: bool) {
	window = sdl.CreateWindow("Jumper", 500, 50, SCREEN_WIDTH, SCREEN_HEIGHT, nil);
	if window == nil {
		printf("Error: Failed to create window. Message: '{}'\n", sdl.GetError());
		return nil, nil, false;
	}
	
	renderer = sdl.CreateRenderer(window, -1, sdl.RENDERER_PRESENTVSYNC | sdl.RENDERER_ACCELERATED);
	if renderer == nil {
		printf("Error: Failed to create renderer. Message: '{}'\n", sdl.GetError());
		return nil, nil, false;
	}

	sdl.SetRenderDrawBlendMode(renderer, sdl.BlendMode.BLEND);

	return window, renderer, true;
}
