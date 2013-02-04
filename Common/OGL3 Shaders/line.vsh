//
//  line.vsh
//  InternetMap
//

#version 330

in vec4 position;
in vec4 color;

smooth out vec4 fragColor;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    fragColor = color;
    vec4 transformed = modelViewProjectionMatrix * position;
    gl_Position = transformed;
}
