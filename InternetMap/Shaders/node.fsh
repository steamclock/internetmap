//
//  node.fsh
//  InternetMap
//

precision mediump float;
varying vec4 fragColor;

void main()
{
    float dist = distance(gl_PointCoord, vec2(0.5, 0.5));
    dist = 1.0 - (clamp(dist, 0.0, 0.5) / 0.5);
    gl_FragColor = vec4(fragColor.r * dist, fragColor.g * dist, fragColor.b * dist, fragColor.a * dist);
    //gl_FragColor = vec4(dist, dist, dist, dist);
    //gl_FragColor = vec4(dist, 0, 0, dist);
}
