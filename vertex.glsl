#version 450

layout(location = 0) in vec3 vertexPosition;
layout(location = 1) in vec3 vertexColor;

uniform vec3 cameraPosition;

uniform mat4 inverseModel;
uniform mat4 mvp;

out vec3 fragVertexColor;
out vec3 fragOrigin;
out vec3 fragDirection;


void main()
{
	// Transform vertex position from local-space to clip-space
	gl_Position = mvp * vec4(vertexPosition, 1.0);

	// Convert camera position from world-space to local-space of the model
	vec3 cameraLocal = (inverseModel * vec4(cameraPosition, 1.0)).xyz;

	// Ray origin and direction
	fragOrigin = cameraLocal;
	fragDirection = (vertexPosition - cameraLocal);

	// Providing color to fragment shader
	fragVertexColor = vertexColor;
}