// neon_gate.glsl -- bloom gate pre-pass. Added 2026-07-28 for THERMALS.
//
// MUST be the FIRST custom-shader in the chain, immediately before
// macbook-m4max-2056-theme-friendly-sharp.glsl. It passes the terminal image
// through untouched in RGB and writes the neon-bloom emission weight into
// ALPHA, so the phosphor shader's 24-tap gather reads a precomputed answer
// per tap instead of re-running the full HSV/hue gate 24x per pixel per
// frame. The gate math below is a byte-for-byte port of the per-tap gate the
// phosphor shader used inline until 2026-07-28; the constants here MUST stay
// in sync with that file (satGateLo/Hi, dim boost, fgHue*, blue bias).
//
// ENCODING: alpha = w * 0.5. Raw w spans 0..1.9 (blue bias can push past
// 1.0), so the 0.5 scale keeps the stored value <= 0.95, safely below the
// 1.0 the raw terminal image carries (background-opacity = 1). The phosphor
// shader treats alpha > 0.99 as "no gate ran" and recomputes inline -- so if
// THIS file ever fails to compile (ghostty ignores broken shaders silently),
// the chain degrades to exactly the old behaviour instead of blooming
// everything at full weight.
//
// Downstream alpha is never seen by the window: the phosphor shader writes
// alpha = 1.0 as it always has.

// ---- constants mirrored from macbook-m4max-2056-theme-friendly-sharp.glsl ----
float gateSatLo = 0.22;   // = neonBloomSatGateLo. Grey weights are load-bearing; do not lower.
float gateSatHi = 0.55;   // = neonBloomSatGateHi
float gateDimBoost = 0.35; // = neonDimBoost
float gateFgHueExclude = 1.0;              // = fgHueExclude
vec3  gateFgHueRef = vec3(0.0, 0.690, 0.071); // #00b012, must track config `foreground`
float gateFgHueBand = 0.055;               // = fgHueBand
float gateFgHueSoft = 0.045;               // = fgHueSoft

// Hue in TURNS (0..1). 0.0 for achromatic input.
float hue01(vec3 c) {
    float mx = max(c.r, max(c.g, c.b));
    float mn = min(c.r, min(c.g, c.b));
    float d = mx - mn;
    if (d < 1e-5) return 0.0;
    float h;
    if (mx == c.r)      h = mod((c.g - c.b) / d, 6.0);
    else if (mx == c.g) h = (c.b - c.r) / d + 2.0;
    else                h = (c.r - c.g) / d + 4.0;
    return h / 6.0;
}

float hueDist(float a, float b) {
    float d = abs(a - b);
    return min(d, 1.0 - d);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec3 c = texture(iChannel0, uv).rgb;

    float tmax = max(c.r, max(c.g, c.b));
    float tmin = min(c.r, min(c.g, c.b));
    float tsat = (tmax - tmin) / max(tmax, 0.0001);

    // Saturated-dim boost: dim fully-saturated chrome (pane borders) glows.
    float lift = gateDimBoost * (1.0 - tmax) * smoothstep(0.60, 0.90, tsat);
    // Emission = sat gate x peak channel (not luma), same as the inline gate.
    float w = smoothstep(gateSatLo, gateSatHi, tsat) * min(tmax + lift, 1.0);

    // Foreground hue exclusion (fg #00b012 is fully saturated; sat can't gate it).
    if (gateFgHueExclude > 0.0) {
        float hd = hueDist(hue01(c), hue01(gateFgHueRef));
        w *= smoothstep(gateFgHueBand, gateFgHueBand + gateFgHueSoft, hd);
    }

    // Blue compensation toward perceptual parity with warm hues.
    float blueBias = clamp(c.b - max(c.r, c.g), 0.0, 1.0);
    w *= 1.0 + 0.9 * blueBias;

    fragColor = vec4(c, w * 0.5);
}
