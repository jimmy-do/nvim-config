// sRGB -> Linear conversion (needed because Ghostty passes sRGB values but the shader pipeline operates in linear color space)
vec3 sRGBToLinear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

// --- CONFIGURATION ---
// 🔧 VENDORED + FIXED 2026-07-15: sRGBToLinear() REMOVED.
// The upstream author wrote it for `alpha-blending = linear-corrected` (the LINUX
// default). This machine is macOS, where the default is `alpha-blending = native`
// (Display P3) — verified via `ghostty +show-config --default`. Ghostty hands the
// shader colours in the CONFIGURED space, so on native there is nothing to convert:
// the call just darkened the trail (0.5 -> 0.21). THAT is why the trail was "too dark".
// ⚠️ If you ever set `alpha-blending = linear` or `linear-corrected`, PUT IT BACK.
vec4 TRAIL_COLOR = vec4(iCurrentCursorColor.rgb, iCurrentCursorColor.a); // for custom color: vec4(0.2, 0.6, 1.0, 0.5); (wrap in sRGBToLinear for correct brightness)
const float DURATION = 0.30; // in seconds. VENDORED+TUNED: was 0.09 ("way too goddamn fast").
const float MAX_TRAIL_LENGTH = 0.2;
const float THRESHOLD_MIN_DISTANCE = 3.0; // KNOB 1 2026-07-27 (was 1.5): scroll steps are 1-2 cells and spawned a trail per frame; pane jumps are far bigger and keep theirs. Revert: 1.5
const float BLUR = 2.0; // blur size in pixels (for antialiasing)

// COMET FADE, take two (2026-07-22). Take one had three separate alpha
// regimes -- a glow fringe, a quadratic body ramp, and the AA edge -- meeting
// at visible seams, with a 0.10 tail floor that read as dirty grey behind a
// near-white cursor. This is ONE continuous field: alpha eases along the
// motion axis with smoothstep (C1-continuous, so there is no visible band
// where the fade begins or ends), and the tail floor is high enough that the
// tail still reads as the cursor colour, never as grey murk. No fringe layer.
const float TAIL_FADE = 0.35; // alpha at the tail end; 1.0 at the head

// --- CONSTANTS for easing functions ---
const float PI = 3.14159265359;
const float C1_BACK = 1.70158;
const float C2_BACK = C1_BACK * 1.525;
const float C3_BACK = C1_BACK + 1.0;
const float C4_ELASTIC = (2.0 * PI) / 3.0;
const float C5_ELASTIC = (2.0 * PI) / 4.5;
const float SPRING_STIFFNESS = 9.0;
const float SPRING_DAMPING = 0.9;

// --- EASING FUNCTIONS ---

// // Linear
// float ease(float x) {
//     return x;
// }

// // EaseOutQuad
// float ease(float x) {
//     return 1.0 - (1.0 - x) * (1.0 - x);
// }

// // EaseOutCubic
// float ease(float x) {
//     return 1.0 - pow(1.0 - x, 3.0);
// }


// // EaseOutQuart
// float ease(float x) {
//     return 1.0 - pow(1.0 - x, 4.0);
// }

// // EaseOutQuint
// float ease(float x) {
//     return 1.0 - pow(1.0 - x, 5.0);
// }

// // EaseOutSine
// float ease(float x) {
//     return sin((x * PI) / 2.0);
// }

// // EaseOutExpo
// float ease(float x) {
//     return x == 1.0 ? 1.0 : 1.0 - pow(2.0, -10.0 * x);
// }

// EaseOutCirc
float ease(float x) {
    return sqrt(1.0 - pow(x - 1.0, 2.0));
}

// // EaseOutBack
// float ease(float x) {
//     return 1.0 + C3_BACK * pow(x - 1.0, 3.0) + C1_BACK * pow(x - 1.0, 2.0);
// }

// // EaseOutElastic
// float ease(float x) {
//     return x == 0.0 ? 0.0
//          : x == 1.0 ? 1.0
//                     : pow(2.0, -10.0 * x) * sin((x * 10.0 - 0.75) * C4_ELASTIC) + 1.0;
// }

