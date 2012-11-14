//
//  node.fsh
//  InternetMap
//

precision mediump float;

void main()
{
    float dist = distance(gl_PointCoord, vec2(0.5, 0.5));
    dist = 1.0 - (clamp(dist, 0.0, 0.5) / 0.5);
    dist = dist / 5.0;
    gl_FragColor = vec4(dist, dist, dist, dist);
}
