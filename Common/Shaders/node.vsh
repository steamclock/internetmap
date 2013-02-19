//
//  node.vsh
//  InternetMap
//

attribute vec4 position;
attribute vec4 color;
attribute float size;

varying vec4 fragColor;
varying float sharpness;

varying vec2 pointCentre;
varying float pixelSize;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform float minSize;
uniform float maxSize;
uniform float screenWidth;
uniform float screenHeight;

const float minSharpDist = 1.0;
const float maxSharpDist = 0.2;

void main()
{
    fragColor = color;
    vec4 transformed = modelViewMatrix * position;
    vec4 projectedOrigin = projectionMatrix * transformed;
    vec4 projectedPoint = projectionMatrix * vec4(transformed.x + size, transformed.y, transformed.z, 1);
    float sizeInPixels = (projectedPoint.x - projectedOrigin.x) * screenWidth / (projectedPoint.w*2.0);
        
    sizeInPixels = clamp(sizeInPixels, minSize, maxSize - 1.0);
    
    sharpness = clamp( 1.0 - ((abs(transformed.z) - maxSharpDist) / (minSharpDist - maxSharpDist)), 0.0, 1.0);
    
    pointCentre = vec2((((projectedOrigin.x / projectedOrigin.w) + 1.0) * 0.5 * screenWidth),
                       (((projectedOrigin.y / projectedOrigin.w) + 1.0) * 0.5 * screenHeight));
    pixelSize = sizeInPixels;
    gl_Position = projectedOrigin;
    gl_PointSize = sizeInPixels + 1.0;
}
