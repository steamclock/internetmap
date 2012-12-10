//
//  node.vsh
//  InternetMap
//

attribute vec4 position;
attribute vec4 color;
attribute float size;

varying vec4 fragColor;
varying float sharpness;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform float maxSize;
uniform float screenWidth;
uniform float screenHeight;

const float minSharpDist = 1.0;
const float maxSharpDist = 0.2;

void main()
{
    fragColor = color;
    vec4 transformed = modelViewMatrix * position;
    vec4 projectedPoint = projectionMatrix * vec4(size, 0, transformed.z, 1);
    float sizeInPixels = projectedPoint.x * screenWidth / (projectedPoint.w*2.0);
    vec4 projectedOrigin = projectionMatrix * transformed;
    
    sharpness = clamp( 1.0 - ((abs(transformed.z) - maxSharpDist) / (minSharpDist - maxSharpDist)), 0.0, 1.0);
    gl_Position = projectedOrigin;
    gl_PointSize = clamp(sizeInPixels, 0.0, maxSize);
}
