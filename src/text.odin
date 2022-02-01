package main;

import sdl "shared:odin-sdl2"
import sdl_image "shared:odin-sdl2/image"
import sdl_ttf "shared:odin-sdl2/ttf"

Text :: struct {
	message: cstring,

	font: ^sdl_ttf.Font,
	texture: ^sdl.Texture,
	rect: sdl.Rect,

	colour: sdl.Color,
}

create_text :: proc(renderer: ^sdl.Renderer, font_: ^sdl_ttf.Font, message_: cstring, colour_: sdl.Color = { 255, 255, 255, 255 }) -> Text {
	using text: Text;
	font = font_;
	message = message_;
	
	change_text_colour(renderer, &text, colour_);
	sdl_ttf.size_text(font, message, &rect.w, &rect.h);

	return text;
}

draw_text :: proc(renderer: ^sdl.Renderer, text: ^Text, x: i32, y: i32) {
	text.rect.x = x - (text.rect.w / 2);
	text.rect.y = y - (text.rect.h / 2);

	sdl.render_copy(renderer, text.texture, nil, &text.rect);
}

change_text_colour :: proc(renderer: ^sdl.Renderer, using text: ^Text, colour_: sdl.Color) {
	colour = colour_;
	
	surface := sdl_ttf.render_text_solid(font, message, colour);
	texture = sdl.create_texture_from_surface(renderer, surface);
	sdl.free_surface(surface);
}
