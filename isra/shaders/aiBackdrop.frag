#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    vec4 colorA;
    vec4 colorB;
    vec4 colorC;
    vec4 dotColor;
    vec2 resolution;
    float qt_Opacity;
    float time;
    float gradientAngle;
    float glowOpacity;
    float dotOpacity;
    float maxAlpha;
    float cellSize;
    float baseRadius;
    float noiseScale;
    float islandThreshold;
    float coreDepth;
    float minIslandCeiling;
    float edgeSigma;
    float edgeIntensity;
    float saturation;
    float lightness;
};

const float LATTICE = 26.0;

float hash(vec2 p) {
    p = mod(p, LATTICE);
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float ease(float x) {
    return x * x * (3.0 - 2.0 * x);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = p - i;

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    vec2 u = vec2(ease(f.x), ease(f.y));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float density(vec2 n) {
    float n1 = valueNoise(n + vec2(time * 0.18, time * 0.12));
    float n2 = valueNoise(n * 2.1 + vec2(-time * 0.1, time * 0.15));
    return n1 * 0.7 + n2 * 0.3;
}

float ceilingField(vec2 n) {
    return valueNoise(n * 0.6 + vec2(100.0 + time * 0.08, -50.0 + time * 0.05));
}

void main() {
    vec2 px = qt_TexCoord0 * resolution;

    float ang = radians(gradientAngle);
    vec2 centered = px - resolution * 0.5;
    float side = max(resolution.x, resolution.y) * 1.5;
    float lx = centered.x * cos(-ang) - centered.y * sin(-ang);
    float g = clamp(lx / side + 0.5, 0.0, 1.0);

    vec3 grad;
    if (g < 0.34)
        grad = mix(colorA.rgb, colorB.rgb, g / 0.34);
    else if (g < 0.67)
        grad = mix(colorB.rgb, colorC.rgb, (g - 0.34) / 0.33);
    else
        grad = mix(colorC.rgb, colorA.rgb, (g - 0.67) / 0.33);

    float luma = dot(grad, vec3(0.2126, 0.7152, 0.0722));
    grad = clamp(mix(vec3(luma), grad, 1.0 + saturation) + lightness, 0.0, 1.0);

    float dx = min(px.x, resolution.x - px.x);
    float dy = min(px.y, resolution.y - px.y);
    float denom = 2.0 * edgeSigma * edgeSigma;
    float fx = exp(-(dx * dx) / denom);
    float fy = exp(-(dy * dy) / denom);

    const float CORNER_BOOST = 0.306;
    float edge = edgeIntensity * (1.0 + CORNER_BOOST * fx * fy)
               * (1.0 - (1.0 - fx) * (1.0 - fy));

    vec4 col = vec4(grad, 1.0) * (edge * glowOpacity);

    vec2 cellIdx = floor(px / cellSize + 0.5);
    float dist = length(px - cellIdx * cellSize);
    vec2 n = cellIdx * noiseScale;

    float d = density(n);
    if (d > islandThreshold) {
        float ceilingVal = minIslandCeiling + (1.0 - minIslandCeiling) * ceilingField(n);
        float depth = min(1.0, (d - islandThreshold) / (coreDepth * ceilingVal));
        float eased = ease(depth);

        float radius = baseRadius * (1.5 - 0.5 * eased);
        float alpha = maxAlpha * eased * dotOpacity;
        alpha *= 1.0 - smoothstep(radius - 0.75, radius + 0.75, dist);

        col.rgb = col.rgb * (1.0 - alpha) + dotColor.rgb * alpha;
        col.a = col.a * (1.0 - alpha) + alpha;
    }

    fragColor = col * qt_Opacity;
}
