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
};
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
    float d1 = abs(r - R) * unit, d2 = abs(r - (R + 7.0)) * unit;
    float a1 = (1.0 - smoothstep(0.6, 1.4, d1)) * 0.85 * skin.y;            // ~2 px solid line
    float a2 = (1.0 - smoothstep(0.3, 1.0, d2)) * 0.6 * skin.y;             // thin border-colored echo
    float fill = (1.0 - smoothstep(R - 1.0, R + 0.5, r)) * (0.02 + skin.w * 0.05) * skin.y;
    vec3 c = colSkin.rgb * (a1 + fill) + colLine2.rgb * a2;
    fragColor = vec4(c, a1 + a2 + fill) * qt_Opacity;
}
