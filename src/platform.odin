package main;

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
