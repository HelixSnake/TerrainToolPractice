#ifndef NOISE_INCLUDED
#define NOISE_INCLUDED

#include "Random.cginc"
#include "Helper.cginc"

inline float PerlinNoise(float density, float radius, float2 UV)
{
	float oneDivDensity = 1.0 / density;
	float densitydivradius = density / radius;
	float2 upperLeftCorner = floor(UV * density);
	float finalValue = 0;
	for (int i = 0; i < 2; i++)
	{
		for (int j = 0; j < 2; j++)
		{
			float2 cornerPos = upperLeftCorner + float2(i, j);
			float2 cornerValue = normalize(hash22(cornerPos) - float2(0.5, 0.5));
			float2 cornerVect = UV - cornerPos * oneDivDensity;
			float value = dot(cornerValue, cornerVect) * densitydivradius;
			//finalValue += saturate(invlerp(oneDivDensity, 0, length(cornerVect))) * value;
			finalValue += smoothstep(oneDivDensity, 0, length(cornerVect)) * value;
		}
	}
	return clamp(finalValue, -1, 1);
}

inline float PerlinNoise3D(float density, float radius, float3 pos)
{
	float oneDivDensity = 1.0 / density;
	float densitydivradius = density / radius;
	float3 upperLeftCorner = floor(pos * density);
	float finalValue = 0;
	for (int i = 0; i < 2; i++)
	{
		for (int j = 0; j < 2; j++)
		{
			for (int k = 0; k < 2; k++)
			{
				float3 cornerPos = upperLeftCorner + float3(i, j, k);
				float3 cornerValue = normalize(hash33(cornerPos) - float3(0.5, 0.5, 0.5));
				float3 cornerVect = pos - cornerPos * oneDivDensity;
				float value = dot(cornerValue, cornerVect) * densitydivradius;
				finalValue += smoothstep(oneDivDensity, 0, length(cornerVect)) * value;
			}
		}
	}
	return clamp(finalValue, -1, 1);
}

inline float PerlinNoise3D_Test(float density, float radius, float3 pos)
{
	float finalValue = 0;
	for (int i = 0; i < 2; i++)
	{
		for (int j = 0; j < 2; j++)
		{
			for (int k = 0; k < 2; k++)
			{
				finalValue += pos.x;
			}
		}
	}
	return finalValue;
}

inline float PerlinNoise4D(float density, float radius, float4 pos)
{
	float oneDivDensity = 1.0 / density;
	float densitydivradius = density / radius;
	float halfOneDivDens = oneDivDensity * 0.5;
	float4 upperLeftCorner = floor(pos * density);
	float finalValue = 0;
	for (int i = 0; i < 2; i++)
	{
		for (int j = 0; j < 2; j++)
		{
			for (int k = 0; k < 2; k++)
			{
				for (int l = 0; l < 2; l++)
				{
					float4 cornerPos = upperLeftCorner + float4(i, j, k, l);
					float4 cornerValue = normalize(hash44(cornerPos) - float4(0.5, 0.5, 0.5, 0.5));
					float4 cornerVect = pos - cornerPos * oneDivDensity;
					float value = dot(cornerValue, cornerVect) * densitydivradius;
					finalValue += smoothstep(oneDivDensity, 0, length(cornerVect)) * value;
				}
			}
		}
	}
	return clamp(finalValue, -1, 1);
}

inline float Voronoi(float cellDensity, float2 UV, float radius)
{
	float oneDivCellDensity = 1.0 / cellDensity;
	float2 uvTimesCellDens = UV * cellDensity;
	float minDistance = radius;
	for (int i = 0; i < 3; i++)
	{
		for (int j = 0; j < 3; j++)
		{
			int2 cell = floor(uvTimesCellDens) + int2(i-1, j-1);
			float2 cellValue = hash22(cell);
			cellValue = (cellValue + (float2)cell) * oneDivCellDensity;
			minDistance = min(minDistance, distance(UV, cellValue));
		}
	}
	float returnValue = saturate(minDistance / radius); 
	return returnValue;
}

inline float Voronoi3D(float cellDensity, float3 pos, float radius)
{
	float oneDivCellDensity = 1.0 / cellDensity;
	float3 posTimesCellDens = pos * cellDensity;
	float minDistance = radius;
	for (int i = 0; i < 3; i++)
	{
		for (int j = 0; j < 3; j++)
		{
			for (int k = 0; k < 3; k++)
			{
				int3 cell = floor(posTimesCellDens) + int3(i - 1, j - 1, k - 1);
				float3 cellValue = hash33(cell);
				cellValue = (cellValue + (float3)cell) * oneDivCellDensity;
				minDistance = min(minDistance, distance(pos, cellValue));
			}
		}
	}
	float returnValue = saturate(minDistance / radius);
	return returnValue;
}

