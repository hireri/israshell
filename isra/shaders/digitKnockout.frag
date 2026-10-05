#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 texel;
    float radius;
};

layout(binding = 1) uniform sampler2D d0;
layout(binding = 2) uniform sampler2D d1;
layout(binding = 3) uniform sampler2D d2;
layout(binding = 4) uniform sampler2D d3;

float dilated(sampler2D s, vec2 uv) {
    float a = textureLod(s, uv, 0.0).a;
    for (int i = 0; i < 24; i++) {
        float t = 6.2831853 * float(i) / 24.0;
        vec2 dir = vec2(cos(t), sin(t)) * texel;
        a = max(a, textureLod(s, uv + dir * radius, 0.0).a);
        if (i % 2 == 0)
            a = max(a, textureLod(s, uv + dir * radius * 0.66, 0.0).a);
        if (i % 4 == 0)
            a = max(a, textureLod(s, uv + dir * radius * 0.33, 0.0).a);
    }
    return a;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec4 c0 = textureLod(d0, uv, 0.0);
    vec4 c1 = textureLod(d1, uv, 0.0);
    vec4 c2 = textureLod(d2, uv, 0.0);
    vec4 c3 = textureLod(d3, uv, 0.0);

    float o2 = c2.a > 0.0 ? dilated(d3, uv) : 0.0;
    float o1 = c1.a > 0.0 ? max(dilated(d2, uv), dilated(d3, uv)) : 0.0;
    float o0 = c0.a > 0.0 ? max(max(dilated(d1, uv), dilated(d2, uv)), dilated(d3, uv)) : 0.0;

    vec4 acc = c0 * (1.0 - o0);
    acc = c1 * (1.0 - o1) + acc * (1.0 - c1.a * (1.0 - o1));
    acc = c2 * (1.0 - o2) + acc * (1.0 - c2.a * (1.0 - o2));
    acc = c3 + acc * (1.0 - c3.a);
    fragColor = acc * qt_Opacity;
}
