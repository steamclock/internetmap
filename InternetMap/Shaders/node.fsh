//
//  node.fsh
//  InternetMap
//

precision mediump float;
varying vec4 fragColor;

void main()
{
//    float dist = distance(gl_PointCoord, vec2(0.5, 0.5));
//    dist = 1.0 - (clamp(dist, 0.0, 0.5) / 0.5);
//    gl_FragColor = vec4(fragColor.r * dist, fragColor.g * dist, fragColor.b * dist, fragColor.a * dist);
    float dist = distance(gl_PointCoord, vec2(0.5, 0.5));
    float irad = 0.3;
    float orad = 0.5;
    float alpha = 1.0 - clamp((dist - irad)/(orad - irad), 0.0, 1.0);
    gl_FragColor = vec4(fragColor.r*alpha, fragColor.g*alpha, fragColor.b*alpha, fragColor.a*alpha);
}
