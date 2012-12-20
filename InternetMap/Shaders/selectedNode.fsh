//
//  node.fsh
//  InternetMap
//

precision mediump float;
varying vec4 fragColor;
varying float sharpness;

void main()
{
    float dist = distance(gl_PointCoord, vec2(0.5, 0.5));
    float irad = 0.3 + (0.1999 * sharpness);
    float orad = 0.5;
    float alpha = 1.0 - clamp((dist - irad)/(orad - irad), 0.0, 1.0);
    if(alpha < 0.35) discard;
    gl_FragColor = vec4(fragColor.r, fragColor.g, fragColor.b, fragColor.a);
}