inline float Voronoi4D(float cellDensity, float4 pos, float radius)
{
	float oneDivCellDensity = 1.0 / cellDensity;
	float4 posTimesCellDens = pos * cellDensity;
	float minDistance = radius;
	for (int i = 0; i < 3; i++)
	{
		for (int j = 0; j < 3; j++)
		{
			for (int k = 0; k < 3; k++)
			{
				for (int l = 0; l < 3; l++)
				{
					int4 cell = floor(posTimesCellDens) + int4(i - 1, j - 1, k - 1, l - 1);
					float4 cellValue = hash44(cell);
					cellValue = (cellValue + (float4)cell) * oneDivCellDensity;
					minDistance = min(minDistance, distance(pos, cellValue));
				}
			}
		}
	}
	float returnValue = saturate(minDistance / radius);
	return returnValue;
}

inline float VoronoiAnimatedLowQuality(float cellDensity, float2 UV, float radius, float speed)
{
	float oneDivCellDensity = 1.0 / cellDensity;
	float minDistance = radius;
	for (int i = 0; i < 3; i++)
	{
		for (int j = 0; j < 3; j++)
		{
			int2 cell = floor(UV * cellDensity) + int2(i - 1, j - 1);
			float time = _Time.x * speed + hash22(cell);
			//float time = _Time.x * speed;
			int timeFloor = floor(time) * 100;
			int nextTimeFloor = timeFloor + 100;
			float timeFrac = frac(time);
			float2 cellValue1 = hash22(cell + int2(timeFloor, timeFloor));
			float2 cellValue2 = hash22(cell + int2(nextTimeFloor, nextTimeFloor));
			float2 cellValue = lerp(cellValue1, cellValue2, timeFrac);
			cellValue = (cellValue + (float2)cell) * oneDivCellDensity;
			minDistance = min(minDistance, distance(UV, cellValue));
		}
	}
	float returnValue = saturate(minDistance / radius);
	return returnValue;
}

inline float VoronoiAnimated(float cellDensity, float2 UV, float radius, float speed)
{
	float oneDivCellDensity = 1.0 / cellDensity;
	float minDistance = radius;
	for (int i = 0; i < 3; i++)
	{
		for (int j = 0; j < 3; j++)
		{
			int2 cell = floor(UV * cellDensity) + int2(i - 1, j - 1);
			float time = _Time.x * speed + hash22(cell);
			int timeFloor = floor(time) * 100;
			int prevTimeFloor = timeFloor - 100;
			int nextTimeFloor = timeFloor + 100;
			int nextTimeFloor2 = timeFloor + 200;
			float timeFrac = frac(time);
			float2 cellValue0 = hash22(cell + int2(prevTimeFloor, prevTimeFloor));
			float2 cellValue1 = hash22(cell + int2(timeFloor, timeFloor));
			float2 cellValue2 = hash22(cell + int2(nextTimeFloor, nextTimeFloor));
			float2 cellValue3 = hash22(cell + int2(nextTimeFloor2, nextTimeFloor2));

			float2 slope1 = ((cellValue1 - cellValue0) + (cellValue2 - cellValue1)) / 2;
			float2 slope2 = ((cellValue2 - cellValue1) + (cellValue3 - cellValue2)) / 2;
			slope1 /= (cellValue2 - cellValue1);
			slope2 /= (cellValue2 - cellValue1);
			slope1 = clamp(slope1, float2(-100, -100), float2(100, 100));
			slope2 = clamp(slope2, float2(-100, -100), float2(100, 100));

			float f = timeFrac;
			float easeInx = (1 - slope1.x)*f*f + slope1.x * f;
			float easeOutx = (slope2.x - 1)*f*f + (2 - slope2.x)*f;
			float easeInOutx = easeInx * (1 - f) + easeOutx * f;
			float easeIny = (1 - slope1.y)*f*f + slope1.y * f;
			float easeOuty = (slope2.y - 1)*f*f + (2 - slope2.y)*f;
			float easeInOuty = easeIny * (1 - f) + easeOuty * f;
			float2 cellValue;
			cellValue.x = lerp(cellValue1.x, cellValue2.x, easeInOutx);
			cellValue.y = lerp(cellValue1.y, cellValue2.y, easeInOuty);
			cellValue = (cellValue + (float2)cell) * oneDivCellDensity;
			minDistance = min(minDistance, distance(UV, cellValue));
		}
	}
	float returnValue = saturate(minDistance / radius);
	return returnValue;
}

