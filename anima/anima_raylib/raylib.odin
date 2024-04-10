package anima_raylib

import ".."
import rl "vendor:raylib"

draw :: proc(
	self: ^anima.Animation,
	texture: rl.Texture,
	x: f32,
	y: f32,
	rotation: f32 = 0.0,
	color: rl.Color = rl.WHITE,
) {
	frame := anima.current_frame(self)

	flip_x: f32 = self.flip_v ? -1.0 : 1.0
	flip_y: f32 = self.flip_h ? -1.0 : 1.0

	rl.DrawTexturePro(
		texture,
		{f32(frame.x), f32(frame.y), flip_x * f32(frame.width), flip_y * f32(frame.height)},
		{x, y, f32(frame.width), f32(frame.height)},
		{0, 0},
		rotation,
		color,
	)
}
