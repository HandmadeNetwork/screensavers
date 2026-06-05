package screensaver

import "core:math"
import "core:math/noise"
import rl "vendor:raylib"

mohaveData :: #load("Mohave-Regular.otf")

v2 :: [2]f32
v3 :: [3]f32

c_bg := rl.Color{134, 68, 154, 255}

main :: proc() {
	rl.InitWindow(800, 450, "Handmade Network Expo 2026")
	rl.SetWindowState({.WINDOW_RESIZABLE})
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.HideCursor()
	rl.MaximizeWindow()

	mohave := rl.LoadFontFromMemory(
		".otf",
		raw_data(mohaveData),
		i32(len(mohaveData)),
		400,
		nil,
		0,
	)

	plasma := rl.LoadShaderFromMemory(nil, #load("bg.glsl"))
	time_loc := rl.GetShaderLocation(plasma, "time")
	render_size_loc := rl.GetShaderLocation(plasma, "windowSize")

	sizeBeforeFullscreen: [2]i32
	posBeforeFullscreen: [2]f32

	for !rl.WindowShouldClose() {
		t := f32(rl.GetTime())

		if rl.IsKeyPressed(rl.KeyboardKey.F) {
			if rl.IsWindowState({.WINDOW_UNDECORATED}) {
				rl.ClearWindowState({.WINDOW_UNDECORATED, .WINDOW_TOPMOST})
				rl.SetWindowPosition(i32(posBeforeFullscreen.x), i32(posBeforeFullscreen.y))
				rl.SetWindowSize(sizeBeforeFullscreen.x, sizeBeforeFullscreen.y)
			} else {
				posBeforeFullscreen = rl.GetWindowPosition()
				sizeBeforeFullscreen = [2]i32{rl.GetScreenWidth(), rl.GetScreenHeight()}
				rl.SetWindowState({.WINDOW_UNDECORATED, .WINDOW_TOPMOST})
				rl.MaximizeWindow()
			}
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		rl.SetShaderValue(plasma, time_loc, &t, .FLOAT)
		shaderRenderSize := v2{f32(rl.GetRenderWidth()), f32(rl.GetRenderHeight())}
		rl.SetShaderValue(plasma, render_size_loc, &shaderRenderSize, .VEC2)
		rl.BeginShaderMode(plasma)
		rl.DrawRectangle(0, 0, rl.GetRenderWidth(), rl.GetRenderHeight(), rl.WHITE)
		rl.EndShaderMode()

		window_size :=
			v2{f32(rl.GetRenderWidth()), f32(rl.GetRenderHeight())} / rl.GetWindowScaleDPI()
		window_center := window_size / 2

		scale := content_scale(window_size.y)
		text_pos := window_center - {scale * 1.1, scale * 0.38}
		rl.DrawTextEx(
			mohave,
			"HANDMADE NETWORK EXPO",
			text_pos,
			scale * 0.6,
			scale * -.003,
			rl.WHITE,
		)
		rl.DrawTextEx(
			mohave,
			"Vancouver 2O26",
			text_pos + {scale * 0.03, scale * 0.6},
			scale * 0.4,
			scale * -.003,
			rl.WHITE,
		)

		to_world :: proc(t: f32, id: int) -> v3 {
			v := verts[id]

			rotate_period :: 36
			theta: f32 = f32(t) * -1 * 2 * math.PI / rotate_period

			rotated := rl.Vector3RotateByAxisAngle(verts[id], {0, 0, 1}, theta)

			vertex_angle := math.atan2(v.x, v.y) + math.PI
			noise_width :: 2
			noise_scale_amt :: 0.08
			noise_speed :: 1
			noise := noise.noise_2d(
				0,
				{(f64(vertex_angle) + f64(t) * noise_speed) / noise_width, f64(v.y)},
			)
			v_scale := 1 + (noise + 1) / 2 * noise_scale_amt

			return rotated * v_scale
		}
		to_screen :: proc(v: v3, window_size: v2) -> v2 {
			scale := content_scale(window_size.y) // the "radius" of the dome
			pos := v2{window_size.x / 2 - scale * 2.5, window_size.y * 0.54} // the center pos of the dome
			return {v.x, v.z} * {1, -1} * scale + pos
		}
		transform :: proc(t: f32, id: int, window_size: v2) -> v2 {
			return to_screen(to_world(t, id), window_size)
		}

		for _, i in verts {
			if i < num_inner_verts {
				continue
			}
			rl.DrawCircleV(
				transform(t, i, window_size),
				0.025 * content_scale(window_size.y),
				rl.Color{255, 255, 255, vert_opacity(to_world(t, i).y)},
			)
		}
		for edge in edges {
			a_rot := to_world(t, edge[0])
			b_rot := to_world(t, edge[1])
			a_proj := transform(t, edge[0], window_size)
			b_proj := transform(t, edge[1], window_size)
			rl.DrawLineEx(
				a_proj,
				b_proj,
				0.01 * content_scale(window_size.y),
				rl.Color{255, 255, 255, vert_opacity(min(a_rot.y, b_rot.y))},
			)
		}

		rl.EndDrawing()
	}

	rl.CloseWindow()
}

vert_opacity :: proc(y: f32) -> u8 {
	max_opacity, min_opacity :: 255, 0
	opacity := clamp(math.remap(y, -0.3, 0.2, max_opacity, min_opacity), min_opacity, max_opacity)
	return u8(opacity)
}

content_scale :: proc(window_height: f32) -> f32 {
	return window_height * 0.15
}
