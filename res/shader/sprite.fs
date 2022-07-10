#version 330
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 effect;

in vec2 vTex;

uniform sampler2D tex;
uniform int has_fx;

uniform vec4 tint;
uniform int clear_fx;

// Contains (x, y) = lower bound (z, w) = size
uniform vec4 clip;

void main()
{
    vec2 coord = vec2(vTex.x * clip.z + clip.x, vTex.y * clip.w + clip.y);

    if(has_fx == 1)
    {
        effect = texture(tex, coord);
        // OpenGL requires we write to all targets!
        color = vec4(0, 0, 0, 0);
    }
    else
    {
        color = texture(tex, coord) * tint;
        if(clear_fx == 1 && color.a != 0)
        {
            effect = vec4(0, 0, 0, 1);
        }
        else
        {
            effect = vec4(0, 0, 0, 0);
        }
    }
}
