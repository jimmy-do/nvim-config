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
const float DURATION = 0.48; // Slightly quicker, while quintic easing preserves the glide.
const float MOVE_CLASS_THRESHOLD = 0.30; // Short/long timing boundary; independent of visual length.
const float MAX_TRAIL_LENGTH = 0.34; // Slightly longer comet without changing move classification.
const float THRESHOLD_MIN_DISTANCE = 3.0; // KNOB 1 2026-07-27 (was 1.5): scroll steps are 1-2 cells and spawned a trail per frame; pane jumps are far bigger and keep theirs. Revert: 1.5
const float BLUR = 3.0; // Silky antialiasing for diagonals and the moving edge.

// COMET FADE, take two (2026-07-22). Take one had three separate alpha
// regimes -- a glow fringe, a quadratic body ramp, and the AA edge -- meeting
// at visible seams, with a 0.10 tail floor that read as dirty grey behind a
// near-white cursor. This is ONE continuous field: alpha eases along the
// motion axis with smoothstep (C1-continuous, so there is no visible band
// where the fade begins or ends), and the tail floor is high enough that the
// tail still reads as the cursor colour, never as grey murk. No fringe layer.
const float TAIL_FADE = 0.18; // Long, gentle luminance ramp into the bright head.
// Distance is measured in cursor-cell widths. Short editing motions whisper;
// word jumps ramp in; pane-scale jumps get the full comet.
const float SPEED_FADE_START = 3.0;
const float SPEED_FADE_FULL = 10.0;

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

// Quintic smootherstep: zero velocity AND zero acceleration at both ends.
// Unlike EaseOutCirc, it has no near-vertical launch slope, so the cursor body
// glides into motion and settles without a perceptual snap.
float ease(float x) {
    x = clamp(x, 0.0, 1.0);
    return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
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
    // max() 2026-07-31: a ZERO-LENGTH edge makes dot(e,e) == 0 and this divide
    // 0.0/0.0 -> NaN, for every fragment on screen. The trail parallelogram is
    // degenerate exactly when head_eased == tail_eased, which is not a rare
    // instant: `progress` is CLAMPED, so it sits at exactly 0.0 on any frame
    // rendered at the cursor-change timestamp and at exactly 1.0 on every frame
    // after the animation ends, until the next cursor move. Measured: NaN over
    // 100% of the screen at both ends.
    //
    // NaN is also why the vertical-move suppression below could not contain
    // this — NaN * 0.0 is NaN, so `trailAlpha *= 0.0` does not clear it, and
    // neither does mix(sdfTrail_diag, sdfTrail_rect, isStraightMove): GLSL mix
    // evaluates BOTH operands, so a NaN diagonal SDF poisons a pure-vertical
    // move too. That is the j/k and C-d/C-u "cursor flies in from somewhere
    // off-screen" flash.
    vec2 proj = a + e * clamp(dot(w, e) / max(dot(e, e), 1e-12), 0.0, 1.0);
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

// Stable motion-aligned rectangular beam for diagonal travel. An oriented-box
// SDF avoids the four independently moving corners of the old parallelogram
// without the conspicuous circular end caps of a capsule.
float getSdfMotionBeam(in vec2 p, in vec2 a, in vec2 b, in vec2 cursorSize) {
    vec2 ba = b - a;
    float baLen2 = max(dot(ba, ba), 1e-12);
    vec2 axis = ba * inversesqrt(baLen2);
    vec2 normal = vec2(-axis.y, axis.x);
    vec2 halfCursor = cursorSize * 0.5;
    float halfLength = sqrt(baLen2) * 0.5 + dot(abs(axis), halfCursor);
    float halfWidth = dot(abs(normal), halfCursor);
    vec2 local = vec2(dot(p - (a + b) * 0.5, axis),
                      dot(p - (a + b) * 0.5, normal));
    float corner = min(halfWidth, min(halfCursor.x, halfCursor.y)) * 0.12;
    vec2 q = abs(local) - vec2(halfLength, halfWidth) + corner;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - corner;
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

        float isLongMove = step(MOVE_CLASS_THRESHOLD, lineLength);
        float distanceRatio = clamp(lineLength / MOVE_CLASS_THRESHOLD, 0.0, 1.0);

        // The head always travels; the old short branch set it to 1.0 on frame
        // one, instantly drawing the whole start-to-destination span. Give
        // short moves a modest distance-scaled tail delay so the comet grows
        // behind a moving cursor instead of appearing fully formed.
        head_eased = ease(progress);
        float shortDelay = mix(0.04, 0.16, distanceRatio);
        float tail_eased_short = ease(smoothstep(shortDelay, 1.0, progress));

        // Preserve the established long-move shape: its delay is the maximum
        // trail length expressed as a fraction of the total jump. Clamp below
        // 1.0 so smoothstep never receives equal or reversed edges at the
        // short/long boundary.
        float longDelay = clamp(MAX_TRAIL_LENGTH / lineLength, 0.02, 0.92);
        float tail_eased_long = ease(smoothstep(longDelay, 1.0, progress));
        tail_eased = mix(tail_eased_short, tail_eased_long, isLongMove);

        // detect straight moves
        vec2 delta_abs = abs(centerCC - centerCP); 
        float threshold = 0.001;
        float isHorizontal = step(delta_abs.y, threshold);
        float isVertical = step(delta_abs.x, threshold);
        float isStraightMove = max(isHorizontal, isVertical);

        vec2 head_center = mix(centerCP, centerCC, head_eased);
        vec2 tail_center = mix(centerCP, centerCC, tail_eased);

        // Diagonal path: one stable segment instead of a deforming four-corner
        // parallelogram. Horizontal/vertical paths retain the proven rectangle.
        float sdfTrail_diag = getSdfMotionBeam(
            vu, tail_center, head_center, currentCursor.zw
        );

        // -- Making the rectangle sdf (straight move) --

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
        // Hold the dimmest value over the very tip, then roll continuously into
        // the bright head. This reads as light shedding from the cursor instead
        // of a uniformly bright rubber band.
        float comet = mix(TAIL_FADE, 1.0, smoothstep(0.06, 1.0, along));

        float trailAlpha = clamp(antialising(sdfTrail), 0.0, 1.0) * comet;

        // Motion-sensitive intensity. iTimeCursorChange gives us distance, not
        // velocity history, but distance-per-cursor-event is the useful signal:
        // typing and tiny edits stay calm while deliberate navigation lights up.
        float distanceCells = lineLength / max(currentCursor.z, 1e-6);
        float motionEnergy = smoothstep(SPEED_FADE_START, SPEED_FADE_FULL, distanceCells);
        trailAlpha *= motionEnergy;

        // Belt and braces for the degenerate frames the max() above makes
        // merely finite rather than meaningful: when head and tail coincide the
        // trail has zero length and there is nothing to draw anyway. Gate it to
        // zero explicitly so a collapsed parallelogram can never paint, whatever
        // the driver decides sqrt() of a clamped-to-zero distance should be.
        // Costs nothing visually — these are exactly the frames where the trail
        // is a zero-area sliver at the two ends of the animation.
        trailAlpha *= step(1e-6, abs(head_eased - tail_eased));

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
