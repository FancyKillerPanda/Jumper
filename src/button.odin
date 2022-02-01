package main;

import sdl "shared:odin-sdl2"
import sdl_image "shared:odin-sdl2/image"
import sdl_ttf "shared:odin-sdl2/ttf"

ButtonGroup :: struct {
	renderer: ^sdl.Renderer,
	font: ^sdl_ttf.Font,
	buttonTexts: [dynamic] Text,
}

create_button_group :: proc(renderer: ^sdl.Renderer, font: ^sdl_ttf.Font, texts: [] cstring) -> ButtonGroup {
	buttonGroup: ButtonGroup = { renderer = renderer, font = font };
	for text in texts {
		append(&buttonGroup.buttonTexts, create_text(renderer, font, text));
	}

	return buttonGroup;
}

draw_button_group :: proc(using buttonGroup: ^ButtonGroup, x: i32, y: i32, ySpacing: i32 = SCREEN_HEIGHT / 8) {
	currentY := y;
	
	for text in &buttonTexts {
		draw_text(renderer, &text, x, currentY);
		currentY += ySpacing;
	}
}
