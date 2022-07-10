#version 330
layout (location = 0) in vec3 aPos;

uniform mat4 tform;
uniform mat4 subtform;

void main()
{
	gl_Position = tform * subtform * vec4(aPos.x, aPos.y, aPos.z, 1.0);
}
