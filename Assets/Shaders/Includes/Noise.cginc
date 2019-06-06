#ifndef VORONOI_INCLUDED
#define VORONOI_INCLUDED

#include "Random.cginc"

inline float PerlinNoise(float density, float radius, float2 UV)
{
	float oneDivDensity = 1.0 / density;
	float halfOneDivDens = oneDivDensity * 0.5;
	float2 upperLeftCorner = floor(UV * density);
	float finalValue = 0;
	for (int i = 0; i < 2; i++)
	{
		for (int j = 0; j < 2; j++)
		{
			float2 cornerPos = upperLeftCorner + float2(i, j);
			float2 cornerValue = normalize(hash22(cornerPos) - float2(0.5, 0.5));
			float2 cornerVect = UV - cornerPos * oneDivDensity;
			float value = dot(cornerValue, cornerVect * density / radius);
			finalValue += smoothstep(oneDivDensity, 0, length(cornerVect)) * value;
		}
	}
	return saturate((finalValue + 1) / 2);
}

inline float PerlinNoise3D(float density, float radius, float3 pos)
{
	float oneDivDensity = 1.0 / density;
	float halfOneDivDens = oneDivDensity * 0.5;
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
				float value = dot(cornerValue, cornerVect * density / radius);
				finalValue += smoothstep(oneDivDensity, 0, length(cornerVect)) * value;
			}
		}
	}
	return saturate((finalValue + 1) / 2);
}

inline float PerlinNoise4D(float density, float radius, float4 pos)
{
	float oneDivDensity = 1.0 / density;
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
					float value = dot(cornerValue, cornerVect * density / radius);
					finalValue += smoothstep(oneDivDensity, 0, length(cornerVect)) * value;
				}
			}
		}
	}
	return saturate((finalValue + 1) / 2);
}

inline float Voronoi(float cellDensity, float2 UV, float radius)
{
	float oneDivCellDensity = 1.0 / cellDensity;
	float minDistance = radius;
	for (int i = 0; i < 3; i++)
	{
		for (int j = 0; j < 3; j++)
		{
			int2 cell = floor(UV * cellDensity) + int2(i-1, j-1);
			float2 cellValue = hash22(cell);
			cellValue = (cellValue + (float2)cell) * oneDivCellDensity;
			minDistance = min(minDistance, distance(UV, cellValue));
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
			float2 cellValue = hash22(cell) * 0.7f;
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

#endif // VORONOI_INCLUDED