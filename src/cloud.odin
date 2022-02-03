package main;

import "core:math/rand"

import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

CLOUD_MIN_VELOCITY :: 75.0;
CLOUD_MAX_VELOCITY :: 125.0;

clouds: [2] Cloud;

Cloud :: struct {
	renderer: ^sdl.Renderer,
	texture: ^sdl.Texture,
	flip: sdl.RendererFlip,
	rect: sdl.Rect,

	velocity: Vector2, // y component is always 0
}

init_clouds :: proc(renderer: ^sdl.Renderer) {
	for cloud in &clouds {
		init_random_cloud(renderer, &cloud);
	}
}

init_random_cloud :: proc(renderer: ^sdl.Renderer, cloud: ^Cloud) {
	cloud.renderer = renderer;
	cloud.texture = img.LoadTexture(renderer, "res/cloud.png");
	if cloud.texture == nil {
		printf("Error: Failed to load cloud texture.\n");
		return;
	}

	if sdl.QueryTexture(cloud.texture, nil, nil, &cloud.rect.w, &cloud.rect.h) < 0 {
		printf("Error: Cloud texture is invalid.\n");
		return;
	}
	
	cloud.flip = sdl.RendererFlip(rand.uint32() % 2); // Only horizontal flipping
	
	// NOTE(fkp): These are top-left coordinates
	cloud.rect.x = cast(i32) rand.float64_range(0.0, cast(f64) (SCREEN_WIDTH - cloud.rect.w));
	cloud.rect.y = cast(i32) rand.float64_range(0.0, cast(f64) ((SCREEN_HEIGHT / 2) - cloud.rect.h));

	cloud.velocity.x = rand.float64_range(CLOUD_MIN_VELOCITY, CLOUD_MAX_VELOCITY) * cast(f64) (((rand.int31() % 2) * 2) - 1);
}

update_clouds :: proc(deltaTime: f64) {
	for cloud in &clouds {
		cloud.rect.x += cast(i32) (cloud.velocity.x * deltaTime);

		if cloud.rect.x + cloud.rect.w < 0 {
			cloud.rect.x = SCREEN_WIDTH;
		} else if cloud.rect.x > SCREEN_WIDTH {
			cloud.rect.x = -cloud.rect.w;
		}
	}
}

draw_clouds :: proc() {
	for cloud in &clouds {
		sdl.RenderCopyEx(cloud.renderer, cloud.texture, nil, &cloud.rect, 0.0, nil, cloud.flip);
	}
}
