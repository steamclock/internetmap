//
//  line.vsh
//  InternetMap
//

attribute vec4 position;
attribute vec4 color;

varying vec4 fragColor;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    fragColor = color;
    vec4 transformed = modelViewProjectionMatrix * position;
    gl_Position = transformed;
}
