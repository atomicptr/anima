package anima_sdl3

import ".."
import "../anima_fsm"
import "vendor:sdl3"

draw :: proc(
	self: ^anima.Animation,
	renderer: ^sdl3.Renderer,
	texture: ^sdl3.Texture,
	x: f32,
	y: f32,
	rotation: f32 = 0.0,
	color: sdl3.Color = {255, 255, 255, 255},
	zoom: f32 = 1.0,
) {
	frame := anima.current_frame(self)

	src_rect := sdl3.FRect{f32(frame.x), f32(frame.y), f32(frame.width), f32(frame.height)}
	dest_rect := sdl3.FRect{x, y, f32(frame.width) * zoom, f32(frame.height) * zoom}
	center := sdl3.FPoint{0, 0}

	flip := sdl3.FlipMode.NONE

	if self.flip_v do flip += .HORIZONTAL
	if self.flip_h do flip += .VERTICAL

	// apply texture tint
	sdl3.SetTextureColorMod(texture, color.r, color.g, color.b)
	sdl3.SetTextureAlphaMod(texture, color.a)

	sdl3.RenderTextureRotated(
		renderer,
		texture,
		&src_rect,
		&dest_rect,
		f64(rotation),
		&center,
		flip,
	)

	// restore texture tint
	sdl3.SetTextureColorMod(texture, 255, 255, 255)
	sdl3.SetTextureAlphaMod(texture, 255)
}

fsm_draw :: proc(
	self: ^anima_fsm.FSM($Ident),
	renderer: ^sdl3.Renderer,
	texture: ^sdl3.Texture,
	x: f32,
	y: f32,
	rotation: f32 = 0.0,
	color: sdl3.Color = {255, 255, 255, 255},
	zoom: f32 = 1.0,
) {
	animation := anima_fsm.current_animation(self)
	draw(animation, renderer, texture, x, y, rotation, color, zoom)
}
