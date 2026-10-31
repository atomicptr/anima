package cat_fighter_fsm_karl2d

import "../../anima"
import "../../anima/anima_fsm"
import "../../anima/anima_sdl3"
import "core:fmt"
import "vendor:sdl3"
import sdl3_image "vendor:sdl3/image"

CatAnim :: enum u8 {
	PunchRight,
	PunchLeft,
	KickRight,
	KickLeft,
}

anim_speed :: 0.1

main :: proc() {
	if !sdl3.Init({.VIDEO}) {
		panic(fmt.tprintf("sdl: could not initialize: %s", sdl3.GetError()))
	}
	defer sdl3.Quit()

	window := sdl3.CreateWindow("anima - example - cat fighter fsm", 800, 600, {})
	if window == nil {
		panic(fmt.tprintf("sdl: could not create window: %s", sdl3.GetError()))
	}
	defer sdl3.DestroyWindow(window)

	sdl3.SetWindowSurfaceVSync(window, 1)

	renderer := sdl3.CreateRenderer(window, nil)
	if renderer == nil {
		panic(fmt.tprintf("sdl: could not create renderer: %s", sdl3.GetError()))
	}
	defer sdl3.DestroyRenderer(renderer)

	surface := sdl3_image.Load("assets/cat_fighter.png")
	if renderer == nil {
		panic(fmt.tprintf("sdl: could not load file: %s", sdl3.GetError()))
	}
	defer sdl3.DestroySurface(surface)

	texture := sdl3.CreateTextureFromSurface(renderer, surface)
	if texture == nil {
		panic(fmt.tprintf("sdl: could not create texture: %s", sdl3.GetError()))
	}
	defer sdl3.DestroyTexture(texture)

	sdl3.SetTextureScaleMode(texture, .NEAREST)

	width: f32 = 0.0
	height: f32 = 0.0

	assert(sdl3.GetTextureSize(texture, &width, &height))

	g := anima.new_grid(50, 50, uint(width), uint(height))

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

	last_time := sdl3.GetTicks()

	main_loop: for {
		for ev: sdl3.Event; sdl3.PollEvent(&ev); {
			#partial switch ev.type {
			case .QUIT:
				break main_loop
			case .WINDOW_CLOSE_REQUESTED:
				break main_loop
			case .KEY_DOWN:
				if ev.key.repeat do continue

				#partial switch ev.key.scancode {
				case .Q:
					anima_fsm.play(cat, .PunchLeft)
				case .W:
					anima_fsm.play(cat, .PunchRight)
				case .A:
					anima_fsm.play(cat, .KickRight)
				case .S:
					anima_fsm.play(cat, .KickLeft)
				}
			}
		}

		now := sdl3.GetTicks()
		dt := f32(now - last_time) / 1000.0
		last_time = now

		anima_fsm.update(cat, dt)

		sdl3.SetRenderDrawColor(renderer, 0, 0, 0, 255)
		sdl3.RenderClear(renderer)

		anima_sdl3.fsm_draw(cat, renderer, texture, 100, 100, zoom = 2.0)

		sdl3.SetRenderDrawColor(renderer, 0, 255, 0, 255)
		sdl3.RenderDebugText(renderer, 10, 10, "Q/W to punch left/right, A/S to kick left/right")

		sdl3.RenderPresent(renderer)
	}
}
