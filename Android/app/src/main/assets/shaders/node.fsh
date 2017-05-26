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
    gl_FragColor = vec4(fragColor.r*alpha, fragColor.g*alpha, fragColor.b*alpha, fragColor.a*alpha);
}
