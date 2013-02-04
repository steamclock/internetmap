//
//  node.fsh
//  InternetMap
//

#version 330

precision mediump float;

smooth in vec4 fragColor;
in float sharpness;

out vec4 outputColor;

void main()
{
    float dist = distance(gl_PointCoord, vec2(0.5, 0.5));
    float irad = 0.3 + (0.1999 * sharpness);
    float orad = 0.5;
    float alpha = 1.0 - clamp((dist - irad)/(orad - irad), 0.0, 1.0);
    if(alpha < 0.35) discard;
    float glow = 0.2 * clamp(1.0 - dist * 2.0, 0.0, 0.6);
    outputColor = vec4(fragColor.r + glow, fragColor.g + glow, fragColor.b + glow, fragColor.a);
}
