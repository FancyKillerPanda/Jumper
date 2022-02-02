package main;

import "core:slice"

import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

SpriteSheet :: struct {
	renderer: ^sdl.Renderer,
	texture: ^sdl.Texture,
	textureRect: sdl.Rect,
	
	subrectDimensions: Vector2,
	numberOfSubrects: u32,

	timeSinceLastTextureChange: f64,

	animationOrder: [] u32,
	animationCurrentIndex: u32,
	animationDelayMs: u32,
}

init_sprite_sheet :: proc(spriteSheet: ^SpriteSheet, renderer: ^sdl.Renderer, filepath: cstring, subrectDimensions: Vector2, 
						  numberOfSubrects: u32, animationOrder: [] u32, animationDelayMs: u32) {
	spriteSheet.renderer = renderer;
	spriteSheet.texture = img.LoadTexture(renderer, filepath);
	if spriteSheet.texture == nil {
		printf("Error: Failed to load spritesheet texture (\"%s\").\n", filepath);
		return;
	}

	if sdl.QueryTexture(spriteSheet.texture, nil, nil, &spriteSheet.textureRect.w, &spriteSheet.textureRect.h) < 0 {
		printf("Error: Spritesheet texture (\"%s\") is invalid.\n", filepath);
		return;
	}

	spriteSheet.subrectDimensions = subrectDimensions;
	spriteSheet.numberOfSubrects = numberOfSubrects;

	spriteSheet.animationOrder = slice.clone(animationOrder);
	spriteSheet.animationDelayMs = animationDelayMs;
}

update_sprite_sheet :: proc(using spriteSheet: ^SpriteSheet, deltaTime: f64) {
	timeSinceLastTextureChange += deltaTime;

	if timeSinceLastTextureChange >= (cast(f64) animationDelayMs / 1000.0) {
		timeSinceLastTextureChange = 0;
		
		animationCurrentIndex += 1;
		animationCurrentIndex %= cast(u32) len(animationOrder);
	}
}

draw_sprite_sheet :: proc(using spriteSheet: ^SpriteSheet, position: Vector2) {
	rect: sdl.Rect;
	rect.x = cast(i32) (position.x - (subrectDimensions.x / 2));
	rect.y = cast(i32) (position.y - (subrectDimensions.y / 2));
	rect.w = cast(i32) subrectDimensions.x;
	rect.h = cast(i32) subrectDimensions.y;
	
	subrect := get_sprite_sheet_subrect(spriteSheet, spriteSheet.animationOrder[spriteSheet.animationCurrentIndex]);
	sdl.RenderCopy(renderer, texture, &subrect, &rect);
}

// TODO(fkp): Allow multiple lines of images
get_sprite_sheet_subrect :: proc(using spriteSheet: ^SpriteSheet, subrectIndex: u32) -> sdl.Rect {
	assert(subrectIndex < numberOfSubrects);

	return sdl.Rect {
		cast(i32) (subrectIndex * cast(u32) subrectDimensions.x),
		0,
		cast(i32) subrectDimensions.x,
		cast(i32) subrectDimensions.y,
	};
}
