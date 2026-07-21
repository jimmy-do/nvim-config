// 321urx-monitor-preset-theme-friendly-sharp.glsl
// Baseline captured 2026-07-18 from clean/bettercrt.glsl.
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
float scan = 0.0; // Temporarily disabled for a clean-text comparison.
float paperLift = 0.14; // neutral foreground lift; saturated syntax is gated out
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

// float softRadius = 0.025; // quarter of amber-phosphor-321urx.glsl
// float softAmount = 0.125; // quarter of amber-phosphor-321urx.glsl

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

    // Ported amber micro-softening disabled.
    // vec2 px = 1.0 / iResolution.xy;
    // float d = softRadius * 0.7071068;
    // vec3 src = texture(iChannel0, uv).rgb;
    // vec3 soft = src * 1.5;
    // soft += texture(iChannel0, uv + vec2(0.0,  softRadius) * px).rgb;
    // soft += texture(iChannel0, uv + vec2(0.0, -softRadius) * px).rgb;
    // soft += texture(iChannel0, uv + vec2(0.0,  d) * px).rgb * 0.5;
    // soft += texture(iChannel0, uv + vec2(0.0, -d) * px).rgb * 0.5;
    // soft /= 4.5;
    // vec3 color = mix(src, soft, softAmount);
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

    vec3 color = texture(iChannel0, vec2(suv.x + wobOff, suv.y)).rgb;

    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    float maxChannel = max(color.r, max(color.g, color.b));
    float minChannel = min(color.r, min(color.g, color.b));
    float saturation = (maxChannel - minChannel) / max(maxChannel, 0.0001);

    // Paper-line lift for neutral foreground only. This avoids global wash and leaves
    // saturated syntax colors in the selected theme's own palette.
    // Paper presets:
    //   e-ink bright vec3(0.96, 0.96, 0.92) #f5f5eb  active
    //   e-ink lite  vec3(0.92, 0.92, 0.88)  #ebebe0
    //   book page   vec3(0.94, 0.92, 0.85)  #f0ebd9
    //   warm paper  vec3(0.86, 0.85, 0.79)  #dbd9c9
    //   e-ink warm  vec3(0.85, 0.85, 0.81)  #d9d9cf
    //   cool paper  vec3(0.81, 0.84, 0.90)  #cfd6e6
    //   moon paper  vec3(0.84, 0.83, 0.78)  #d6d4c7
    vec3 paper = vec3(0.92, 0.92, 0.88);
    float neutral = 1.0 - smoothstep(0.10, 0.36, saturation);
    float foreground = smoothstep(0.18, 0.62, luma);
    float paperMask = neutral * foreground;
    // Floor raised 0.28 -> 0.45: dim neutral greys were clamped to a dark target and
    // never lifted, while bright text tracked `paper` and blew out.
    color = mix(color, paper * max(luma, 0.45), paperLift * paperMask);
    color *= 1.0 + (hash(floor(fragCoord.xy * 0.5)) - 0.5) * paperGrain * paperMask;

    // Darken bright pixels more than the background, so the image keeps contrast.
    luma = dot(color, vec3(0.299, 0.587, 0.114));
    float lit = smoothstep(0.08, 0.75, luma);
    float phase = fract(fragCoord.y * 0.5);
    float dist = abs(phase - 0.5) * 2.0;
    float darkBand = smoothstep(0.58, 1.0, dist);
    float beam = 1.0 - smoothstep(0.0, 0.30, dist);
    float apply = darkBand * scan * mix(0.055, 0.20, lit);

    color = mix(color, vec3(0.0), apply);
    color *= 1.0 + beam * mix(0.012, 0.040, lit);

    // Very faint triad texture. It is neutral in average, so theme hues stay intact.
    // 2px pitch, not 1px: the panel is driven at 3200x1800 into a 3840x2160 native
    // grid, so a 1px stripe cycle beats against the 1.2x upscale and moires.
    float triad = mod(floor(fragCoord.x * 0.5), 3.0);
    vec3 mask = triad < 1.0 ? vec3(1.020, 0.992, 0.992)
              : triad < 2.0 ? vec3(0.992, 1.018, 0.992)
                             : vec3(0.992, 0.992, 1.020);
    color *= mix(vec3(1.0), mask, 0.0 * lit); // Grille off.

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
