#version 330
layout(location = 0) out vec3 color;

in vec2 vTex;

uniform sampler2D tex;

void main()
{
    vec2 coord = vTex;

    coord = vec2(vTex.x, 1.0 - vTex.y);

    vec4 col = texture(tex, coord);

    color = col.xyz;
}
