package anima

import "core:strconv"
import "core:strings"

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
parse_interval :: proc(interval: IntervalT) -> Interval {
	switch res in interval {
	case Interval:
		return res
	case uint:
		return {res, res, true}
	case string:
		return parse_interval_string(res)
	}

	// TODO: this should not happen
	return parse_interval(0)
}

@(private)
parse_interval_string :: proc(interval_str: string) -> Interval {
	parts := strings.split(interval_str, "-")
	defer delete(parts)
	assert(len(parts) == 2, "Could not parse interval string from, expected format 'X-Y'")

	a := uint(strconv.atoi(parts[0]))
	b := uint(strconv.atoi(parts[1]))

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

grid_frames :: proc(grid: ^Grid, intervals: ..IntervalT) -> []FrameRect {
	assert(
		len(intervals) % 2 == 0,
		"Intervals are interpreted as (column, row) pairs but you did not provide an even amount of parameters",
	)

	frames := make([dynamic]FrameRect)

	for i := 0; i < len(intervals); i += 2 {
		column := parse_interval(intervals[i])
		row := parse_interval(intervals[i + 1])

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
) -> ^Animation {
	anim := new(Animation)
	anim.frames = frames
	anim.duration = duration
	anim.playing = playing
	anim.oneshot = oneshot
	anim.flip_h = flip_h
	anim.flip_v = flip_v
	anim.index = 0
	anim.time = 0.0
	anim.on_finished = nil

	return anim
}

destroy_animation :: proc(self: ^Animation) {
	delete(self.frames)
	free(self)
}

update :: proc(self: ^Animation, dt: f32) {
	if !self.playing {
		return
	}

	self.time += dt

	if self.time >= self.duration {
		self.index = (self.index + 1) % u32(len(self.frames))
		self.time = 0.0

		on_finished, ok := self.on_finished.(OnFinishedFunc)
		if ok {
			on_finished(self)
		}

		if self.oneshot {
			self.playing = false
		}
	}
}

current_frame :: proc(self: ^Animation) -> ^FrameRect {
	return &self.frames[self.index]
}
