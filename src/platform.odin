package main;

import "core:math/rand"

import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

platforms: [dynamic] Platform;

Platform :: struct {
	position: Vector2,
	dimensions: Vector2,
}

draw_platforms :: proc(renderer: ^sdl.Renderer) {
	for platform in &platforms {
		draw_platform(renderer, &platform);
	}
}

draw_platform :: proc(renderer: ^sdl.Renderer, platform: ^Platform) {
	rect: sdl.Rect = { cast(i32) (platform.position.x - (platform.dimensions.x / 2)),
					   cast(i32) (platform.position.y - (platform.dimensions.y / 2)),
					   cast(i32) platform.dimensions.x, cast(i32) platform.dimensions.y };
	
	sdl.SetRenderDrawColor(renderer, 0, 255, 0, 255);
	sdl.RenderFillRect(renderer, &rect);
}

random_platform :: proc() -> (platform: Platform) {
	platform.dimensions.x = rand.float64_range(SCREEN_WIDTH / 8, SCREEN_WIDTH / 4);
	platform.dimensions.y = rand.float64_range(SCREEN_HEIGHT / 32, SCREEN_HEIGHT / 24);
	platform.position.x = rand.float64_range(platform.dimensions.x / 2, SCREEN_WIDTH - (platform.dimensions.x / 2));
	platform.position.y = rand.float64_range((-SCREEN_HEIGHT / 4) - (platform.dimensions.y / 2), -platform.dimensions.y / 2);
	
	for otherPlatform in &platforms {
		if platforms_collide(&platform, &otherPlatform) {
			platform = random_platform();
		}
	}
	
	return;
}

random_platform_on_screen :: proc() -> (platform: Platform) {
	platform = random_platform();
	platform.position.y = rand.float64_range(platform.dimensions.y / 2, (SCREEN_HEIGHT * 3 / 4) - (platform.dimensions.y / 2));

	for otherPlatform in &platforms {
		if platforms_collide(&platform, &otherPlatform) {
			platform = random_platform_on_screen();
		}
	}

	return;
}

delete_off_screen_platforms_and_regenerate :: proc() {
	for i := 0; i < len(platforms); {
		if platforms[i].position.y - (platforms[i].dimensions.y / 2) >= SCREEN_HEIGHT {
			ordered_remove(&platforms, i);
			append(&platforms, random_platform());

			add_to_score(100);
		} else {
			i += 1;
		}
	}
}

platforms_collide :: proc(first: ^Platform, second: ^Platform) -> bool {
	return first.position.x + (first.dimensions.x / 2) >= second.position.x - (second.dimensions.x / 2) &&
		   first.position.x - (first.dimensions.x / 2) <= second.position.x + (second.dimensions.x / 2) &&
		   first.position.y + (first.dimensions.y / 2) >= second.position.y - (second.dimensions.y / 2) &&
		   first.position.y - (first.dimensions.y / 2) <= second.position.y + (second.dimensions.y / 2);
}
