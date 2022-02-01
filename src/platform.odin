package main;

import "core:math/rand"

import sdl "shared:odin-sdl2"
import sdl_image "shared:odin-sdl2/image"

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
	
	sdl.set_render_draw_color(renderer, 0, 255, 0, 255);
	sdl.render_fill_rect(renderer, &rect);
}

random_platform :: proc() -> (platform: Platform) {
	platform.dimensions.x = rand.float64_range(SCREEN_WIDTH / 8, SCREEN_WIDTH / 4);
	platform.dimensions.y = rand.float64_range(SCREEN_HEIGHT / 20, SCREEN_HEIGHT / 12);
	platform.position.x = rand.float64_range(platform.dimensions.x / 2, SCREEN_WIDTH - (platform.dimensions.x / 2));
	platform.position.y = rand.float64_range((-SCREEN_HEIGHT / 4) - (platform.dimensions.y / 2), -platform.dimensions.y / 2);
	
	return;
}

random_platform_on_screen :: proc() -> (platform: Platform) {
	platform = random_platform();
	platform.position.y = rand.float64_range(platform.dimensions.y / 2, (SCREEN_HEIGHT * 3 / 4) - (platform.dimensions.y / 2));
	return;
}
