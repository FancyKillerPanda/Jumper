package main;

import "core:math/rand"

import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

PLATFORM_MIN_MOVE_DISTANCE :: 50;
PLATFORM_MIN_VELOCITY :: 50.0;
PLATFORM_MAX_VELOCITY :: 120.0;

platforms: [dynamic] Platform;

Platform :: struct {
	texture: ^sdl.Texture,
	flip: sdl.RendererFlip,
	angle: f64,
	
	position: Vector2,
	dimensions: Vector2,

	moving: bool,
	movingFrom: Vector2,
	movingTo: Vector2,
	velocity: Vector2, // y component is always 0
}

create_platform :: proc(renderer: ^sdl.Renderer, position: Vector2, dimensions: Vector2, potentiallyMoving := true) -> (platform: Platform) {
	if potentiallyMoving && rand.uint32() % 4 == 0 {
		platform.moving = true;
		platform.velocity.x = rand.float64_range(PLATFORM_MIN_VELOCITY, PLATFORM_MAX_VELOCITY);
		platform.movingFrom = { rand.float64_range(dimensions.x / 2, SCREEN_WIDTH - (dimensions.x / 2)), position.y };
		platform.movingTo = { rand.float64_range(dimensions.x / 2, SCREEN_WIDTH - (dimensions.x / 2)), position.y };

		// We want movingFrom to be the left side
		if platform.movingFrom.x > platform.movingTo.x {
			temp := platform.movingFrom;
			platform.movingFrom = platform.movingTo;
			platform.movingTo = temp;
		}

		platform.position = platform.movingFrom;
		platform.texture = img.LoadTexture(renderer, "res/platforms/moving_platform.png");
	} else {
		platform.position = position;
		platform.texture = img.LoadTexture(renderer, "res/platforms/platform.png");
	}
	
	if platform.texture == nil {
		printf("Error: Failed to load platform texture.\n");
		return;
	}
	
	platform.flip = sdl.RendererFlip(rand.uint32() % 3);
	platform.angle = cast(f64) (rand.uint32() % 2) * 180.0;
	platform.dimensions = dimensions;

	return;
}

update_platforms :: proc(deltaTime: f64) {
	for platform in &platforms {
		if platform.moving {
			platform.position += platform.velocity * deltaTime;

			if platform.position.x < platform.movingFrom.x || platform.position.x > platform.movingTo.x {
				platform.velocity.x *= -1.0;
			}
		}
	}
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

	if !platform.moving { // Moving platforms will have a random position assigned
		platform.position.x = rand.float64_range(platform.dimensions.x / 2, SCREEN_WIDTH - (platform.dimensions.x / 2));
		platform.position.y = rand.float64_range((-SCREEN_HEIGHT / 4) - (platform.dimensions.y / 2), -platform.dimensions.y / 2);
	}

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
