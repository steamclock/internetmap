//
//  node.vsh
//  InternetMap
//

attribute vec4 position;
attribute vec4 color;
attribute float size;

varying vec4 fragColor;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    fragColor = color;
    gl_Position = modelViewProjectionMatrix * position;
    gl_PointSize = size;
}
