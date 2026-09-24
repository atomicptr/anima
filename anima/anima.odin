#+vet explicit-allocators
package anima

import "core:strconv"
import "core:strings"
import "core:testing"

Grid :: struct {
	frame_width:  uint,
	frame_height: uint,
	image_width:  uint,
	image_height: uint,
	left:         uint,
	top:          uint,
	width:        uint,
	height:       uint,
	border:       uint,
}

new_grid :: proc(
	frame_width, frame_height, image_width, image_height: uint,
	left: uint = 0,
	top: uint = 0,
	border: uint = 0,
) -> Grid {
	return {
		frame_width,
		frame_height,
		image_width,
		image_height,
		left,
		top,
		image_width / frame_width,
		image_height / frame_height,
		border,
	}
}

Interval :: struct {
	from:    uint,
	to:      uint,
	forward: bool,
}

IntervalT :: union {
	Interval,
	uint,
	string,
}

@(private)
parse_interval :: proc(interval: IntervalT, allocator := context.temp_allocator) -> Interval {
	switch res in interval {
	case Interval:
		return res
	case uint:
		return {res, res, true}
	case string:
		return parse_interval_string(res, allocator)
	}

	// TODO: this should not happen
	return parse_interval(0, allocator)
}

@(private)
parse_interval_string :: proc(
	interval_str: string,
	temp_allocator := context.temp_allocator,
) -> Interval {
	parts := strings.split(interval_str, "-", temp_allocator)
	defer delete(parts, temp_allocator)
	assert(len(parts) == 2, "Could not parse interval string from, expected format 'X-Y'")

	a, a_ok := strconv.parse_uint(parts[0])
	assert(a_ok)

	b, b_ok := strconv.parse_uint(parts[1])
	assert(b_ok)

	if a > b {
		return {a, b, false}
	}

	return {a, b, true}
}

FrameRect :: struct {
	x:      uint,
	y:      uint,
	width:  uint,
	height: uint,
}

grid_frames :: proc(
	grid: ^Grid,
	intervals: ..IntervalT,
	allocator := context.allocator,
	temp_allocator := context.temp_allocator,
) -> []FrameRect {
	assert(
		len(intervals) % 2 == 0,
		"Intervals are interpreted as (column, row) pairs but you did not provide an even amount of parameters",
	)

	frames := make([dynamic]FrameRect, allocator)

	for i := 0; i < len(intervals); i += 2 {
		column := parse_interval(intervals[i], temp_allocator)
		row := parse_interval(intervals[i + 1], temp_allocator)

		cond := proc(index: int, interval: Interval) -> bool {
			if interval.forward {
				return index <= int(interval.to)
			}
			return index >= int(interval.to)
		}

		for y := int(row.from); cond(y, row); y += (row.forward ? 1 : -1) {
			for x := int(column.from); cond(x, column); x += (column.forward ? 1 : -1) {
				append(
					&frames,
					FrameRect {
						grid.left + uint(x) * grid.frame_width + (uint(x) + 1) * grid.border,
						grid.top + uint(y) * grid.frame_height + (uint(y) + 1) * grid.border,
						grid.frame_width,
						grid.frame_height,
					},
				)
			}
		}
	}

	return frames[:]
}

OnFinishedFunc :: proc(_: ^Animation)

Animation :: struct {
	frames:      []FrameRect,
	duration:    f32,
	index:       u32,
	playing:     bool,
	oneshot:     bool,
	time:        f32,
	flip_h:      bool,
	flip_v:      bool,
	on_finished: Maybe(OnFinishedFunc),
}