inline float VoronoiAnimated5x5(float cellDensity, float2 UV, float radius, float speed, float range)
{
	float oneDivCellDensity = 1.0 / cellDensity;
	float minDistance = radius;
	for (int i = 0; i < 5; i++)
	{
		for (int j = 0; j < 5; j++)
		{
			int2 cell = floor(UV * cellDensity) + int2(i - 2, j - 2);
			float time = _Time.x * speed + hash22(cell);
			int timeFloor = floor(time) * 100;
			int prevTimeFloor = timeFloor - 100;
			int nextTimeFloor = timeFloor + 100;
			int nextTimeFloor2 = timeFloor + 200;
			float timeFrac = frac(time);
			float2 cellValue0 = hash22(cell + int2(prevTimeFloor, prevTimeFloor)) * range;
			float2 cellValue1 = hash22(cell + int2(timeFloor, timeFloor)) * range;
			float2 cellValue2 = hash22(cell + int2(nextTimeFloor, nextTimeFloor)) * range;
			float2 cellValue3 = hash22(cell + int2(nextTimeFloor2, nextTimeFloor2)) * range;

			float2 slope1 = ((cellValue1 - cellValue0) + (cellValue2 - cellValue1)) / 2;
			float2 slope2 = ((cellValue2 - cellValue1) + (cellValue3 - cellValue2)) / 2;
			slope1 /= (cellValue2 - cellValue1);
			slope2 /= (cellValue2 - cellValue1);
			slope1 = clamp(slope1, float2(-100, -100), float2(100, 100));
			slope2 = clamp(slope2, float2(-100, -100), float2(100, 100));

			float f = timeFrac;
			float easeInx = (1 - slope1.x)*f*f + slope1.x * f;
			float easeOutx = (slope2.x - 1)*f*f + (2 - slope2.x)*f;
			float easeInOutx = easeInx * (1 - f) + easeOutx * f;
			float easeIny = (1 - slope1.y)*f*f + slope1.y * f;
			float easeOuty = (slope2.y - 1)*f*f + (2 - slope2.y)*f;
			float easeInOuty = easeIny * (1 - f) + easeOuty * f;
			float2 cellValue;
			cellValue.x = lerp(cellValue1.x, cellValue2.x, easeInOutx);
			cellValue.y = lerp(cellValue1.y, cellValue2.y, easeInOuty);
			cellValue = (cellValue + (float2)cell) * oneDivCellDensity;
			minDistance = min(minDistance, distance(UV, cellValue));
		}
	}
	float returnValue = saturate(minDistance / radius);
	return returnValue;
}

inline float VoronoiAnimated5x5Normalized(float cellDensity, float2 UV, float radius, float speed, float range, float blend)
{
	float oneDivCellDensity = 1.0 / cellDensity;
	float distances[25];
	for (int i = 0; i < 5; i++)
	{
		for (int j = 0; j < 5; j++)
		{
			int2 cell = floor(UV * cellDensity) + int2(i - 2, j - 2);
			float time = _Time.x * speed + hash22(cell);
			int timeFloor = floor(time) * 100;
			int prevTimeFloor = timeFloor - 100;
			int nextTimeFloor = timeFloor + 100;
			int nextTimeFloor2 = timeFloor + 200;
			float timeFrac = frac(time);
			float cellSize1 = lerp(0.5, 2, hash22(cell + int2(timeFloor, timeFloor)));
			float cellSize2 = lerp(0.5, 2, hash22(cell + int2(nextTimeFloor, nextTimeFloor)));
			float cellSize = lerp(cellSize1, cellSize2, timeFrac);
			float2 cellValue0 = hash22(cell + int2(prevTimeFloor, prevTimeFloor)) * range;
			float2 cellValue1 = hash22(cell + int2(timeFloor, timeFloor)) * range;
			float2 cellValue2 = hash22(cell + int2(nextTimeFloor, nextTimeFloor)) * range;
			float2 cellValue3 = hash22(cell + int2(nextTimeFloor2, nextTimeFloor2)) * range;

			float2 slope1 = ((cellValue1 - cellValue0) + (cellValue2 - cellValue1)) / 2;
			float2 slope2 = ((cellValue2 - cellValue1) + (cellValue3 - cellValue2)) / 2;
			slope1 /= (cellValue2 - cellValue1);
			slope2 /= (cellValue2 - cellValue1);
			slope1 = clamp(slope1, float2(-100, -100), float2(100, 100));
			slope2 = clamp(slope2, float2(-100, -100), float2(100, 100));

			float f = timeFrac;
			float easeInx = (1 - slope1.x)*f*f + slope1.x * f;
			float easeOutx = (slope2.x - 1)*f*f + (2 - slope2.x)*f;
			float easeInOutx = easeInx * (1 - f) + easeOutx * f;
			float easeIny = (1 - slope1.y)*f*f + slope1.y * f;
			float easeOuty = (slope2.y - 1)*f*f + (2 - slope2.y)*f;
			float easeInOuty = easeIny * (1 - f) + easeOuty * f;
			float2 cellValue;
			cellValue.x = lerp(cellValue1.x, cellValue2.x, easeInOutx);
			cellValue.y = lerp(cellValue1.y, cellValue2.y, easeInOuty);
			cellValue = (cellValue + (float2)cell) * oneDivCellDensity;
			distances[i + j * 5] = distance(UV, cellValue) * cellSize;
		}
	}
	float minDistance = radius;
	float minDistance2 = radius;
	for (int k = 0; k < 25; k++)
	{
		{
			UNITY_FLATTEN
				if (minDistance > distances[k])
				{
					minDistance2 = minDistance;
					minDistance = distances[k];
				}
				else if (minDistance2 > distances[k])
				{
					minDistance2 = distances[k];
				}
		}
	}
	float returnValue = lerp(saturate(minDistance / radius), saturate(minDistance / minDistance2), blend);
	return returnValue;
}

