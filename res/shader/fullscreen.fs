#version 330
out vec4 FragColor;

in vec2 vTex;

uniform sampler2D tex;

void main()
{
    vec2 coord = vTex;

    coord = vec2(vTex.x, 1.0 - vTex.y);

    vec4 col = texture(tex, coord);

    FragColor = vec4(col.xyz, 1.0);
}
