package screensaver

import "core:math"
import rl "vendor:raylib"

v2 :: [2]f32
v3 :: [3]f32

c_bg := rl.Color{134, 68, 154, 255}

main :: proc() {
	rl.InitWindow(800, 450, "raylib [core] example - basic window")

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(c_bg)
		// rl.DrawText("Congrats! You created your first window!", 190, 200, 20, rl.LIGHTGRAY)
		rl.EndDrawing()

		theta: f32 = f32(rl.GetTime()) * -1 * 2 * math.PI / 20
		rot :: proc(v: v3, theta: f32) -> v3 {
			return rl.Vector3RotateByAxisAngle(v, {0, 0, 1}, theta)
		}
		proj :: proc(v: v3) -> v2 {
			scale :: 150
			pos :: v2{200, 200}
			return {v.x, v.z} * {1, -1} * scale + pos
		}
		transform :: proc(v: v3, theta: f32) -> v2 {
			return proj(rot(v, theta))
		}

		for v, i in verts {
			if i < num_inner_verts {
				continue
			}
			rl.DrawCircleV(
				transform(v, theta),
				3,
				rl.Color{255, 255, 255, vert_opacity(rot(v, theta).y)},
			)
		}
		for edge in edges {
			a_rot := rot(verts[edge[0]], theta)
			b_rot := rot(verts[edge[1]], theta)
			a_proj := transform(verts[edge[0]], theta)
			b_proj := transform(verts[edge[1]], theta)
			rl.DrawLineEx(
				a_proj,
				b_proj,
				1.5,
				rl.Color{255, 255, 255, vert_opacity(min(a_rot.y, b_rot.y))},
			)
		}
	}

	rl.CloseWindow()
}

vert_opacity :: proc(y: f32) -> u8 {
	opacity := clamp(math.remap(y, -0.3, 0.2, 255, 0), 0, 255)
	return u8(opacity)
}
