// macbook-m4max-2056-theme-friendly-sharp.glsl
// Ported 2026-07-18 from 321urx-monitor-preset-theme-friendly-sharp.glsl.
// Tuned for MacBook Pro M4 Max @ 1900x1200, NON-HIDPI (1:1 backing) as of 2026-07-25.
// History: 2056x1329 HiDPI (4112x2658 backing) -> 2336x1510 non-HiDPI 07-23 -> 1900x1200
// non-HiDPI 07-25. The filename still says 2056; the resolution in it is stale, not the file.
// Goal: sharp, theme-friendly CRT scanlines without amber tint, wash, bloom, or softening.

// Original shader collected from: https://www.shadertoy.com/view/WsVSzV
// Licensed under Shadertoy's default since the original creator didn't provide any license. (CC BY NC SA 3.0)
// Slight modifications were made to give a green-ish effect.

// This shader was modified by April Hall (arithefirst)
// Sourced from https://github.com/m-ahdal/ghostty-shaders/blob/main/retro-terminal.glsl
// Changes made:
// - Removed tint
// - Made the boundaries match ghostty's background color

float warp = 0.0; // curvature OFF
float scan = 0.0; // Scanlines OFF (was 1.56), matching the 321urx preset's clean-text look
float paperLift = 0.10; // 0.0 -> 0.10 on 2026-07-28: RESTORED. The 07-27 "drop sepia + grain" commit
                        // removed this without being asked; Jimmy wants the warm paper lift on
                        // neutral foreground. Do not zero it again as a side effect of bloom work.
float paperGrain = 0.0; // stays 0: Jimmy's rule is no grain; only the lift comes back.

// Motion ports from amber-phosphor-321urx.glsl, kept color-neutral.
float barDir = 1.0;
float barGap = 6.0;
float barSpeed = 0.09;
float barHeight = 0.10;
float barDark = 0.0;    // 0.055 -> 0.0 on 2026-07-28: bar was VISIBLY rolling — animation=false
                        // does NOT freeze iTime, it advances on every redraw (cursor blink,
                        // clock). Jimmy's rule: no grain, no scanlines, no rolling artifacts.
float retraceN = 21.0;
float retraceBright = 0.0; // 0.045 -> 0.0 on 2026-07-28, same reason as barDark.
float retraceW = 0.0009;
float retraceSplit = 0.10;
float flagAmount = 0.0;    // 0.0005 -> 0.0 on 2026-07-28: horizontal flagging trails the bar; dead with it.
float flagTau = 0.030;
float syncTwitchXPx = 0.0;
float syncTwitchYPx = 0.0;
float wobbleAmount = 0.0;
float wobblePeak = 40.0;
float wobbleFreq = 0.11;
float reducedMotion = 0.0;

float softRadius = 0.18; // MacBook-only subpixel softening; nudges edges toward CRT aliasing.
float softAmount = 0.0; // 0.18 -> 0.0 on 2026-07-25. This was the ONLY thing making plain
                        // foreground softer than the 321urx preset. Off = pixel-exact text.