// Parametric Spring
// float ease(float x) {
//     x = clamp(x, 0.0, 1.0);
//     float decay = exp(-SPRING_DAMPING * SPRING_STIFFNESS * x);
//     float freq = sqrt(SPRING_STIFFNESS * (1.0 - SPRING_DAMPING * SPRING_DAMPING));
//     float osc = cos(freq * 6.283185 * x) + (SPRING_DAMPING * sqrt(SPRING_STIFFNESS) / freq) * sin(freq * 6.283185 * x);
//     return 1.0 - decay * osc;
// }

float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Based on Inigo Quilez's 2D distance functions article: https://iquilezles.org/articles/distfunctions2d/
// Potencially optimized by eliminating conditionals and loops to enhance performance and reduce branching

float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a;
    vec2 w = p - a;
    vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
    float segd = dot(p - proj, p - proj);
    d = min(d, segd);

    float c0 = step(0.0, p.y - a.y);
    float c1 = 1.0 - step(0.0, p.y - b.y);
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    float allCond = c0 * c1 * c2;
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
    float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
    s *= flip;
    return d;
}

float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
    float s = 1.0;
    float d = dot(p - v0, p - v0);

    d = seg(p, v0, v3, s, d);
    d = seg(p, v1, v0, s, d);
    d = seg(p, v2, v1, s, d);
    d = seg(p, v3, v2, s, d);

    return s * sqrt(d);
}

