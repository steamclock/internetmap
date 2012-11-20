//
//  line.vsh
//  InternetMap
//

attribute vec4 position;
attribute vec4 lineColor;

varying vec4 fragColor;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    fragColor = lineColor;
    vec4 transformed = modelViewProjectionMatrix * position;
    gl_Position = transformed;
}
