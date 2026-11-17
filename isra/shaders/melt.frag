#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 winSize;
    vec4 innerRect;
    vec4 innerR;
    float fillet;
    vec4 frameColor;
    vec4 outlineColor;
    vec4 p0; vec4 q0;
    vec4 p1; vec4 q1;
    vec4 p2; vec4 q2;
    vec4 p3; vec4 q3;
    vec4 p4; vec4 q4;
    vec4 p5; vec4 q5;
    vec4 pillRect; vec4 pillR;
    vec4 pillTop; vec4 pillBottom;
    float pillFillet;
};

// rect = (x1, y1, x2, y2); radii = (tl, tr, br, bl)
float sdRoundRect(vec2 p, vec4 rect, vec4 radii) {
    vec2 c = (rect.xy + rect.zw) * 0.5;
    vec2 hs = (rect.zw - rect.xy) * 0.5;
    bool right = p.x > c.x;
    bool bottom = p.y > c.y;
    float rad = right ? (bottom ? radii.z : radii.y) : (bottom ? radii.w : radii.x);
    rad = min(rad, min(hs.x, hs.y));
    vec2 q = abs(p - c) - (hs - rad);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - rad;
}

float smin(float a, float b, float k) {
    if (k <= 0.0) return min(a, b);
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

float roundUnion(float a, float b, float r) {
    vec2 u = max(vec2(r - a, r - b), vec2(0.0));
    return max(r, min(a, b)) - length(u);
}

float panelFillet(vec4 rect) {
    return min(fillet, min((rect.z - rect.x) * 0.5, rect.w - rect.y));
}

void main() {
    vec2 p = qt_TexCoord0 * winSize;
    float frame = -sdRoundRect(p, innerRect, innerR);
    float pill = sdRoundRect(p, pillRect, pillR);
    float s0 = sdRoundRect(p, p0, q0);
    float s1 = sdRoundRect(p, p1, q1);
    float s2 = sdRoundRect(p, p2, q2);
    float s3 = sdRoundRect(p, p3, q3);
    float s4 = sdRoundRect(p, p4, q4);
    float s5 = sdRoundRect(p, p5, q5);
    float d = roundUnion(frame, pill, pillFillet);
    d = smin(d, s0, panelFillet(p0));
    d = smin(d, s1, panelFillet(p1));
    d = smin(d, s2, panelFillet(p2));
    d = smin(d, s3, panelFillet(p3));
    d = smin(d, s4, panelFillet(p4));
    d = smin(d, s5, panelFillet(p5));
    float rest = min(frame, min(min(s0, s1), min(min(s2, s3), min(s4, s5))));
    float t = clamp((p.y - pillRect.y) / max(pillRect.w - pillRect.y, 1.0), 0.0, 1.0);
    vec4 c = pill <= rest ? mix(pillTop, pillBottom, t) : frameColor;
    vec4 fill = vec4(c.rgb * c.a, c.a) * clamp(0.5 - d, 0.0, 1.0);
    float edge = clamp(1.0 - abs(d + 0.5), 0.0, 1.0);
    vec4 outline = vec4(outlineColor.rgb * outlineColor.a, outlineColor.a) * edge;
    fragColor = (outline + fill * (1.0 - outline.a)) * qt_Opacity;
}
