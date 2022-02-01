package main;

import sdl "shared:odin-sdl2"
import sdl_image "shared:odin-sdl2/image"
import sdl_ttf "shared:odin-sdl2/ttf"

Text :: struct {
	font: ^sdl_ttf.Font,
	texture: ^sdl.Texture,
	rect: sdl.Rect,
}

create_text :: proc(renderer: ^sdl.Renderer, font_: ^sdl_ttf.Font, message: cstring, colour: sdl.Color = { 255, 255, 255, 255 }) -> Text {
	using text: Text;
	font = font_;
	
	surface := sdl_ttf.render_text_solid(font, message, { 255, 255, 255, 255 });
	texture = sdl.create_texture_from_surface(renderer, surface);
	sdl.free_surface(surface);
	sdl_ttf.size_text(font, message, &rect.w, &rect.h);

	return text;
}

draw_text :: proc(renderer: ^sdl.Renderer, text: ^Text, x: i32, y: i32) {
	text.rect.x = x - (text.rect.w / 2);
	text.rect.y = y - (text.rect.h / 2);

	sdl.render_copy(renderer, text.texture, nil, &text.rect);
}
