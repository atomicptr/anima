package anima_karl2d

import ".."
import k2 "../../../karl2d"
import "../anima_fsm"

draw :: proc(
	self: ^anima.Animation,
	texture: k2.Texture,
	x: f32,
	y: f32,
	rotation: f32 = 0.0,
	color: k2.Color = k2.WHITE,
) {
	frame := anima.current_frame(self)

	flip_x: f32 = self.flip_v ? -1.0 : 1.0
	flip_y: f32 = self.flip_h ? -1.0 : 1.0

	k2.draw_texture_ex(
		texture,
		{f32(frame.x), f32(frame.y), flip_x * f32(frame.width), flip_y * f32(frame.height)},
		{x, y, f32(frame.width), f32(frame.height)},
		{0, 0},
		rotation,
		color,
	)
}

fsm_draw :: proc(
	self: ^anima_fsm.FSM($Ident),
	texture: k2.Texture,
	x: f32,
	y: f32,
	rotation: f32 = 0.0,
	color: k2.Color = k2.WHITE,
) {
	animation := anima_fsm.current_animation(self)
	draw(animation, texture, x, y, rotation, color)
}

