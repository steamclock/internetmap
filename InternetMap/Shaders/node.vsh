//
//  node.vsh
//  InternetMap
//

attribute vec4 position;
attribute float size;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    gl_Position = modelViewProjectionMatrix * position;
    gl_PointSize = size;
}
