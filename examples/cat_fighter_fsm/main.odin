package cat_fighter_fsm

import "../../anima"
import "../../anima/anima_fsm"
import "../../anima/anima_raylib"
import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

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

	rl.InitWindow(800, 600, "anima - example - cat fighter fsm")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	image := rl.LoadImage("assets/cat_fighter.png")
	texture := rl.LoadTextureFromImage(image)
	defer rl.UnloadTexture(texture)
	rl.UnloadImage(image)

	camera := rl.Camera2D{0, 0, 0.0, 2.0}

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

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		if rl.IsKeyPressed(rl.KeyboardKey.Q) {
			anima_fsm.play(cat, CatAnim.PunchLeft)
		}

		if rl.IsKeyPressed(rl.KeyboardKey.W) {
			anima_fsm.play(cat, CatAnim.PunchRight)
		}

		if rl.IsKeyPressed(rl.KeyboardKey.A) {
			anima_fsm.play(cat, CatAnim.KickRight)
		}

		if rl.IsKeyPressed(rl.KeyboardKey.S) {
			anima_fsm.play(cat, CatAnim.KickLeft)
		}

		anima_fsm.update(cat, dt)

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		rl.BeginMode2D(camera)

		anima_raylib.fsm_draw(cat, texture, 100, 100)

		rl.DrawText("Q/W to punch left/right, A/S to kick left/right", 10, 10, 10, rl.GREEN)

		rl.EndMode2D()

		rl.EndDrawing()
	}
}
