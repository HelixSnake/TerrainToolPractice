#ifndef RANDOM_INCLUDED
#define RANDOM_INCLUDED

// Hash without Sine
// Creative Commons Attribution-ShareAlike 4.0 International Public License
// Created by David Hoskins.

// https://www.shadertoy.com/view/4djSRW
// Trying to find a Hash function that is the same on all systems
// and doesn't rely on trigonometry functions that lose accuracy with high values. 
// New one on the left, sine function on the right.

// *NB: This is for integer scaled floats only! i.e. Standard noise functions.
// MODIFICATION: Converted to CG

#define ITERATIONS 4

//----------------------------------------------------------------------------------------
//  1 out, 1 in...
float hash11(float p)
{
	p = frac(p * .1031);
	p *= p + 19.19;
	p *= p + p;
	return frac(p);
}

//----------------------------------------------------------------------------------------
//  1 out, 2 in...
float hash12(float2 p)
{
	float3 p3 = frac(float3(p.xyx) * .1031);
	p3 += dot(p3, p3.yzx + 19.19);
	return frac((p3.x + p3.y) * p3.z);
}

//----------------------------------------------------------------------------------------
//  1 out, 3 in...
float hash13(float3 p3)
{
	p3 = frac(p3 * .1031);
	p3 += dot(p3, p3.yzx + 19.19);
	return frac((p3.x + p3.y) * p3.z);
}

//----------------------------------------------------------------------------------------
//  2 out, 1 in...
float2 hash21(float p)
{
	float3 p3 = frac(p.xxx * float3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx + 19.19);
	return frac((p3.xx + p3.yz)*p3.zy);

}

//----------------------------------------------------------------------------------------
///  2 out, 2 in...
float2 hash22(float2 p)
{
	float3 p3 = frac(float3(p.xyx) * float3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx + 19.19);
	return frac((p3.xx + p3.yz)*p3.zy);

}

//----------------------------------------------------------------------------------------
///  2 out, 3 in...
float2 hash23(float3 p3)
{
	p3 = frac(p3 * float3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx + 19.19);
	return frac((p3.xx + p3.yz)*p3.zy);
}

//----------------------------------------------------------------------------------------
//  3 out, 1 in...
float3 hash31(float p)
{
	float3 p3 = frac(p.xxx * float3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx + 19.19);
	return frac((p3.xxy + p3.yzz)*p3.zyx);
}


//----------------------------------------------------------------------------------------
///  3 out, 2 in...
float3 hash32(float2 p)
{
	float3 p3 = frac(float3(p.xyx) * float3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yxz + 19.19);
	return frac((p3.xxy + p3.yzz)*p3.zyx);
}

//----------------------------------------------------------------------------------------
///  3 out, 3 in...
float3 hash33(float3 p3)
{
	p3 = frac(p3 * float3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yxz + 19.19);
	return frac((p3.xxy + p3.yxx)*p3.zyx);

}

//----------------------------------------------------------------------------------------
// 4 out, 1 in...
float4 hash41(float p)
{
	float4 p4 = frac(p.xxxx * float4(.1031, .1030, .0973, .1099));
	p4 += dot(p4, p4.wzxy + 19.19);
	return frac((p4.xxyz + p4.yzzw)*p4.zywx);

}

//----------------------------------------------------------------------------------------
// 4 out, 2 in...
float4 hash42(float2 p)
{
	float4 p4 = frac(float4(p.xyxy) * float4(.1031, .1030, .0973, .1099));
	p4 += dot(p4, p4.wzxy + 19.19);
	return frac((p4.xxyz + p4.yzzw)*p4.zywx);

}

//----------------------------------------------------------------------------------------
// 4 out, 3 in...
float4 hash43(float3 p)
{
	float4 p4 = frac(float4(p.xyzx)  * float4(.1031, .1030, .0973, .1099));
	p4 += dot(p4, p4.wzxy + 19.19);
	return frac((p4.xxyz + p4.yzzw)*p4.zywx);
}

//----------------------------------------------------------------------------------------
// 4 out, 4 in...
float4 hash44(float4 p4)
{
	p4 = frac(p4  * float4(.1031, .1030, .0973, .1099));
	p4 += dot(p4, p4.wzxy + 19.19);
	return frac((p4.xxyz + p4.yzzw)*p4.zywx);
}

/*
inline float RandFloatFromInt(int input)
{
	return frac(sin(dot(float2(input * 0.00001526, input * 0.00001526), float2(12.9898, 78.233)))*43758.5453123);
}

inline float RandFloatFromInt2(int2 input)
{
	return frac(sin(dot(float2(input.x * 0.00001526, input.y * 0.00001526), float2(12.9898, 78.233)))*43758.5453123);
}
inline float2 RandFloat2FromInt(int input)
{
	float2 randFloat;
	randFloat.x = frac(sin(dot(float2(input * 0.00001526, input * 0.00001526), float2(12.9898, 78.233)))*43758.5453123);
	randFloat.y = frac(sin(dot(float2(randFloat.x, randFloat.x), float2(12.9898, 78.233)))*43758.5453123);
	return randFloat;
}

inline float2 RandFloat2FromInt2(int2 input)
{
	float2 randFloat;
	randFloat.x = frac(sin(dot(float2(input.x * 0.00001526, input.y * 0.00001526), float2(12.9898, 78.233)))*43758.5453123);
	randFloat.y = frac(cos(dot(float2(input.y * 0.00002520, input.x * 0.00002520), float2(12.9898, 78.233)))*43758.5453123);
	return randFloat;
}*/

#endif // RANDOM_INCLUDED