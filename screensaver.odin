package screensaver

import "core:math"
import rl "vendor:raylib"

mohaveData :: #load("Mohave-Regular.otf")

v2 :: [2]f32
v3 :: [3]f32

c_bg := rl.Color{134, 68, 154, 255}

main :: proc() {
	rl.InitWindow(800, 450, "Handmade Network Expo 2026")
	rl.SetWindowState({.WINDOW_RESIZABLE})

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

	for !rl.WindowShouldClose() {
		t := f32(rl.GetTime())

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
		text_pos := window_center - {scale * 1.1, scale * 0.4}
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

		theta: f32 = f32(t) * -1 * 2 * math.PI / 20
		rot :: proc(v: v3, theta: f32) -> v3 {
			return rl.Vector3RotateByAxisAngle(v, {0, 0, 1}, theta)
		}
		proj :: proc(v: v3, window_size: v2) -> v2 {
			scale := content_scale(window_size.y) // the "radius" of the dome
			pos := v2{window_size.x / 2 - scale * 2.5, window_size.y * 0.54} // the center pos of the dome
			return {v.x, v.z} * {1, -1} * scale + pos
		}
		transform :: proc(v: v3, theta: f32, window_size: v2) -> v2 {
			return proj(rot(v, theta), window_size)
		}

		for v, i in verts {
			if i < num_inner_verts {
				continue
			}
			rl.DrawCircleV(
				transform(v, theta, window_size),
				0.025 * content_scale(window_size.y),
				rl.Color{255, 255, 255, vert_opacity(rot(v, theta).y)},
			)
		}
		for edge in edges {
			a_rot := rot(verts[edge[0]], theta)
			b_rot := rot(verts[edge[1]], theta)
			a_proj := transform(verts[edge[0]], theta, window_size)
			b_proj := transform(verts[edge[1]], theta, window_size)
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
	opacity := clamp(math.remap(y, -0.3, 0.2, 255, 0), 0, 255)
	return u8(opacity)
}

content_scale :: proc(window_height: f32) -> f32 {
	return window_height * 0.15
}
