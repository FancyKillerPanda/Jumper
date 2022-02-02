package main;

import "core:math/rand"

import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

platforms: [dynamic] Platform;

Platform :: struct {
	texture: ^sdl.Texture,
	flip: sdl.RendererFlip,
	angle: f64,
	
	position: Vector2,
	dimensions: Vector2,
}

create_platform :: proc(renderer: ^sdl.Renderer, position: Vector2, dimensions: Vector2) -> (platform: Platform) {
	platform.texture = img.LoadTexture(renderer, "res/platform.png");
	if platform.texture == nil {
		printf("Error: Failed to load platform texture.\n");
		return;
	}
	
	platform.flip = sdl.RendererFlip(rand.uint32() % 3);
	platform.angle = cast(f64) (rand.uint32() % 2) * 180.0;
	platform.position = position;
	platform.dimensions = dimensions;

	return;
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
	
	sdl.RenderCopyEx(renderer, platform.texture, nil, &rect, platform.angle, nil, platform.flip);
}

random_platform :: proc(renderer: ^sdl.Renderer) -> (platform: Platform) {
	platform = create_platform(
		renderer,
		{ 0, 0 }, // Will be filled later as it relies on the dimensions
		{ rand.float64_range(SCREEN_WIDTH / 8, SCREEN_WIDTH / 4), rand.float64_range(SCREEN_HEIGHT / 32, SCREEN_HEIGHT / 24) },
	);

	platform.position.x = rand.float64_range(platform.dimensions.x / 2, SCREEN_WIDTH - (platform.dimensions.x / 2));
	platform.position.y = rand.float64_range((-SCREEN_HEIGHT / 4) - (platform.dimensions.y / 2), -platform.dimensions.y / 2);
	
	for otherPlatform in &platforms {
		if platforms_collide(&platform, &otherPlatform) {
			sdl.DestroyTexture(platform.texture);
			platform = random_platform(renderer);
		}
	}
	
	return;
}

random_platform_on_screen :: proc(renderer: ^sdl.Renderer) -> (platform: Platform) {
	platform = random_platform(renderer);
	platform.position.y = rand.float64_range(platform.dimensions.y / 2, (SCREEN_HEIGHT * 3 / 4) - (platform.dimensions.y / 2));

	for otherPlatform in &platforms {
		if platforms_collide(&platform, &otherPlatform) {
			platform = random_platform_on_screen(renderer);
		}
	}

	return;
}

delete_off_screen_platforms_and_regenerate :: proc(renderer: ^sdl.Renderer) {
	for i := 0; i < len(platforms); {
		if platforms[i].position.y - (platforms[i].dimensions.y / 2) >= SCREEN_HEIGHT {
			ordered_remove(&platforms, i);
			append(&platforms, random_platform(renderer));

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