// NEON BLOOM -- saturation-gated, added 2026-07-22. This is NOT the discarded
// global blur: text is untouched. Only pixels that are both SATURATED and
// BRIGHT (the orange pills, cyan chips, neon syntax) emit a halo; neutral
// foreground fails the saturation gate and stays razor sharp, exactly the
// same neutral-vs-saturated split the paper-lift below already relies on.
// Set neonBloom to 0.0 to switch the whole effect off.
float neonBloom = 0.60;        // 0.40 -> 0.60 on 2026-07-28 (REVERT, same day): Jimmy vetoed the bloom cut
                               // in ALL CAPS -- the bloom itself is wanted; "nvim blurry" must be solved some
                               // other way or not at all. Do NOT lower this knob for sharpness complaints.
                               // 0.90 -> 0.60 on 2026-07-28 (REVERT): the 0.60 -> 0.90 bump below was justified
                               // by an NSScreen probe reading 1920x1200 @ scale 1.0. That probe was WRONG -- a
                               // compiled probe the same day read backing 3456. The glow looked weak because the
                               // MacBook was on HiDPI (mode detune), NOT because the LCD black floor swallowed it.
                               // 0.60 is the last value confirmed BY EYE at a real 1:1 1920x1200 backing.
                               // 0.60 -> 0.90 on 2026-07-28: MacBook-only complaint, backing MEASURED still
                               // 1920x1200 @ scale 1.0 (NSScreen) = NOT a mode detune, so radius 13 and the
                               // 7.0 fill knee stay correct and are deliberately untouched. This is the PANEL:
                               // the halo is additive and the LCD's lifted black floor swallows it where the
                               // 321URX OLED's true black does not. 1.20 was measured blown out on 07-27, so
                               // 0.90 is the last step below that. Shaders are global -- if the 321URX ever
                               // looks too hot, this line is why.
                               // 0.22 -> 0.60 on 2026-07-27, MEASURED on-screen at 1920x1200 non-HiDPI:
                               // 0.22 rendered a halo of a few /255 = invisible, 1.20 blew out. 0.60 bracketed
                               // between them and confirmed by eye. NOTE: 0.22 was never a known-good value for
                               // THIS mode -- it was tuned 07-23 for 2336x1510 and carried here by the partial
                               // revert below, which restored strength+radius but left the fill knee at 4.0.
                               // 0.45 -> 0.22 on 2026-07-27: display is BACK on 1920x1200, backingScale 1.0
                               // (measured via NSScreen: backing rect 1920x1200 px). The 07-26 bump below was
                               // correct FOR 3200x1800 and wrong here -- these constants are backing-px, so a
                               // mode change silently detunes them.
                               // 0.22 -> 0.45 on 2026-07-26: display went 1900x1200 -> 3200x1800 non-HiDPI. Larger backing spreads each glyph over ~1.7x more px, diluting per-tap energy; 0.22 measured ~1-4/255 halo = invisible. This was misdiagnosed as "bg_transparency kills glow" — it never did.        // halo strength (0 = off); 0.75 verified WAY too much.
                               // 0.45 -> 0.22 on 2026-07-23 for NON-HIDPI 2336x1510.
                               // Without the 2x backing store there is no downsample
                               // averaging any of this away, and every glyph is a much
                               // larger share of the pixels inside the halo radius, so
                               // neighbours pile onto each other. 0.45 blew out completely
                               // and even near-neutral text glowed.
                               // 0.30 -> 0.45 on 2026-07-23, tuned for the MacBook LCD:
                               // the halo is ADDITIVE, so the panel's lifted black floor
                               // swallows it. The 321URX OLED runs this SAME file over
                               // true black and therefore reads much glowier. That
                               // divergence is intentional and wanted -- do not "fix" it
                               // by splitting the presets again.
float neonBloomRadiusPx = 13.0; // 17 -> 13 on 2026-07-28: the 17 experiment made yaml-key halos
                               // spill onto neighbouring text ("white blooming"). 13 is the
                               // confirmed value for this backing; bigger reach = key-glow spill.
                               // halo reach in backing px. 22 -> 13 on 2026-07-27: back on 1920x1200 backing,
                               // so this returns to the 07-25 value tuned for exactly that mode. At 22 the six
                               // ring taps reach ~2 glyph widths out and mostly sample background.
                               // 13 -> 22 on 2026-07-26: 1900x1200 -> 3200x1800 backing (x1.68), same scaling model as the 07-23/07-25 changes below.
                               // 16 -> 13 on 2026-07-25 for NON-HIDPI 1900x1200. Same
                               // model as the 07-23 change: backing store shrank 2336 ->
                               // 1900 (x0.81) with no DPI change, so glyphs are ~1.23x
                               // fewer px across and a fixed backing-px radius reaches
                               // that much further per glyph. 16 x 0.81 ~= 13.
                               // 32 -> 16 on 2026-07-23 for
                               // NON-HIDPI 2336x1510. This is a DPI-mode change, not a
                               // resolution change: HiDPI 2056x1329 had a 4112px backing
                               // store, non-HiDPI 2336 has a 2336px one. Glyphs are ~1.76x
                               // fewer pixels across, so a radius in backing px reaches
                               // proportionally FURTHER per glyph. Halved, not scaled by
                               // the logical-resolution ratio (that was the wrong model).
                               // 20 -> 32 on 2026-07-23.
                               // Scaled by 1/iResolution, so on the MacBook's dense HiDPI
                               // backing store 20px was a far tighter halo per glyph than
                               // the same 20 on the monitor. This widens the laptop case.
