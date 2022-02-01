package main;

import sdl "shared:odin-sdl2"
import sdl_image "shared:odin-sdl2/image"
import sdl_ttf "shared:odin-sdl2/ttf"

ButtonGroup :: struct {
	renderer: ^sdl.Renderer,
	font: ^sdl_ttf.Font,
	buttonTexts: [dynamic] Text,

	baseColour: sdl.Color,
	hoverColour: sdl.Color,
	pressedColour: sdl.Color,

	active: i32,
}

create_button_group :: proc(renderer: ^sdl.Renderer, font: ^sdl_ttf.Font, texts: [] cstring) -> ButtonGroup {
	buttonGroup: ButtonGroup = { renderer = renderer, font = font };
	set_button_group_colours(&buttonGroup);
	
	for text in texts {
		append(&buttonGroup.buttonTexts, create_text(renderer, font, text, buttonGroup.baseColour));
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

set_button_group_colours :: proc(buttonGroup: ^ButtonGroup, baseColour: sdl.Color = { 255, 255, 255, 255 },
								 hoverColour: sdl.Color = { 255, 0, 0, 255 }, pressedColour: sdl.Color = { 127, 0, 0, 255 }) {
	buttonGroup.baseColour = baseColour;
	buttonGroup.hoverColour = hoverColour;
	buttonGroup.pressedColour = pressedColour;
}

button_group_handle_mouse_motion :: proc(using buttonGroup: ^ButtonGroup, event: ^sdl.Event) {
	mouseRect: sdl.Rect = { event.motion.x, event.motion.y, 1, 1 };

	for text, i in &buttonGroup.buttonTexts {
		if sdl.has_intersection(&mouseRect, &text.rect) == .True {
			if text.colour == buttonGroup.baseColour {
				change_text_colour(buttonGroup.renderer, &text, buttonGroup.hoverColour);
			}
		} else {
			if active == i32(i) {
				active = -1;
			}

			if text.colour != buttonGroup.baseColour {
				change_text_colour(buttonGroup.renderer, &text, buttonGroup.baseColour);
			}
		}
	}
}

button_group_handle_mouse_down :: proc(using buttonGroup: ^ButtonGroup, event: ^sdl.Event) {
	mouseRect: sdl.Rect = { event.button.x, event.button.y, 1, 1 };

	for text, i in &buttonGroup.buttonTexts {
		if sdl.has_intersection(&mouseRect, &text.rect) == .True {
			active = i32(i);
			
			if text.colour != buttonGroup.pressedColour {
				change_text_colour(buttonGroup.renderer, &text, buttonGroup.pressedColour);
			}
		}
	}
}

button_group_handle_mouse_up :: proc(using buttonGroup: ^ButtonGroup, event: ^sdl.Event) -> i32 {
	if active == -1 {
		return -1;
	}

	mouseRect: sdl.Rect = { event.button.x, event.button.y, 1, 1 };
	if sdl.has_intersection(&mouseRect, &buttonGroup.buttonTexts[active].rect) == .True {
		return active;
	}
	
	return -1;
}
