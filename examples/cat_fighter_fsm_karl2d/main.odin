package cat_fighter_fsm_karl2d

import k2 "../../../karl2d"
import "../../anima"
import "../../anima/anima_fsm"
import "../../anima/anima_karl2d"
import "core:fmt"
import "core:mem"

CatAnim :: enum u8 {
	PunchRight,
	PunchLeft,
	KickRight,
	KickLeft,
}

anim_speed :: 0.1

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	k2.init(800, 600, "anima - example - cat fighter fsm")
	defer k2.shutdown()

	texture := k2.load_texture_from_file("assets/cat_fighter.png")
	defer k2.destroy_texture(texture)

	camera := k2.Camera{0, 0, 0, 2.0}

	g := anima.new_grid(50, 50, uint(texture.width), uint(texture.height))

	cat := anima_fsm.create(CatAnim)
	defer anima_fsm.destroy(cat)

	anima_fsm.add(
		cat,
		CatAnim.PunchRight,
		anima.new_animation(anima.grid_frames(&g, "6-9", 3), anim_speed),
	)
	anima_fsm.add(
		cat,
		CatAnim.PunchLeft,
		anima.new_animation(anima.grid_frames(&g, "6-9", 3), anim_speed, flip_v = true),
	)
	anima_fsm.add(
		cat,
		CatAnim.KickLeft,
		anima.new_animation(anima.grid_frames(&g, "0-9", 4, "8-1", 4), anim_speed),
	)
	anima_fsm.add(
		cat,
		CatAnim.KickRight,
		anima.new_animation(anima.grid_frames(&g, "0-9", 4, "8-1", 4), anim_speed, flip_v = true),
	)

	anima_fsm.play(cat, CatAnim.PunchRight)

	for k2.update() {
		dt := k2.get_frame_time()

		if k2.key_went_down(.Q) {
			anima_fsm.play(cat, CatAnim.PunchLeft)
		}

		if k2.key_went_down(.W) {
			anima_fsm.play(cat, CatAnim.PunchRight)
		}

		if k2.key_went_down(.A) {
			anima_fsm.play(cat, CatAnim.KickRight)
		}

		if k2.key_went_down(.S) {
			anima_fsm.play(cat, CatAnim.KickLeft)
		}

		anima_fsm.update(cat, dt)

		k2.clear(k2.BLACK)

		k2.set_camera(camera)

		anima_karl2d.fsm_draw(cat, texture, 100, 100)

		k2.draw_text("Q/W to punch left/right, A/S to kick left/right", {10, 10}, 10, k2.GREEN)

		k2.present()
	}
}