// Sampling is a VOGEL SPIRAL (golden-angle disk), rotated per pixel by hash.
// The two failed geometries, for the record: sparse rings missed 2px pane
// borders entirely; a 7x7 grid at 8px spacing caught everything but stamped
// its own square lattice into strong halos -- visible "square pixels".
// A rotated spiral has no repeating structure: residual sampling error
// dissolves into fine static grain (which matches paperGrain's texture)
// instead of geometry.
// Gate ramp: glow fades in from satGateLo and is FULL by satGateHi. The first
// cut ran 0.40->0.85, which demanded near-total saturation and silently
// excluded the whole cool/pastel half of the palette (#59f1ff laser_cyan sat
// 0.65 at half glow, #9fefff ice_blue sat 0.38 at ZERO) while pure warm hues
// sailed through -- "only yellows and oranges glow". Neutral text sits below
// ~0.15 saturation, so 0.22 still excludes it cleanly.
// ---- 2026-07-25: SATURATION GATE DEMOTED, HUE EXCLUSION ADDED ----
// The comment above ("neutral text sits below ~0.15 saturation, so 0.22 still
// excludes it cleanly") was true for the OLD grey foreground #787c99, tsat 0.22.
// The foreground is now #00b012 -- a PURE green, tsat 1.0. It passes the old gate
// at FULL weight, so saturation can no longer tell foreground from syntax. The
// gate is therefore dropped to catch mid-saturation colours, and the foreground
// is protected by HUE distance instead (see fgHue* below). Old values, for a
// one-line revert if this is worse: Lo = 0.22, Hi = 0.55.
// 2026-07-25: these are the ORIGINAL values, restored. Two changes were tried
// and both are reverted -- the grey weights they produced were never requested:
//   - Lo 0.22 -> 0.10 to make mid-tones glow. This lit the muted blue-greys
//     (#444b6a 0.41 -> 0.96, #5e6381 0.17 -> 0.85). Regression.
//   - A brightness gate to force those greys to 0.0. That pushed them BELOW
//     their original weights, which is also a change nobody asked for.
// Reference saturations, measured from ~/.claude/themes/tokyo-night-terminal-dark.json:
//   #cbccd1 body text 0.029 (never glows) | #5e6381 0.271 | #444b6a 0.358
//   #7c68a5 warning   0.370 -- only 0.012 above #444b6a, so a saturation gate
//   CANNOT separate dim grey chrome from muted accents. Do not try again.
// DO NOT retune these to chase mid-tone glow. Grey bloom weights are load-bearing.
float neonBloomSatGateLo = 0.22;
float neonBloomSatGateHi = 0.55;
// Hue exclusion. Bloom is suppressed for taps whose hue sits within fgHueBand
// (in TURNS, 0..1 around the wheel) of the foreground, ramping back to full glow
// by fgHueBand + fgHueSoft. #00b012 is hue 0.352. A band of 0.055 turns is ~20
// degrees each way, which covers the foreground and its antialiased edge pixels
// without eating the rest of the palette. WARNING: any near-neighbour green in
// the theme lands in this band too and will NOT glow -- widen or narrow here.
// Set fgHueExclude = 0.0 to disable and get the pure saturation gate back.
float fgHueExclude = 1.0;
vec3  fgHueRef = vec3(0.0, 0.690, 0.071); // #00b012, must track `foreground` in config
float fgHueBand = 0.055;
float fgHueSoft = 0.045;
// Sampling is a dense 7x7 gaussian GRID, not a ring. Rings geometrically miss
// thin axis-aligned strokes (a 2px pane border catches ~2 of 24 ring taps and
// vanishes); a grid lands a full column of taps on it. The normalizer (the
// /12.0 below) is also deliberately SMALLER than the kernel's total gaussian
// weight (~25): full-area normalization averages a thin emitter against its
// dark surroundings and drowns it. Under-normalizing lets sparse emitters --
// borders, chip edges -- actually shine; the final clamp handles saturation.
// Saturated-dim boost: glow weight is saturation x LUMA, which leaves the dim
// halves of pane borders (#7a3200 -- fully saturated, low luminance, one cell
// thin) barely emitting. This lifts the weight of near-fully-saturated pixels
// toward full regardless of brightness, so dim chrome glows like warm neon at
// rest. Text never qualifies (fails the saturation gate); bright pixels gain
// almost nothing (the boost scales by the brightness they lack).
float neonDimBoost = 0.35;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// Hue in TURNS (0..1). Returns 0.0 for achromatic input; callers must gate on
// saturation separately, since hue is meaningless there.
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

