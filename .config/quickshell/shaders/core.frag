#version 440
layout(location = 0) in float vCol;
layout(location = 1) in vec2 vLocal;
layout(location = 2) in float vRatio;
layout(location = 3) in vec4 vColor;
layout(location = 0) out vec4 fragColor;
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

void main() {
    if (fract(vCol * 0.5) > 0.499) discard;          // a bridge cell, not a particle
    // a flat square pixel (like the desktop's other graphics), stretched into a
    // straight bar along its motion; only the trailing end fades
    float tail = vRatio > 1.0 ? smoothstep(-1.0, 0.2, vLocal.x) : 1.0;
    fragColor = vColor * mix(0.35, 1.0, tail) * qt_Opacity;
}
