#version 440
layout(location = 0) in vec2 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;
layout(location = 0) out vec2 qt_TexCoord0;
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
void main() {
    qt_TexCoord0 = qt_MultiTexCoord0;
    gl_Position = qt_Matrix * vec4(qt_Vertex, 0.0, 1.0);
}
