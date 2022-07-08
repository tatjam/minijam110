#version 330
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTex;

out vec2 vTex;

uniform mat4 tform;
uniform mat4 sprite_tform;

void main()
{
	vTex = aTex;
	gl_Position = tform * sprite_tform * vec4(aPos.x, aPos.y, aPos.z, 1.0);
}
