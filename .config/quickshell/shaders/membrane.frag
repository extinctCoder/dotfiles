#version 440
// The living core's skin: wraps the body (each band's projected extent, using
// how far it reached recently, so it relaxes slowly: memory), ripples with
// heartbeat waves, dents where it is touched, trembles when something is wrong.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float unit;      // pixels per design unit
    vec2 size;       // item size in pixels
    vec4 axC;        // band axis xyz, w = remembered reach (design units, 0 = absent)
    vec4 axM;
    vec4 axS;
    vec4 axN;
    vec4 waveR;
    vec4 waveA;
    vec4 skin;       // x minimum radius, y brightness, z tremble, w fever
    vec4 touch;      // x amount, y width, z angle
    vec4 colSkin;
    vec4 colLine2;   // the theme's border color
    vec4 audio;      // x mids, y highs (live music), z heartbeat contraction
    vec4 pores;      // x download, y upload, z the specks' skin radius
};
float hash(float n) { return fract(sin(n) * 43758.5453123); }
float reach(vec4 ax, vec2 d) {
    if (ax.w <= 0.0) return 0.0;
    float nd = dot(ax.xyz, vec3(d, 0.0));
    return ax.w * sqrt(max(0.0, 1.0 - nd * nd));   // a tilted circle's outline in direction d
}
void main() {
    vec2 p = (qt_TexCoord0 * size - size * 0.5) / unit;
    float r = length(p);
    float th = atan(p.y, p.x);
    vec2 d = vec2(cos(th), sin(th));
    float e1 = reach(axC, d), e2 = reach(axM, d), e3 = reach(axS, d), e4 = reach(axN, d);
    float R = pow(pow(e1, 8.0) + pow(e2, 8.0) + pow(e3, 8.0) + pow(e4, 8.0) + pow(skin.x, 8.0), 0.125) + 16.0;
    for (int j = 0; j < 4; j++) {
        float dd = abs(R - waveR[j]);
        R += max(0.0, 1.0 - dd / 22.0) * waveA[j] * 9.0;
    }
    float da = atan(sin(th - touch.z), cos(th - touch.z));
    R -= touch.x * 26.0 * exp(-(da * da) / (2.0 * touch.y * touch.y));
    R += skin.z * (sin(th * 13.0 + time * 25.0) + sin(th * 7.0 - time * 31.0));
    // music: mids swell the skin in slow moving lobes, highs shimmer along it
    R += audio.x * 12.0 * (0.6 + 0.4 * sin(th * 3.0 + time * 1.7));
    R += audio.y * 2.5 * sin(th * 29.0 + time * 13.0) * (0.5 + 0.5 * sin(th * 4.0 - time * 2.3)); // in travelling patches, not evenly
    // heartbeat: the skin contracts with the body
    R *= 1.0 - audio.z * 0.08;
    // pores: the line lights up where a speck crosses it. Same paths as the specks
    // in core.vert (same seeds and formulas), so each flash is a real crossing.
    float pore = 0.0;
    for (int i = 0; i < 40; i++) {
        float j = float(i);
        float kind = j < 20.0 ? 0.0 : 1.0;
        float amount = kind < 0.5 ? pores.x : pores.y;
        if (hash(j * 4.1 + 500.0) >= amount) continue;
        float a = hash(j * 6.1 + 501.0) * 6.2831853 + time * 0.25 * 0.1;
        float s = fract(time * (0.25 + amount * 0.4) * (0.7 + hash(j * 7.7 + 503.0) * 0.6) + hash(j * 8.3 + 502.0));
        float sr = kind < 0.5 ? mix(pores.z + 70.0, 25.0, s) : mix(35.0, pores.z + 60.0, s);
        float near = 1.0 - min(1.0, abs(sr - pores.z) / 10.0);
        float dth = atan(sin(th - a), cos(th - a));
        pore = max(pore, near * exp(-(dth * dth) / 0.0018));
    }
    float d1 = abs(r - R) * unit, d2 = abs(r - (R + 7.0)) * unit;
    float a1 = (1.0 - smoothstep(0.6, 1.4, d1)) * min(1.0, 0.85 + pore) * skin.y; // ~2 px solid line, brighter at a pore
    float a2 = (1.0 - smoothstep(0.3, 1.0, d2)) * 0.6 * skin.y;             // thin border-colored echo
    float fill = (1.0 - smoothstep(R - 1.0, R + 0.5, r)) * (0.02 + skin.w * 0.05) * skin.y;
    vec3 c = colSkin.rgb * (a1 + fill) + colLine2.rgb * a2;
    fragColor = vec4(c, a1 + a2 + fill) * qt_Opacity;
}