inline float VoronoiNormalized(float cellDensity, float2 UV, float radius)
{
	float oneDivCellDensity = 1.0 / cellDensity;
	float distances[9];
	for (int i = 0; i < 3; i++)
	{
		for (int j = 0; j < 3; j++)
		{
			int2 cell = floor(UV * cellDensity) + int2(i - 1, j - 1);
			float2 cellValue = hash22(cell);
			cellValue = (cellValue + (float2)cell) * oneDivCellDensity;
			distances[i+j*3] = distance(UV, cellValue);
		}
	}
	float minDistance = radius;
	float minDistance2 = radius;
	for (int k = 0; k < 9; k++)
	{
		{
			UNITY_FLATTEN
			if (minDistance > distances[k])
			{
				minDistance2 = minDistance;
				minDistance = distances[k];
			}
			else if (minDistance2 > distances[k])
			{
				minDistance2 = distances[k];
			}
		}
	}
	float returnValue = saturate(minDistance / minDistance2);
	return returnValue;
}

inline float VoronoiNormalized2(float cellDensity, float2 UV, float radius)
{
	float oneDivCellDensity = 1.0 / cellDensity;
	float2 points[9];
	for (int i = 0; i < 3; i++)
	{
		for (int j = 0; j < 3; j++)
		{
			int2 cell = floor(UV * cellDensity) + int2(i - 1, j - 1);
			float2 cellValue = hash22(cell);
			cellValue = (cellValue + (float2)cell) * oneDivCellDensity;
			points[i + j * 3] = cellValue;
		}
	}
	/*for (int i = 0; i < 3; i++)
	{
		for (int j = 0; j < 2; j++)
		{
			float2 point1 = points[i + j * 3];
			float2 point2 = points[i + (j+1) * 3];
		}
	}*/
	//Horizontal center line checks
	float2 closestPoint1 = float2(0,0);
	float2 closestPoint2 = float2(0, 0);
	float closestDist1 = radius * 10;
	float closestDist2 = radius * 10;
	//Find the three closest points
	for (int k = 0; k < 9; k++)
	{
		{
			float currentDist = distance(UV, points[k]);
			UNITY_FLATTEN
				if (closestDist1 > currentDist)
				{
					closestDist2 = closestDist1;
					closestDist1 = currentDist;
					closestPoint2 = closestPoint1;
					closestPoint1 = points[k];
				}
				else if (closestDist2 > currentDist)
				{
					closestDist2 = currentDist;
					closestPoint2 = points[k];
				}
		}
	}
	// Find the distance from the line from the midpoint between closest points 1 and 2, and the midpoint bectween closest points 1 and 3
	float2 linePoint1 = (closestPoint1 + closestPoint2) * 0.5;
	float2 linePointVector = normalize(closestPoint2 - closestPoint1);
	float distanceToLine = abs(dot(linePoint1 - UV, linePointVector));
	//return saturate(distanceToLine / radius);
	return saturate(distance(UV, closestPoint1) / radius);
}

#endif // NOISE_INCLUDED