// Shortest distance between two hues on the wheel, in turns (0..0.5).
float hueDist(float a, float b) {
    float d = abs(a - b);
    return min(d, 1.0 - d);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // squared distance from center
    vec2 uv = fragCoord / iResolution.xy;
    vec2 dc = abs(0.5 - uv);
    dc *= dc;
    
    // warp the fragment coordinates
    uv.x -= 0.5; uv.x *= 1.0 + (dc.y * (0.3 * warp)); uv.x += 0.5;
    uv.y -= 0.5; uv.y *= 1.0 + (dc.x * (0.4 * warp)); uv.y += 0.5;

    float motion = 1.0 - reducedMotion;
    float motionTime = iTime * motion;

    // Rolling VBI bar position. It travels once, exits, then leaves a clean gap.
    float cycle = 1.0 / barSpeed + barGap;
    float t = mod(motionTime, cycle);
    float prog = clamp(t * barSpeed, 0.0, 1.0);
    float span = 1.0 + barHeight;
    float barPos = (barDir < 0.0)
                 ? (1.0 + barHeight * 0.5) - prog * span
                 : (-barHeight * 0.5) + prog * span;
    float bd = uv.y - barPos;
    float barMask = exp(-bd * bd / (barHeight * barHeight * 0.25) * 2.0);

    // One-sided horizontal flagging immediately after the rolling bar.
    float after = bd;
    float s = after - barHeight * 0.5;
    float flag = exp(-max(s, 0.0) / flagTau)
               * clamp(after / (barHeight * 0.5), 0.0, 1.0);

    vec2 suv = uv;
    suv.x += motion * flagAmount * flag;

    // Rare sync twitch, with adjacent events guaranteed 14-40 seconds apart.
    // Events are centered 27s apart and independently jittered by +/-6.5s.
    const float twitchCell = 27.0;
    float twitchSlot = floor(motionTime / twitchCell);
    float twitchLocal = motionTime - twitchSlot * twitchCell;
    float jitterPrev = (hash(vec2(twitchSlot - 1.0, 73.1)) - 0.5) * 13.0;
    float jitterCurr = (hash(vec2(twitchSlot,       73.1)) - 0.5) * 13.0;
    float jitterNext = (hash(vec2(twitchSlot + 1.0, 73.1)) - 0.5) * 13.0;
    float dtPrev = twitchLocal - (-twitchCell * 0.5 + jitterPrev);
    float dtCurr = twitchLocal - ( twitchCell * 0.5 + jitterCurr);
    float dtNext = twitchLocal - ( twitchCell * 1.5 + jitterNext);
    float envPrev = exp(-pow(dtPrev / 0.10, 2.0));
    float envCurr = exp(-pow(dtCurr / 0.10, 2.0));
    float envNext = exp(-pow(dtNext / 0.10, 2.0));
    float signPrev = step(0.5, hash(vec2(twitchSlot - 1.0, 11.9))) * 2.0 - 1.0;
    float signCurr = step(0.5, hash(vec2(twitchSlot,       11.9))) * 2.0 - 1.0;
    float signNext = step(0.5, hash(vec2(twitchSlot + 1.0, 11.9))) * 2.0 - 1.0;
    vec2 dirPrev = normalize(vec2(signPrev, hash(vec2(twitchSlot - 1.0, 41.6)) * 2.0 - 1.0));
    vec2 dirCurr = normalize(vec2(signCurr, hash(vec2(twitchSlot,       41.6)) * 2.0 - 1.0));
    vec2 dirNext = normalize(vec2(signNext, hash(vec2(twitchSlot + 1.0, 41.6)) * 2.0 - 1.0));
    vec2 twitch = envPrev * dirPrev + envCurr * dirCurr + envNext * dirNext;
    suv += motion * twitch * vec2(syncTwitchXPx, syncTwitchYPx) / iResolution.xy;

    // Rare whole-screen horizontal wobble. All channels shift together: no color split.
    float wob = 1.0;
    const float wobPeriods[4] = float[4](6.0, 16.0, 19.0, 27.0);
    for (int i = 0; i < 4; i++) {
        wob *= 1.0 + 0.5 * sin(motionTime * wobPeriods[i] * wobbleFreq);
    }
    wob *= 27.0;
    wob = min(wob, wobblePeak);
    const float wobbleCell = 27.0;
    float wobbleSlot = floor(motionTime / wobbleCell);
    float wobbleLocal = motionTime - wobbleSlot * wobbleCell;
    float wobbleJitterPrev = (hash(vec2(wobbleSlot - 1.0, 37.7)) - 0.5) * 13.0;
    float wobbleJitterCurr = (hash(vec2(wobbleSlot,       37.7)) - 0.5) * 13.0;
    float wobbleJitterNext = (hash(vec2(wobbleSlot + 1.0, 37.7)) - 0.5) * 13.0;
    float wobbleDtPrev = wobbleLocal - (-wobbleCell * 0.5 + wobbleJitterPrev);
    float wobbleDtCurr = wobbleLocal - ( wobbleCell * 0.5 + wobbleJitterCurr);
    float wobbleDtNext = wobbleLocal - ( wobbleCell * 1.5 + wobbleJitterNext);
    float wobbleEnvPrev = exp(-pow(wobbleDtPrev / 0.70, 2.0));
    float wobbleEnvCurr = exp(-pow(wobbleDtCurr / 0.70, 2.0));
    float wobbleEnvNext = exp(-pow(wobbleDtNext / 0.70, 2.0));
    float wobbleSignPrev = step(0.5, hash(vec2(wobbleSlot - 1.0, 91.3))) * 2.0 - 1.0;
    float wobbleSignCurr = step(0.5, hash(vec2(wobbleSlot,       91.3))) * 2.0 - 1.0;
    float wobbleSignNext = step(0.5, hash(vec2(wobbleSlot + 1.0, 91.3))) * 2.0 - 1.0;
    float wobbleGate = wobbleEnvPrev * wobbleSignPrev
                     + wobbleEnvCurr * wobbleSignCurr
                     + wobbleEnvNext * wobbleSignNext;
    float wobOff = motion * wobbleAmount * wob * wobbleGate / iResolution.x;

    // MacBook HiDPI can look too analytically sharp; soften at the final sample
    // coordinate before CRT texture so text keeps a little terminal-era aliasing.
    vec2 sampleUv = vec2(suv.x + wobOff, suv.y);
    vec2 px = 1.0 / iResolution.xy;
    float d = softRadius * 0.7071068;
    vec3 src = texture(iChannel0, sampleUv).rgb;
    // GUARDED 2026-07-28: these 8 taps ran unconditionally and were then mixed at
    // softAmount, which has been 0.0 since 07-25 -- 8 texture fetches per pixel per
    // frame, every one of them discarded. mix(src, soft, 0.0) IS src, so this guard
    // is a provable visual no-op; it only stops paying for a result nobody uses.
    // If softAmount ever goes non-zero again the original path runs exactly as before.
    vec3 color = src;
    if (softAmount > 0.0) {
        vec3 soft = src * 1.5;
        soft += texture(iChannel0, sampleUv + vec2(0.0,  softRadius) * px).rgb;
        soft += texture(iChannel0, sampleUv + vec2(0.0, -softRadius) * px).rgb;
        soft += texture(iChannel0, sampleUv + vec2( softRadius, 0.0) * px).rgb * 0.5;
        soft += texture(iChannel0, sampleUv + vec2(-softRadius, 0.0) * px).rgb * 0.5;
        soft += texture(iChannel0, sampleUv + vec2( d,  d) * px).rgb * 0.35;
        soft += texture(iChannel0, sampleUv + vec2(-d,  d) * px).rgb * 0.35;
        soft += texture(iChannel0, sampleUv + vec2( d, -d) * px).rgb * 0.35;
        soft += texture(iChannel0, sampleUv + vec2(-d, -d) * px).rgb * 0.35;
        soft /= 5.9;
        color = mix(src, soft, softAmount);
    }

    // Neon bloom: two interleaved 6-tap rings. Each tap contributes only by
    // its OWN saturation x luminance, so glow spreads outward from lit neon
    // into dark surroundings and never lifts neutral text or background.
    if (neonBloom > 0.0) {
        vec3 neon = vec3(0.0);
        float wsum = 0.0;
        float spin = hash(fragCoord.xy) * 6.2831853;
        float fgHue = hue01(fgHueRef); // loop-invariant, hoisted out of the tap loop
        // ---- 2026-07-28 THERMALS: gate-in-alpha + early-exit probe ----
        // neon_gate.glsl (must run FIRST in the chain) precomputes the full
        // emission gate ONCE per pixel and stores it as alpha = w * 0.5
        // (max ~0.95). Taps below read that instead of re-running HSV + hue
        // math 24x per pixel. alpha > 0.99 means the gate pass is MISSING
        // (raw terminal alpha is 1.0 with background-opacity = 1) -- e.g. it
        // failed to compile -- and the tap falls back to the old inline gate,
        // so the worst failure mode is exactly the pre-07-28 behaviour.
        //
        // PROBE: 9 fixed alpha reads across the disk. If none carry any
        // emission, no halo can land here and the 24-tap loop is skipped --
        // which is most of the screen (dark background far from any neon).
        // Taps are deterministic (no spin) so the skip boundary is stable,
        // not flickery. A probe this sparse CAN miss a thin emitter near the
        // disk's outer edge and clip the faintest fringe of its halo; if a
        // border halo ever looks truncated, set probeEnable = 0.0 (full
        // gather everywhere, still keeps the gate-in-alpha ALU win).
        float probeEnable = 1.0;
        bool skipBloom = false;
        if (probeEnable > 0.0) {
            float pr = neonBloomRadiusPx;
            float pa = texture(iChannel0, sampleUv).a;
            pa = max(pa, texture(iChannel0, sampleUv + vec2( 0.55, 0.0) * pr * px).a);
            pa = max(pa, texture(iChannel0, sampleUv + vec2(-0.55, 0.0) * pr * px).a);
            pa = max(pa, texture(iChannel0, sampleUv + vec2(0.0,  0.55) * pr * px).a);
            pa = max(pa, texture(iChannel0, sampleUv + vec2(0.0, -0.55) * pr * px).a);
            pa = max(pa, texture(iChannel0, sampleUv + vec2( 0.65,  0.65) * pr * px).a);
            pa = max(pa, texture(iChannel0, sampleUv + vec2(-0.65,  0.65) * pr * px).a);
            pa = max(pa, texture(iChannel0, sampleUv + vec2( 0.65, -0.65) * pr * px).a);
            pa = max(pa, texture(iChannel0, sampleUv + vec2(-0.65, -0.65) * pr * px).a);
            skipBloom = pa < 0.002; // below the smallest storable weight (0.5/255)
        }
        // 24 -> 96 taps on 2026-07-27 to kill halo speckle. The per-pixel random
        // `spin` above means neighbouring pixels sample disjoint point sets; with
        // only 24 samples over a ~530px^2 disk they disagreed badly and that
        // disagreement WAS the grain. Noise falls as 1/sqrt(N), so 4x taps = 2x
        // cleaner. tapNorm rescales BOTH accumulators back to their 24-tap
        // magnitudes, so neonBloom, the fill knee (7.0) and the /6.0 divisor below
        // all keep their existing calibration -- this changes noise ONLY, not look.
        // If this ever costs too much fill rate, drop TAPS and everything still
        // holds; do NOT remove tapNorm.
        // 96 -> 48 on 2026-07-28 for THERMALS. The 07-27 bump to 96 was the single
        // biggest fill-rate change this shader has ever taken (4x the cost of the
        // most expensive block) and it landed the day the MacBook started running
        // hot. This is the escape hatch the comment below already sanctions.
        // Noise goes as 1/sqrt(N), so 48 sits halfway between the old 24 and 96:
        // ~1.4x cleaner than the speckle that prompted the bump, at half the cost.
        // tapNorm keeps neonBloom / the 7.0 knee / the /6.0 divisor calibrated.
        const int TAPS = 48; // 96 -> 48 on 2026-07-28: Jimmy traded tap density for halo REACH
                             // (radius 13 -> 17 above) at similar cost. 96 was approved by eye
                             // but redundant once the halo got bigger; 48 stays speckle-clean
                             // thanks to gate-in-alpha + the probe early-exit.
        float tapNorm = 24.0 / float(TAPS);
        if (!skipBloom) for (int i = 0; i < TAPS; i++) {
            float fi = float(i) + 0.5;
            float rr = sqrt(fi / float(TAPS));
            float a = fi * 2.39996323 + spin;
            vec2 off = vec2(cos(a), sin(a)) * rr * neonBloomRadiusPx * px;
            float g = exp(-3.0 * rr * rr);
            vec4 tap4 = texture(iChannel0, sampleUv + off);
            vec3 tapc = tap4.rgb;
            float w;
            if (tap4.a <= 0.99) {
                // Gate precomputed by neon_gate.glsl: decode alpha = w * 0.5.
                w = tap4.a * 2.0;
            } else {
                // Gate pass missing (alpha is raw 1.0): inline fallback, the
                // exact pre-07-28 per-tap gate. Kept verbatim -- if this path
                // is hot, neon_gate.glsl is broken; fix THAT, don't tune here.
                // Emission strength = PEAK CHANNEL, not luma. Luma weights
                // (R .30 / G .59 / B .11) rate a pure blue emitter ~9x weaker
                // than an equally driven yellow -- right for text legibility,
                // wrong for "how hard is this neon tube driven". Peak channel
                // treats every hue as an equal citizen; blue halos still read
                // dimmer to the eye, but that is physics, not a gate.
                float tmax = max(tapc.r, max(tapc.g, tapc.b));
                float tmin = min(tapc.r, min(tapc.g, tapc.b));
                float tsat = (tmax - tmin) / max(tmax, 0.0001);
                float lift = neonDimBoost * (1.0 - tmax) * smoothstep(0.60, 0.90, tsat);
                w = smoothstep(neonBloomSatGateLo, neonBloomSatGateHi, tsat)
                        * min(tmax + lift, 1.0);
                // Foreground hue exclusion. The saturation gate above can no longer
                // exclude the foreground (#00b012 is fully saturated), so kill glow
                // for taps sitting at the foreground's hue instead. Applied AFTER
                // the saturation gate so it only ever subtracts.
                if (fgHueExclude > 0.0) {
                    float hd = hueDist(hue01(tapc), fgHue);
                    w *= smoothstep(fgHueBand, fgHueBand + fgHueSoft, hd);
                }
                // Blue compensation: the eye sees blue light at a fraction of
                // the brightness of equally driven warm hues, so blue halos
                // vanished ("no glow" on the k8s-blue session chip) while gold
                // and turquoise radiated. Boost blue-DOMINANT emitters toward
                // perceptual parity; warm and balanced hues are untouched.
                float blueBias = clamp(tapc.b - max(tapc.r, tapc.g), 0.0, 1.0);
                w *= 1.0 + 0.9 * blueBias;
            }
            neon += tapc * w * g;
            wsum += w * g;
        }
        // Rescale to 24-tap magnitudes so all downstream constants are unchanged.
        neon *= tapNorm;
        wsum *= tapNorm;
        // Occupancy mask: a pixel SURROUNDED by glowing material (knockout
        // text inside a lit chip -- the word "sample" on a swatch) would
        // receive halo light from every direction and fill in, destroying
        // legibility. The more lit the neighborhood, the less glow a pixel
        // may receive: halos land on dark background OUTSIDE a slab, never
        // inside its letterforms. Max possible wsum with this kernel is ~7.6
        // (24 taps x mean gaussian 0.32), so the knee sits at "mostly lit".
        //
        // 7.0 -> 4.0 on 2026-07-26. This knee doubles as the only "big panel
        // vs text" discriminator available to a post-process shader: it sees
        // pixels, not tmux geometry. A glyph stroke sits in mostly-dark space
        // (low wsum) and keeps full glow; a FILLED SLAB -- the clock pill, the
        // DEVOPS chip, the session chips -- is surrounded by lit pixels (high
        // wsum) and now falls off much faster. Text is untouched by design.
        // Thin tmux PANE BORDERS are not helped by this and cannot be: they
        // are geometrically identical to glyphs. Desaturate them in tmux.conf
        // if they need to come down.
        //
        // 4.0 -> 7.0 on 2026-07-27: the 07-26 tightening belonged to the
        // 3200x1800 state and was tuned against neonBloom 0.45 / radius 22.
        // Those two were reverted to 0.22 / 13 for 1920x1200 but this knee was
        // missed, leaving an aggressive knockout stacked on a weak halo = no
        // visible glow. Keep all THREE in sync on any display-mode change.
        float fill = 1.0 - clamp(wsum / 7.0, 0.0, 1.0);
        color += neon * (neonBloom / 6.0) * fill;
    }

    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    float maxChannel = max(color.r, max(color.g, color.b));
    float minChannel = min(color.r, min(color.g, color.b));
    float saturation = (maxChannel - minChannel) / max(maxChannel, 0.0001);

    // Paper-line lift for neutral foreground only. This avoids global wash and leaves
    // saturated syntax colors in the selected theme's own palette.
    // Paper presets:
    //   warm paper  vec3(0.86, 0.85, 0.79)  #dbd9c9
    //   e-ink warm  vec3(0.85, 0.85, 0.81)  #d9d9cf  active
    //   cool paper  vec3(0.81, 0.84, 0.90)  #cfd6e6
    //   moon paper  vec3(0.84, 0.83, 0.78)  #d6d4c7
    vec3 paper = vec3(0.85, 0.85, 0.81);
    float neutral = 1.0 - smoothstep(0.10, 0.36, saturation);
    float foreground = smoothstep(0.18, 0.62, luma);
    float paperMask = neutral * foreground;
    color = mix(color, paper * max(luma, 0.28), paperLift * paperMask);
    // 0.25 -> 0.5 on 2026-07-25: 0.25 was a HiDPI-era value (4px cells at 1:1). Both
    // displays are now non-HiDPI, so 0.5 gives 2px cells, matching the 321urx preset.
    color *= 1.0 + (hash(floor(fragCoord.xy * 0.5)) - 0.5) * paperGrain * paperMask;

    // Darken bright pixels more than the background, so the image keeps contrast.
    luma = dot(color, vec3(0.299, 0.587, 0.114));
    float lit = smoothstep(0.08, 0.75, luma);
    float phase = fract(fragCoord.y * 0.5); // 0.25 -> 0.5 on 2026-07-25, non-HiDPI. Dormant
                                            // while scan = 0.0, but correct if re-enabled.
    float dist = abs(phase - 0.5) * 2.0;
    float darkBand = smoothstep(0.58, 1.0, dist);
    float beam = 1.0 - smoothstep(0.0, 0.30, dist);
    float apply = darkBand * scan * mix(0.055, 0.20, lit);

    color = mix(color, vec3(0.0), apply);
    color *= 1.0 + beam * mix(0.012, 0.040, lit);

    // Very faint triad texture. It is neutral in average, so theme hues stay intact.
    float triad = mod(floor(fragCoord.x * 0.5), 3.0);
    vec3 mask = triad < 1.0 ? vec3(1.020, 0.992, 0.992)
              : triad < 2.0 ? vec3(0.992, 1.018, 0.992)
                             : vec3(0.992, 0.992, 1.020);
    color *= mix(vec3(1.0), mask, 0.0 * lit); // Grille off — 2026-07-25.

    // Rolling blanking bar and faint blue-slate retrace raster, after scanlines.
    color *= 1.0 - barDark * barMask;
    float p = (bd + barHeight * 0.5) / barHeight;
    float q = p * retraceN - uv.x;
    float dq = q - floor(q + 0.5);
    float dy = dq * barHeight / retraceN;
    float lines = exp(-dy * dy / (retraceW * retraceW));
    float splitQ = q + 0.34;
    float splitDQ = splitQ - floor(splitQ + 0.5);
    float splitDY = splitDQ * barHeight / retraceN;
    float splitLines = exp(-splitDY * splitDY / (retraceW * retraceW));
    float splitEvent = step(0.78, hash(vec2(floor(motionTime / cycle), 91.3)));
    vec3 retraceColor = vec3(0.52, 0.66, 0.72);
    color += retraceColor * retraceBright * lines * barMask;
    color += retraceColor * retraceBright * retraceSplit
           * splitLines * barMask * splitEvent * motion;

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
