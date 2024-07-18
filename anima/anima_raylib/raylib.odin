package anima_raylib

import ".."
import "../anima_fsm"
import rl "vendor:raylib"

draw :: proc(
	self: ^anima.Animation,
	texture: rl.Texture,
	x: f32,
	y: f32,
	rotation: f32 = 0.0,
	color: rl.Color = rl.WHITE,
	flip_x, flip_y: bool,
) {
	frame := anima.current_frame(self)

	flip_x: f32 = (self.flip_v || flip_x) ? -1.0 : 1.0
	flip_y: f32 = (self.flip_h || flip_y) ? -1.0 : 1.0

	rl.DrawTexturePro(
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
	texture: rl.Texture,
	x: f32,
	y: f32,
	rotation: f32 = 0.0,
	color: rl.Color = rl.WHITE,
	flip_x: bool = false,
	flip_y: bool = false,
) {
	animation := anima_fsm.current_animation(self)
	draw(animation, texture, x, y, rotation, color, flip_x, flip_y)
}
