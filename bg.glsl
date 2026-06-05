#version 330
in vec2 fragTexCoord;
out vec4 finalColor;

uniform float time;
uniform vec2 windowSize;

float oscillateBetween(float a, float b, float t) {
  float normalized = sin(t) / 2 + 0.5;
  return normalized * abs(b - a) + min(a, b);
}

void main() {
  vec2 coord = gl_FragCoord.xy;
  float t = time * 0.5;
  float s = 1 / windowSize.y;

  float rod_freq = 8;
  float rod_rotate_period = 39;
  float color1 = (sin(dot(coord, vec2(sin(t * 2 * 3.14159 / rod_rotate_period), cos(t * 2 * 3.14159 / rod_rotate_period))) * rod_freq * s + t) + 1.0) * 0.5;
  // float color1 = 0;

  float orbit_scale = 5;
  float orbit_period = 10;
  vec2 center = windowSize / 2 + orbit_scale * vec2(windowSize.y / 2 * sin(-t * 2 * 3.14159 / orbit_period), windowSize.y / 2 * cos(-t * 2 * 3.14159 / orbit_period));
  // vec2 center = windowSize / 2;

  float ring_freq = 6;
  float color2 = (cos(length(coord - center) * ring_freq * s) + 1.0) * 0.5;
  // float color2 = 0;

  float c = color1 + color2;

  // For the final colors to match up with our general color palette, we
  // basically need to oscillate around roughly:
  //
  // "Warm purple": rgb(134, 68, 154) (0.52, 0.26, 0.60)
  // "Cool purple": rgb(101, 31, 170) (0.39, 0.12, 0.66)
  float blueWarble = sin(t * 0.12345 * 3.14159) * 0.1 + 0.2;
  // float blueWarble = 0;
  finalColor = vec4(
    oscillateBetween(0.52, 0.39, c * 3.14159),
    oscillateBetween(0.26, 0.12, c * 3.14159),
    oscillateBetween(0.60, 0.66, c * 3.14159) + blueWarble,
    1.0
  );
}
