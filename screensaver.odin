package screensaver

import "core:fmt"
import "core:math"
import "core:math/noise"
import "core:os"
import rl "vendor:raylib"

mohaveData :: #load("Mohave-Regular.otf")

v2 :: [2]f32
v3 :: [3]f32

c_bg := rl.Color{134, 68, 154, 255}

// Offline render settings (--video flag)
VIDEO_W, VIDEO_H :: 1920, 1080
VIDEO_SS :: 4 // supersample factor
VIDEO_FPS :: 30
RENDER_DURATION :: 72 // seconds (LCM of all periods)

main :: proc() {
	render_video := false
	for arg in os.args[1:] {
		if arg == "--video" {
			render_video = true
		}
	}

	target: rl.RenderTexture2D
	if render_video {
		rl.SetConfigFlags({.WINDOW_HIDDEN})
		rl.InitWindow(VIDEO_W, VIDEO_H, "Handmade Network Expo 2026")
		target = rl.LoadRenderTexture(VIDEO_W * VIDEO_SS, VIDEO_H * VIDEO_SS)
		os.make_directory("frames")
	} else {
		rl.InitWindow(800, 450, "Handmade Network Expo 2026")
		rl.SetWindowState({.WINDOW_RESIZABLE})
		rl.SetConfigFlags({.VSYNC_HINT})
		rl.HideCursor()
		rl.MaximizeWindow()
	}

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

	frame := 0
	video_frames := VIDEO_FPS * RENDER_DURATION
	for {
		t: f32
		render_w, render_h: i32
		dpi: v2

		if render_video {
			if frame >= video_frames {
				break
			}
			t = f32(frame) / VIDEO_FPS
			render_w, render_h = VIDEO_W * VIDEO_SS, VIDEO_H * VIDEO_SS
			dpi = {1, 1}
		} else {
			if rl.WindowShouldClose() {
				break
			}
			t = f32(rl.GetTime())
			render_w, render_h = rl.GetRenderWidth(), rl.GetRenderHeight()
			dpi = rl.GetWindowScaleDPI()
		}

		if !render_video && rl.IsKeyPressed(rl.KeyboardKey.F) {
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

		if render_video {
			rl.BeginTextureMode(target)
		} else {
			rl.BeginDrawing()
		}
		rl.ClearBackground(rl.BLACK)

		rl.SetShaderValue(plasma, time_loc, &t, .FLOAT)
		shaderRenderSize := v2{f32(render_w), f32(render_h)}
		rl.SetShaderValue(plasma, render_size_loc, &shaderRenderSize, .VEC2)
		rl.BeginShaderMode(plasma)
		rl.DrawRectangle(0, 0, render_w, render_h, rl.WHITE)
		rl.EndShaderMode()

		window_size := v2{f32(render_w), f32(render_h)} / dpi
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
			// theta: f32 = 0

			rotated := rl.Vector3RotateByAxisAngle(verts[id], {0, 0, 1}, theta)

			// In order to get nice waves of noise traveling over the sphere while
			// allowing perfect loops, we "unwrap" the sphere around its vertical
			// axis (mapping vertex angle to x) and the vertex's vertical position to
			// y. This gives us 2D rectangular coordinates for each vertex, which we
			// then map to an annulus (ring) in 2D simplex noise. We then rotate that
			// annulus at whatever speed we desire. Because this is circular, we get
			// perfect loops.
			//
			// The parameters to vary are:
			// - Annulus inner radius: Controls the horizontal noise frequency, as
			//   well as the distortion in noise speed between the top and bottom of
			//   the sphere. A larger radius means higher noise frequency and less
			//   distortion; a smaller radius means lower noise frequency but more
			//   distortion. Note that this also affects the speed of wave travel.
			// - Annulus thickness: Controls the vertical noise frequency. Slight
			//   misnomer, because it is just a scale factor applied to the vertex's
			//   z coordinate when mapped to the annulus.
			// - Period: Controls how quickly you proceed around the annulus.
			annulus_inner_radius :: 1
			annulus_thickness :: 0.6
			noise_period :: 12 // seconds
			noise_scale_amt :: 0.08
			v_2d := v2{(math.atan2(v.x, v.y) + math.PI) / (2 * math.PI), 1 - v.z}
			v_theta := (f64(t) * 2 * math.PI / noise_period) + f64(v_2d.x) * 2 * math.PI
			v_radius := annulus_inner_radius + f64(v_2d.y) * annulus_thickness
			n := noise.noise_2d(0, {v_radius * math.cos(v_theta), v_radius * math.sin(v_theta)})
			v_scale := 1 + (n + 1) / 2 * noise_scale_amt

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

		if render_video {
			rl.EndTextureMode()

			img := rl.LoadImageFromTexture(target.texture)
			rl.ImageFlipVertical(&img) // render textures are stored upside down
			rl.ImageResize(&img, VIDEO_W, VIDEO_H)
			rl.ExportImage(img, fmt.ctprintf("frames/frame_%05d.png", frame))
			rl.UnloadImage(img)

			fmt.printfln("Rendered frame %d/%d", frame + 1, video_frames)
		} else {
			rl.EndDrawing()
		}

		frame += 1
	}

	if render_video {
		fmt.println()
		rl.UnloadRenderTexture(target)
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
