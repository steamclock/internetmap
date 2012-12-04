//
//  node.vsh
//  InternetMap
//

attribute vec4 position;
attribute vec4 color;
attribute float size;

varying vec4 fragColor;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform float maxSize;
uniform float screenWidth;
uniform float screenHeight;

void main()
{
    fragColor = color;
    vec4 transformed = modelViewMatrix * position;
    vec4 projectedPoint = projectionMatrix * vec4(size, 0, transformed.z, 1);
    float sizeInPixels = projectedPoint.x * screenWidth / (projectedPoint.w*2.0);
    vec4 projectedOrigin = projectionMatrix * transformed;
    gl_Position = projectedOrigin;
    gl_PointSize = clamp(sizeInPixels, 0.0, maxSize);
}
