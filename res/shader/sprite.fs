#version 330
layout(location = 0) out vec4 color;
layout(location = 1) out vec3 effect;

in vec2 vTex;

uniform sampler2D tex;
uniform vec4 tint;

void main()
{
    vec2 coord = vTex;

    coord = vec2(vTex.x, vTex.y);

    color = texture(tex, coord) * tint;
}