new_animation :: proc(
	frames: []FrameRect,
	duration: f32,
	playing: bool = true,
	oneshot: bool = false,
	flip_h: bool = false,
	flip_v: bool = false,
	on_finished: Maybe(OnFinishedFunc) = nil,
	allocator := context.allocator,
) -> ^Animation {
	anim := new(Animation, allocator)
	anim.frames = frames
	anim.duration = duration
	anim.playing = playing
	anim.oneshot = oneshot
	anim.flip_h = flip_h
	anim.flip_v = flip_v
	anim.on_finished = on_finished
	anim.index = 0
	anim.time = 0.0

	return anim
}

destroy_animation :: proc(self: ^Animation, allocator := context.allocator) {
	delete(self.frames, allocator)
	free(self, allocator)
}

update :: proc(self: ^Animation, dt: f32) {
	if !self.playing {
		return
	}

	self.time += dt

	if self.time >= self.duration {
		self.index = (self.index + 1) % u32(len(self.frames))
		self.time = 0.0

		if self.index == 0 {
			on_finished, ok := self.on_finished.(OnFinishedFunc)
			if ok {
				on_finished(self)
			}
			if self.oneshot {
				self.playing = false
			}
		}
	}
}

current_frame :: proc(self: ^Animation) -> ^FrameRect {
	return &self.frames[self.index]
}

@(test)
test_grid_frames :: proc(t: ^testing.T) {
	grid := new_grid(16, 16, 64, 16)
	frames := grid_frames(
		&grid,
		"0-3",
		0,
		allocator = context.temp_allocator,
		temp_allocator = context.temp_allocator,
	)
	defer delete(frames, context.temp_allocator)

	testing.expect_value(t, len(frames), 4)
	testing.expect_value(t, frames[0], FrameRect{0, 0, 16, 16})
	testing.expect_value(t, frames[1], FrameRect{16, 0, 16, 16})
	testing.expect_value(t, frames[2], FrameRect{32, 0, 16, 16})
	testing.expect_value(t, frames[3], FrameRect{48, 0, 16, 16})
}

@(test)
test_update_advances_index :: proc(t: ^testing.T) {
	grid := new_grid(16, 16, 64, 16)
	frames := grid_frames(
		&grid,
		"0-3",
		0,
		allocator = context.temp_allocator,
		temp_allocator = context.temp_allocator,
	)

	anim := new_animation(frames, 0.1, allocator = context.temp_allocator)
	defer destroy_animation(anim, context.temp_allocator)

	update(anim, 0.1)
	testing.expect_value(t, anim.index, u32(1))

	update(anim, 0.1)
	testing.expect_value(t, anim.index, u32(2))
}

// @(private)
// test_on_finished_count: int
//
// @(private)
// test_on_finished :: proc(_: ^Animation) {
// 	test_on_finished_count += 1
// }
//
// @(test)
// test_on_finished_fires_when_index_loops_to_zero :: proc(t: ^testing.T) {
// 	test_on_finished_count = 0
//
// 	grid := new_grid(16, 16, 64, 16)
// 	frames := grid_frames(
// 		&grid,
// 		"0-3",
// 		0,
// 		allocator = context.temp_allocator,
// 		temp_allocator = context.temp_allocator,
// 	)
//
// 	anim := new_animation(
// 		frames,
// 		0.1,
// 		on_finished = test_on_finished,
// 		allocator = context.temp_allocator,
// 	)
// 	defer destroy_animation(anim, context.temp_allocator)
//
// 	testing.expect(t, anim.on_finished != nil)
//
// 	update(anim, 0.1)
// 	update(anim, 0.1)
// 	update(anim, 0.1)
//
// 	testing.expect_value(t, anim.index, u32(3))
// 	testing.expect_value(t, test_on_finished_count, 0)
//
// 	update(anim, 0.1)
//
// 	testing.expect_value(t, anim.index, u32(0))
// 	testing.expect_value(t, test_on_finished_count, 1)
// 	testing.expect_value(t, anim.playing, true)
//
// 	for _ in 0 ..< 4 {
// 		update(anim, 0.1)
// 	}
//
// 	testing.expect_value(t, test_on_finished_count, 2)
// }
