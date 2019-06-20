Shader "Custom/PerlinNoise2"
{
	Properties
	{
		_Tess("Tessellation", Range(1,512)) = 4
		_Density("Density", Float) = 1.0
		_Radius("Radius", Float) = 1.0
		_Speed("Speed", Float) = 1.0
		_Octaves("Octaves", Int) = 8
		_FracMag("FractalMagnitude", Range(0, 1)) = 0.5
		_Distance("Distance", Float) = 1
		_Color1("Color 1", Color) = (1, 1, 1, 1)
		_Color2("Color 2", Color) = (0, 0, 0, 1)
		_Color3("Color 3", Color) = (0, 0, 0, 1)
	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" "Queue" = "Transparent" }
			LOD 200
			ZWrite On

			CGPROGRAM
			// Physically based Standard lighting model, and enable shadows on all light types
			#pragma surface surf Standard fullforwardshadows vertex:vert tessellate:tessDistance

			// Use shader model 3.0 target, to get nicer looking lighting
			#pragma target 4.6
			#include "Tessellation.cginc"
			#include "UnityCG.cginc"
			#include "../Shaders/Includes/Noise.cginc"

			float _Density;
			float _Radius;
			float _Speed;
			float _FracMag;
			float _Distance;
			float4 _Color1;
			float4 _Color2;
			float4 _Color3;
			int _Octaves;

			struct Input
			{
				float2 uv_MainTex;
				float4 screenPos;
				float3 worldPos;
				float3 worldRefl;
				float4 color : COLOR;
				INTERNAL_DATA
			};

			// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
			// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
			// #pragma instancing_options assumeuniformscaling
			UNITY_INSTANCING_BUFFER_START(Props)
				// put more per-instance properties here
			UNITY_INSTANCING_BUFFER_END(Props)

			float _Tess;

			float4 tessDistance(appdata_full v0, appdata_full v1, appdata_full v2) {
				float minDist = 0;
				float maxDist = 10.0;
				return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tess);
			}

			void vert(inout appdata_full v)
			{
				float3 worldScale = float3(
					length(float3(unity_ObjectToWorld[0].x, unity_ObjectToWorld[1].x, unity_ObjectToWorld[2].x)), // scale x axis
					length(float3(unity_ObjectToWorld[0].y, unity_ObjectToWorld[1].y, unity_ObjectToWorld[2].y)), // scale y axis
					length(float3(unity_ObjectToWorld[0].z, unity_ObjectToWorld[1].z, unity_ObjectToWorld[2].z))  // scale z axis
					);
				float4 worldpos = mul(unity_ObjectToWorld, v.vertex);
				float scaledTime = _Time.y * _Speed;
				float noiseImg = 0;
				float densityMult = 1;
				float magnitude = 1;
				int clampedOctaves = min(_Octaves, 30);
				for (int j = 0; j < clampedOctaves; j++)
				{
					noiseImg += abs(PerlinNoise4D(_Density * densityMult, _Radius, float4(worldpos.xyz, scaledTime)) * magnitude);
					densityMult *= 2;
					magnitude *= _FracMag;
				}
				//noiseImg = abs(0.5 - abs(noiseImg));
				noiseImg = saturate(noiseImg);
				v.vertex = normalize(v.vertex);
				v.vertex += float4(v.normal / worldScale, 0) * (noiseImg) * _Distance;
				v.color = lerp(_Color1, _Color2, noiseImg + 0.5);
				v.color = lerp(_Color3, v.color, saturate(1 - pow(1 - dot(normalize(_WorldSpaceCameraPos - worldpos), UnityObjectToWorldNormal(v.normal)), 1)));
			}

			void surf(Input IN, inout SurfaceOutputStandard o)
			{
				fixed4 col = fixed4(1, 1, 1, 1);
				//float noiseImg = PerlinNoise(_Density, _Radius, i.worldPos.xz);
				/*float scaledTime = _Time.y * _Speed;
				float noiseImg = 0;
				float densityMult = 1;
				float magnitude = 1;
				int clampedOctaves = min(_Octaves, 30);
				for (int j = 0; j < clampedOctaves; j++)
				{
					noiseImg += PerlinNoise4D(_Density * densityMult, _Radius, float4(IN.worldPos.xyz, scaledTime)) * magnitude;
					densityMult *= 2;
					magnitude *= _FracMag;
				}
				noiseImg = abs(noiseImg);
				noiseImg = saturate(noiseImg);*/
				col = IN.color;
				col.a = 1;
				UNITY_APPLY_FOG(i.fogCoord, col);
				o.Emission = col;
			}
			ENDCG
		}
}
