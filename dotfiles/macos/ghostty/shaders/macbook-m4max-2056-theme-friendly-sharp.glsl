// macbook-m4max-2056-theme-friendly-sharp.glsl
// Ported 2026-07-18 from 321urx-monitor-preset-theme-friendly-sharp.glsl.
// Tuned for MacBook Pro M4 Max @ 2056x1329 logical, 4112x2658 HiDPI backing.
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
float paperLift = 0.10; // neutral foreground lift; saturated syntax is gated out
float paperGrain = 0.016; // stable foreground-only paper tooth; background stays clean

// Motion ports from amber-phosphor-321urx.glsl, kept color-neutral.
float barDir = 1.0;
float barGap = 6.0;
float barSpeed = 0.09;
float barHeight = 0.10;
float barDark = 0.055;
float retraceN = 21.0;
float retraceBright = 0.045;
float retraceW = 0.0009;
float retraceSplit = 0.10;
float flagAmount = 0.0005;
float flagTau = 0.030;
float syncTwitchXPx = 0.0;
float syncTwitchYPx = 0.0;
float wobbleAmount = 0.0;
float wobblePeak = 40.0;
float wobbleFreq = 0.11;
float reducedMotion = 0.0;

float softRadius = 0.18; // MacBook-only subpixel softening; nudges edges toward CRT aliasing.
float softAmount = 0.18;

// NEON BLOOM -- saturation-gated, added 2026-07-22. This is NOT the discarded
// global blur: text is untouched. Only pixels that are both SATURATED and
// BRIGHT (the orange pills, cyan chips, neon syntax) emit a halo; neutral
// foreground fails the saturation gate and stays razor sharp, exactly the
// same neutral-vs-saturated split the paper-lift below already relies on.
// Set neonBloom to 0.0 to switch the whole effect off.
float neonBloom = 0.30;        // halo strength (0 = off); 0.75 verified WAY too much
float neonBloomRadiusPx = 20.0; // halo reach in backing px
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
float neonBloomSatGateLo = 0.22;
float neonBloomSatGateHi = 0.55;
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
    vec3 color = mix(src, soft, softAmount);

    // Neon bloom: two interleaved 6-tap rings. Each tap contributes only by
    // its OWN saturation x luminance, so glow spreads outward from lit neon
    // into dark surroundings and never lifts neutral text or background.
    if (neonBloom > 0.0) {
        vec3 neon = vec3(0.0);
        float wsum = 0.0;
        float spin = hash(fragCoord.xy) * 6.2831853;
        for (int i = 0; i < 24; i++) {
            float fi = float(i) + 0.5;
            float rr = sqrt(fi / 24.0);
            float a = fi * 2.39996323 + spin;
            vec2 off = vec2(cos(a), sin(a)) * rr * neonBloomRadiusPx * px;
            float g = exp(-3.0 * rr * rr);
            vec3 tapc = texture(iChannel0, sampleUv + off).rgb;
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
            float w = smoothstep(neonBloomSatGateLo, neonBloomSatGateHi, tsat)
                    * min(tmax + lift, 1.0);
            neon += tapc * w * g;
            wsum += w * g;
        }
        // Occupancy mask: a pixel SURROUNDED by glowing material (knockout
        // text inside a lit chip -- the word "sample" on a swatch) would
        // receive halo light from every direction and fill in, destroying
        // legibility. The more lit the neighborhood, the less glow a pixel
        // may receive: halos land on dark background OUTSIDE a slab, never
        // inside its letterforms. Max possible wsum with this kernel is ~7.6
        // (24 taps x mean gaussian 0.32), so the knee sits at "mostly lit".
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
    color *= 1.0 + (hash(floor(fragCoord.xy * 0.25)) - 0.5) * paperGrain * paperMask;

    // Darken bright pixels more than the background, so the image keeps contrast.
    luma = dot(color, vec3(0.299, 0.587, 0.114));
    float lit = smoothstep(0.08, 0.75, luma);
    float phase = fract(fragCoord.y * 0.25);
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
    color *= mix(vec3(1.0), mask, 0.18 * lit);

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
