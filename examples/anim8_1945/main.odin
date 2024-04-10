package main

import "../../anima"
import "../../anima/anima_raylib"
import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

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

	rl.InitWindow(800, 600, "anima - example")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	image := rl.LoadImage("assets/1945.png")
	texture := rl.LoadTextureFromImage(image)
	defer rl.UnloadTexture(texture)
	rl.UnloadImage(image)

	g32 := anima.new_grid(32, 32, 1024, 768, 3, 3, 1)

	spinning := []^anima.Animation {
		anima.new_animation(anima.grid_frames(&g32, "0-7", 0), 0.1),
		anima.new_animation(anima.grid_frames(&g32, 17, "7-10", 17, "9-6"), 0.2),
		anima.new_animation(anima.grid_frames(&g32, "0-7", 1), 0.3),
		anima.new_animation(anima.grid_frames(&g32, 18, "7-10", 18, "9-6"), 0.4),
		anima.new_animation(anima.grid_frames(&g32, "0-7", 2), 0.5),
		anima.new_animation(anima.grid_frames(&g32, 19, "7-10", 19, "9-6"), 0.6),
		anima.new_animation(anima.grid_frames(&g32, "0-7", 3), 0.7),
		anima.new_animation(anima.grid_frames(&g32, 20, "7-10", 20, "9-6"), 0.8),
		anima.new_animation(anima.grid_frames(&g32, "0-7", 4), 0.9),
	}
	defer proc(spinner: []^anima.Animation) {
		for spin in spinner {
			anima.destroy_animation(spin)
		}
	}(spinning)

	g64 := anima.new_grid(64, 64, 1024, 768, 299, 101, 2)

	plane := anima.new_animation(anima.grid_frames(&g64, 0, "0-2"), 0.1)
	defer anima.destroy_animation(plane)
	seaplane := anima.new_animation(anima.grid_frames(&g64, "1-3", 2), 0.1)
	defer anima.destroy_animation(seaplane)
	seaplane_angle: f32 = 0.0

	gs := anima.new_grid(32, 98, 1024, 768, 366, 102, 1)

	submarine := anima.new_animation(anima.grid_frames(&gs, "0-6", 0, "5-2", 0), 0.5)
	defer anima.destroy_animation(submarine)

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
			for spinner in spinning {
				spinner.flip_h = !spinner.flip_h
			}

			plane.flip_v = !plane.flip_v
			seaplane.flip_v = !seaplane.flip_v
			submarine.flip_v = !submarine.flip_v
		}

		for spinner in spinning {
			anima.update(spinner, dt)
		}

		anima.update(plane, dt)
		anima.update(seaplane, dt)
		anima.update(submarine, dt)

		seaplane_angle += 20.0 * dt

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		for spinner, i in spinning {
			anima_raylib.draw(spinner, texture, f32(i) * 75, f32(i) * 50)
		}

		anima_raylib.draw(plane, texture, 100, 400)
		anima_raylib.draw(seaplane, texture, 250, 432, seaplane_angle)
		anima_raylib.draw(submarine, texture, 600, 100)

		rl.EndDrawing()
	}
}
