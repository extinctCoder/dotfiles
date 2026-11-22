#version 440
// The living core's particles, all placed on the GPU.
// Mesh: one row of (2*slots - 1) cells. Even cells are particles; odd cells are
// "bridges" between neighbours that core.frag discards (shared vertices).
// Slots: 0-319 body (4 subsystem bands x 80), 320-389 heart, 390-449 specks.
layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;
layout(location = 0) out float vCol;
layout(location = 1) out vec2 vLocal;
layout(location = 2) out float vRatio;
layout(location = 3) out vec4 vColor;
// Shared by core.vert and core.frag: one uniform block for both stages.
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;      // seconds, advances only while the core runs
    float slots;     // particle slots in the mesh (450)
    float unit;      // pixels per design unit (the core is designed on a 560 unit square)
    vec2 center;     // pixels
    vec4 axC;        // band axis xyz, w = load: compute
    vec4 axM;        // memory
    vec4 axS;        // storage
    vec4 axN;        // network
    vec4 chaos;      // per band, 0..1
    vec4 phase;      // accumulated orbit phase per band
    vec4 rate;       // orbit speed per band (rad/s), for motion streaks
    vec4 waveR;      // radii of up to 4 heartbeat waves
    vec4 waveA;      // their strength
    vec4 life;       // x heart strength, y lock (1 = collapsed), z fever, w beat glow
    vec4 flow;       // x download, y upload, z charging, w food in the heart
    vec4 misc;       // x heart radius, y inner radius, z skin radius, w heart phase
    vec4 colC;
    vec4 colM;
    vec4 colS;
    vec4 colN;
    vec4 colHeart;
    vec4 colIn;
    vec4 colFood;
};

float hash(float n) { return fract(sin(n) * 43758.5453123); }
vec4 pick(float g, vec4 a, vec4 b, vec4 c, vec4 d) { return g < 0.5 ? a : g < 1.5 ? b : g < 2.5 ? c : d; }
float comp(float g, vec4 v) { return g < 0.5 ? v.x : g < 1.5 ? v.y : g < 2.5 ? v.z : v.w; }

