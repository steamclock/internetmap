//
//  node.vsh
//  InternetMap
//

attribute vec4 position;
attribute vec4 color;
attribute float size;

varying vec4 fragColor;

uniform mat4 modelViewProjectionMatrix;
uniform float maxSize;

void main()
{
    fragColor = color;
    vec4 transformed = modelViewProjectionMatrix * position;
    gl_Position = transformed;
    gl_PointSize = clamp(size * (1.0/transformed.z), 0.0, maxSize);
}
