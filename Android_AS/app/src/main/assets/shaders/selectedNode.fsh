//
//  node.fsh
//  InternetMap
//

varying vec4 fragColor;
varying float sharpness;
varying vec2 pointCentre;
varying float pixelSize;

void main()
{
    float dist = distance(gl_FragCoord.xy, pointCentre) / pixelSize;
    float irad = 0.3 + (0.1999 * sharpness);
    float orad = 0.5;
    float alpha = 1.0 - clamp((dist - irad)/(orad - irad), 0.0, 1.0);
    if(alpha < 0.35) discard;
    float glow = 0.2 * clamp(1.0 - dist * 2.0, 0.0, 0.6);
    gl_FragColor = vec4(fragColor.r + glow, fragColor.g + glow, fragColor.b + glow, fragColor.a);
}