void main() {
    float cols = slots * 2.0 - 1.0;
    float c = floor(qt_MultiTexCoord0.x * cols + 0.5);
    float row = floor(qt_MultiTexCoord0.y + 0.5);
    float k = floor(c / 2.0);
    vec2 corner = vec2(mod(c, 2.0) * 2.0 - 1.0, row * 2.0 - 1.0);
    vCol = c;
    vLocal = corner;

    float strength = life.x;
    float bright = 0.3 + 0.7 * min(1.0, strength);
    float looseness = 1.0 + (1.0 - min(1.0, strength)) * 0.5;
    float rIn = misc.y;
    vec2 pos = center;
    vec2 dir = vec2(1.0, 0.0);
    float size = 0.0;      // radius in pixels
    float streak = 0.0;    // extra half-length in pixels
    float alpha = 0.0;
    vec3 col = vec3(1.0);

    if (k < 320.0) {
        // ---- body: a subsystem band ----
        float g = floor(k / 80.0);
        float i = k - g * 80.0;
        vec4 ax = pick(g, axC, axM, axS, axN);
        float load = ax.w;
        if (i < floor(min(1.0, load * 1.15 + 0.05) * 80.0 + 0.5)) {
            float C = comp(g, chaos);
            float w1 = hash(k * 1.7 + 11.0) * 6.0, w2 = hash(k * 2.9 + 13.0) * 6.0;
            float spd = 0.7 + hash(k * 3.3 + 17.0) * 0.6;
            float ph = hash(k * 4.1 + 19.0) * 6.2831853 + comp(g, phase) * spd;
            vec3 n0 = (vec3(hash(k * 5.3 + 23.0), hash(k * 6.7 + 29.0), hash(k * 7.9 + 31.0)) - 0.5) * 0.35;
            vec3 wob = vec3(sin(time * 0.9 + w1), cos(time * 1.1 + w2), sin(time * 0.7 + w1 + w2)) * C * 0.9;
            float jit = max(0.0, life.z - 0.5) * 0.6;
            float tick = floor(time * 15.0);
            wob += (vec3(hash(k + tick * 0.37), hash(k * 1.3 + tick * 0.53), hash(k * 1.9 + tick * 0.71)) - 0.5) * jit;
            vec3 nn = normalize(ax.xyz + n0 * (1.0 + C * 3.0) + wob);
            vec3 u = normalize(cross(nn, abs(nn.x) < 0.9 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0)));
            vec3 w = cross(nn, u);
            float rOut = rIn + 40.0 + load * 75.0;
            float f = hash(k * 8.3 + 37.0);
            float rad = (rIn + 12.0 + pow(f, 0.8) * (rOut - rIn - 12.0)) * looseness * (1.0 + C * 0.35 * sin(ph * 2.0 + w2));
            // strain: now and then a particle is flung out, then pulled back
            float kickSeed = hash(k * 9.1 + floor(time * 2.0) * 0.731);
            rad *= 1.0 + (kickSeed < C * C * 0.05 ? (1.0 - fract(time * 2.0)) * 0.9 : 0.0);
            // heartbeat waves push and light particles as they pass
            float glow = 0.0;
            for (int j = 0; j < 4; j++) {
                float d = abs(rad - waveR[j]);
                if (d < 14.0) { float push = (1.0 - d / 14.0) * waveA[j]; rad += push * 6.0; glow = max(glow, push); }
            }
            rad *= 1.0 - life.y * 0.85;
            vec3 p3 = (u * cos(ph) + w * sin(ph)) * rad;
            float persp = 1.0 + p3.z / 600.0;
            pos = center + p3.xy * persp * unit;
            float depth = (p3.z / max(rad, 1.0) + 1.0) * 0.5;
            size = (0.8 + depth * 2.0 + hash(k * 10.7 + 41.0) * 0.5 + glow) * 0.65 * unit;
            alpha = min(1.0, (0.2 + 0.7 * depth) * bright + glow * 0.5);
            col = pick(g, colC, colM, colS, colN).rgb;
            vec3 tang = -u * sin(ph) + w * cos(ph);
            if (length(tang.xy) > 0.001) dir = normalize(tang.xy);
            streak = clamp(rad * comp(g, rate) * spd * 0.012, 0.0, 3.5) * unit;
        }
    } else if (k < 390.0) {
        // ---- heart: a dense knot of the same particles ----
        float j = k - 320.0;
        vec3 v = normalize(vec3(hash(j * 3.1 + 400.0), hash(j * 5.7 + 401.0), hash(j * 9.3 + 402.0)) - 0.5);
        float rr = sqrt(hash(j * 1.9 + 403.0));
        float nph = hash(j * 2.3 + 404.0) * 6.2831853 + misc.w;
        pos = center + (v.xy * misc.x * rr * (1.0 + 0.15 * sin(nph)) + vec2(sin(nph), cos(nph)) * 1.2) * unit;
        size = 1.0 * unit;
        alpha = min(1.0, (0.45 + 0.55 * life.w) * bright + flow.w * 0.3);
        col = colHeart.rgb;
    } else {
        // ---- specks: data eaten (in), data exhaled (out), food (charging, into the heart) ----
        float j = k - 390.0;
        float kind = j < 20.0 ? 0.0 : (j < 40.0 ? 1.0 : 2.0);
        float amount = kind < 0.5 ? flow.x : (kind < 1.5 ? flow.y : flow.z * 0.6);
        if (hash(j * 4.1 + 500.0) < amount) {
            float a = hash(j * 6.1 + 501.0) * 6.2831853;
            float s = fract(time * (0.25 + amount * 0.4) * (0.7 + hash(j * 7.7 + 503.0) * 0.6) + hash(j * 8.3 + 502.0));
            float skin = misc.z;
            float r;
            if (kind < 0.5) { r = mix(skin + 70.0, 25.0, s); alpha = 0.85 * (1.0 - smoothstep(0.8, 1.0, s)); col = colIn.rgb; }
            else if (kind < 1.5) { r = mix(35.0, skin + 60.0, s); alpha = 0.85 * (1.0 - smoothstep(0.7, 1.0, s)); col = colIn.rgb; }
            else { r = mix(skin + 70.0, 3.0, s); alpha = 0.85 * (1.0 - smoothstep(0.9, 1.0, s)); col = colFood.rgb; }
            alpha *= smoothstep(0.0, 0.08, s);
            a += time * 0.25 * (kind < 1.5 ? 1.0 : -1.0) * 0.1;
            pos = center + vec2(cos(a), sin(a)) * r * unit;
            size = 1.2 * unit;
        }
    }

    vec2 perp = vec2(-dir.y, dir.x);
    float half_len = size + streak;
    vRatio = size > 0.0 ? half_len / size : 1.0;
    vColor = vec4(col * alpha, alpha);
    vec2 p = alpha > 0.0 ? pos + dir * corner.x * half_len + perp * corner.y * size : pos;
    gl_Position = qt_Matrix * vec4(p, 0.0, 1.0);
}
