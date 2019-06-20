#ifndef HELPER_INCLUDED
#define HELPER_INCLUDED

inline float invlerp(float a, float b, float x)
{
	return (x - a) / (b - a);
}

inline float2 invlerp(float2 a, float2 b, float2 x)
{
	return (x - a) / (b - a);
}

inline float3 invlerp(float3 a, float3 b, float3 x)
{
	return (x - a) / (b - a);
}

inline float4 invlerp(float4 a, float4 b, float4 x)
{
	return (x - a) / (b - a);
}

#endif // HELPER_INCLUDED