vec2 normalize(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

float antialising(float distance) {
	return 1. - smoothstep(0., normalize(vec2(BLUR, BLUR), 0.).x, distance);
}

vec4 readFramePixel(vec2 fragCoord) {
    return texture(iChannel0, (floor(fragCoord) + vec2(0.5)) / iResolution.xy);
}

float determineIfTopRightIsLeading(vec2 a, vec2 b) {
    float condition1 = step(b.x, a.x) * step(a.y, b.y); // a.x < b.x && a.y > b.y
    float condition2 = step(a.x, b.x) * step(b.y, a.y); // a.x > b.x && a.y < b.y

    // if neither condition is met, return 1 (else case)
    return 1.0 - max(condition1, condition2);
}

vec2 getRectangleCenter(vec4 rectangle) {
    return vec2(rectangle.x + (rectangle.z / 2.), rectangle.y - (rectangle.w / 2.));
}


void mainImage(out vec4 fragColor, in vec2 fragCoord){
    #if !defined(WEB)
    fragColor = readFramePixel(fragCoord.xy);
    #endif

    // normalization & setup(-1, 1 coords)
    vec2 vu = normalize(fragCoord, 1.);
    vec2 offsetFactor = vec2(-.5, 0.5);
    
    vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.));

    vec2 centerCC = currentCursor.xy - (currentCursor.zw * offsetFactor);
    vec2 centerCP = previousCursor.xy - (previousCursor.zw * offsetFactor);

    vec2 delta = centerCP - centerCC;
    float lineLength = length(delta);

     float sdfCurrentCursor = getSdfRectangle(vu, centerCC, currentCursor.zw * 0.5);
	
     vec4 newColor = vec4(fragColor);
	
     float minDist = currentCursor.w * THRESHOLD_MIN_DISTANCE;
     float progress = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
     if (lineLength > minDist) {
         // ANIMATION logic
        
        float head_eased = 0.0;
        float tail_eased = 0.0;

        float tail_delay_factor = MAX_TRAIL_LENGTH / lineLength;

        float isLongMove = step(MAX_TRAIL_LENGTH, lineLength);

        float head_eased_short = ease(progress);
        float tail_eased_short = ease(smoothstep(tail_delay_factor, 1.0, progress));
        float head_eased_long = 1.0;
        float tail_eased_long = ease(progress);

        head_eased = mix(head_eased_long, head_eased_short, isLongMove);
        tail_eased = mix(tail_eased_long, tail_eased_short, isLongMove);

        // detect straight moves
        vec2 delta_abs = abs(centerCC - centerCP); 
        float threshold = 0.001;
        float isHorizontal = step(delta_abs.y, threshold);
        float isVertical = step(delta_abs.x, threshold);
        float isStraightMove = max(isHorizontal, isVertical);

        // -- Making the parallelogram sdf (diagonal move) --

        // animate the TOP-LEFT corners
        vec2 head_pos_tl = mix(previousCursor.xy, currentCursor.xy, head_eased);
        vec2 tail_pos_tl = mix(previousCursor.xy, currentCursor.xy, tail_eased);

        float isTopRightLeading = determineIfTopRightIsLeading(currentCursor.xy, previousCursor.xy);
        float isBottomLeftLeading = 1.0 - isTopRightLeading;
        
        // v0, v1 : "front" of the trail (head)
        vec2 v0 = vec2(head_pos_tl.x + currentCursor.z * isTopRightLeading, head_pos_tl.y - currentCursor.w);
        vec2 v1 = vec2(head_pos_tl.x + currentCursor.z * isBottomLeftLeading, head_pos_tl.y);
        
        // v2, v3: "back" of the trail (tail)
        vec2 v2 = vec2(tail_pos_tl.x + currentCursor.z * isBottomLeftLeading, tail_pos_tl.y);
        vec2 v3 = vec2(tail_pos_tl.x + currentCursor.z * isTopRightLeading, tail_pos_tl.y - previousCursor.w);

        float sdfTrail_diag = getSdfParallelogram(vu, v0, v1, v2, v3);

        // -- Making the rectangle sdf (straight move) --

        vec2 head_center = mix(centerCP, centerCC, head_eased);
        vec2 tail_center = mix(centerCP, centerCC, tail_eased);

        vec2 min_center = min(head_center, tail_center);
        vec2 max_center = max(head_center, tail_center);
        
        vec2 box_size = (max_center - min_center) + currentCursor.zw;
        vec2 box_center = (min_center + max_center) * 0.5;

        float sdfTrail_rect = getSdfRectangle(vu, box_center, box_size * 0.5);

        // -- FINAL SELECTING AND DRAWING --
        float sdfTrail = mix(sdfTrail_diag, sdfTrail_rect, isStraightMove);
        
        vec4 trail = TRAIL_COLOR;

        // Single continuous comet fade along the eased motion axis.
        vec2 axis = head_center - tail_center;
        float axisLen2 = max(dot(axis, axis), 1e-6);
        float along = clamp(dot(vu - tail_center, axis) / axisLen2, 0.0, 1.0);
        float comet = mix(TAIL_FADE, 1.0, smoothstep(0.0, 1.0, along));

        float trailAlpha = clamp(antialising(sdfTrail), 0.0, 1.0) * comet;

        // KNOB 2 2026-07-27: purely vertical moves never trail. Page scrolls
        // (u/d) are pure-vertical cursor jumps and re-fired the trail on every
        // press; horizontal and diagonal jumps (pane moves, word motions) keep
        // theirs. CAVEAT: vertical tmux pane jumps (C-j/C-k) also lose their
        // trail. Revert: delete this line.
        // ...and "purely vertical" was too strict: a page shift usually lands
        // the cursor on a different COLUMN (indent, first non-blank), so the
        // move is slightly diagonal and isVertical (0.001 tolerance) never
        // fired. Vertical-DOMINANT: suppress when the move is >4x taller than
        // it is wide. Real pane hops sideways and word motions are nowhere
        // near that ratio.
        float vertDominant = step(delta_abs.x * 4.0, delta_abs.y);
        trailAlpha *= 1.0 - max(isVertical, vertDominant);

        // Once the trail collapses onto the current cursor, its antialiased
        // fringe extends just beyond the cursor punch-hole below. Without an
        // explicit end fade that fringe survives as a tiny mark whenever the
        // cursor blinks off, most noticeably on an otherwise empty line.
        trailAlpha *= 1.0 - smoothstep(0.92, 1.0, progress);

        newColor = mix(newColor, trail, trailAlpha);

        // punch hole
        newColor = mix(newColor, fragColor, step(sdfCurrentCursor, 0.));
    }

    fragColor = newColor;
}
