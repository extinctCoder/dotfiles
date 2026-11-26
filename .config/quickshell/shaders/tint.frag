#version 440
// Paints an image in one exact color, keeping only its shape (alpha).
// Used for single-color app icons: the theme's accent, exactly.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 tint;
};
layout(binding = 1) uniform sampler2D source;
void main() {
    float a = texture(source, qt_TexCoord0).a;
    fragColor = vec4(tint.rgb, 1.0) * a * qt_Opacity;   // premultiplied
}
