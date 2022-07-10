#version 330
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 effect;

uniform vec4 tint;
uniform vec4 fx_tint;

void main()
{
    color = tint;
    effect = fx_tint;
}
