package main;

import sdl "vendor:sdl2"
import img "vendor:sdl2/image"
import ttf "vendor:sdl2/ttf"

Text :: struct {
	message: cstring,

	font: ^ttf.Font,
	texture: ^sdl.Texture,
	rect: sdl.Rect,

	colour: sdl.Color,
}

create_text :: proc(renderer: ^sdl.Renderer, font_: ^ttf.Font, message_: cstring, colour_: sdl.Color = { 255, 255, 255, 255 }) -> Text {
	using text: Text;
	font = font_;
	message = message_;
	
	change_text_colour(renderer, &text, colour_);
	ttf.SizeText(font, message, &rect.w, &rect.h);

	return text;
}

free_text :: proc(text: ^Text) {
	sdl.DestroyTexture(text.texture);
	text.texture = nil;
}

draw_text :: proc(renderer: ^sdl.Renderer, text: ^Text, x: i32, y: i32) {
	text.rect.x = x - (text.rect.w / 2);
	text.rect.y = y - (text.rect.h / 2);

	sdl.RenderCopy(renderer, text.texture, nil, &text.rect);
}

change_text_colour :: proc(renderer: ^sdl.Renderer, using text: ^Text, colour_: sdl.Color) {
	colour = colour_;
	
	surface := ttf.RenderText_Solid(font, message, colour);
	texture = sdl.CreateTextureFromSurface(renderer, surface);
	sdl.FreeSurface(surface);
}
