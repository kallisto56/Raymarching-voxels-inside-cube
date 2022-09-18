#version 450

// Try uncommenting 'noperspective' to see what happens.
/* noperspective  */in vec3 fragVertexColor;
/* noperspective  */in vec3 fragOrigin;
/* noperspective  */in vec3 fragDirection;

// TEXTURE_3D, that contains colors for 512 voxels (8x8x8)
uniform sampler3D volume;

// This is an output variable that will be used by OpenGL
out vec4 fragOutputColor;

// This determines how many voxels per axis we have;
// Note, that the more voxels you have, the more
// `COUNT_STEPS` it will require to traverse it.
#define COUNT_VOXELS 8

// Maximum count of steps DDA algorithm will perform
#define COUNT_STEPS 32


vec2 intersectAABB (vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax)
{
	// taken from: https://gist.github.com/DomNomNom/46bb1ce47f68d255fd5d
	// which was adapted from https://github.com/evanw/webgl-path-tracing/blob/master/webgl-path-tracing.js
	vec3 tMin = (boxMin - rayOrigin) / rayDir;
	vec3 tMax = (boxMax - rayOrigin) / rayDir;

	vec3 t1 = min(tMin, tMax);
	vec3 t2 = max(tMin, tMax);

	float tNear = max(max(t1.x, t1.y), t1.z);
	float tFar = min(min(t2.x, t2.y), t2.z);

	return vec2(tNear, tFar);
}


void main ()
{
	float countVoxels = float(COUNT_VOXELS);
	vec3 direction = normalize(fragDirection);
	vec3 point = fragOrigin;
	
	// Move ray inside of the cube [-0.5...0.5]
	point = point + direction * max(0, intersectAABB(point, direction, vec3(-0.5), vec3(+0.5)).x);

	// Convert from [-0.5...0.5] to [0.0...COUNT_VOXELS]
	point = (point + 0.5) * countVoxels;

	// DDA prep (source: https://www.shadertoy.com/view/4dX3zl)
	ivec3 mapPos = ivec3(floor(point));
	vec3 deltaDist = abs(vec3(length(direction)) / direction);
	vec3 rayDirSign = sign(direction);
	ivec3 rayStep = ivec3(rayDirSign);
	vec3 sideDist = (rayDirSign * (vec3(mapPos) - point) + (rayDirSign * 0.5) + 0.5) * deltaDist;
	bvec3 mask;

	ivec3 zero = ivec3(0);
	ivec3 seven = ivec3(COUNT_VOXELS - 1);

	// ...
	for (int n = 0; n < COUNT_STEPS; n++)
	{
		// Checking if currently sampled voxel is 'solid'
		vec4 color = textureLod(volume, vec3(mapPos) / countVoxels, 0);
		if (color.xyz != 0)
		{
			fragOutputColor = vec4(color.xyz, 1.0);
			return;
		}

		// Advance along the ray
		mask = lessThanEqual(sideDist.xyz, min(sideDist.yzx, sideDist.zxy));
		sideDist += vec3(mask) * deltaDist;
		mapPos += ivec3(vec3(mask)) * rayStep;

		// Exit, if we are out of bounds
		if (clamp(mapPos, zero, seven) != mapPos)
		{
			break;
		}
	}

	// Discard value
	// discard;
	fragOutputColor = vec4(fragVertexColor.xyz, 1) * vec4(0.5, 0.5, 0.5, 1);
}