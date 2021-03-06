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

// If the animationDelayMs is 0, the animation will not progress automatically
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

	if animationDelayMs != 0.0 && timeSinceLastTextureChange >= (cast(f64) animationDelayMs / 1000.0) {
		timeSinceLastTextureChange = 0;
		sprite_sheet_next_frame(spriteSheet);
	}
}

draw_sprite_sheet :: proc(using spriteSheet: ^SpriteSheet, position: Vector2, horizontalFlip := false) {
	rect: sdl.Rect;
	rect.x = cast(i32) (position.x - (subrectDimensions.x / 2));
	rect.y = cast(i32) (position.y - (subrectDimensions.y / 2));
	rect.w = cast(i32) subrectDimensions.x;
	rect.h = cast(i32) subrectDimensions.y;
	
	subrect := get_sprite_sheet_subrect(spriteSheet, spriteSheet.animationOrder[spriteSheet.animationCurrentIndex]);
	
	flip := sdl.RendererFlip.NONE;
	if horizontalFlip do flip = sdl.RendererFlip.HORIZONTAL;
	
	sdl.RenderCopyEx(renderer, texture, &subrect, &rect, 0, nil, flip);
}

sprite_sheet_next_frame :: proc(using spriteSheet: ^SpriteSheet) {
	animationCurrentIndex += 1;
	animationCurrentIndex %= cast(u32) len(animationOrder);
}

sprite_sheet_set_frame :: proc(using spriteSheet: ^SpriteSheet, frameIndex: u32) {
	assert(frameIndex < cast(u32) len(animationOrder));
	animationCurrentIndex = frameIndex;
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
