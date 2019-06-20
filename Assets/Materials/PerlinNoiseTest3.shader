Shader "Custom/PerlinNoise3"
{
	Properties
	{
		_Tess("Tessellation", Range(1,512)) = 4
		_Density("Density", Float) = 1.0
		_Radius("Radius", Float) = 1.0
		_Speed("Speed", Float) = 1.0
		_Scale("Scale", Vector) = (1, 1, 1, 1)
		_Octaves("Octaves", Int) = 8
		_FracMag("FractalMagnitude", Range(0, 1)) = 0.5
			[HDR]
		_Color1("Color 1", Color) = (1, 1, 1, 1)
			[HDR]
		_Color2("Color 2", Color) = (0, 0, 0, 1)
		_Color3("Color 3", Color) = (0, 0, 0, 1)
		_RepeatAmt("Repeat Amount", Float) = 2.0
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" "Queue" = "Transparent" }
			LOD 200
			ZWrite On

			CGPROGRAM
			// Physically based Standard lighting model, and enable shadows on all light types
			#pragma surface surf Standard fullforwardshadows vertex:vert

			// Use shader model 3.0 target, to get nicer looking lighting
			#pragma target 4.6
			#include "Tessellation.cginc"
			#include "UnityCG.cginc"
			#include "../Shaders/Includes/Noise.cginc"

			float _Density;
			float _Radius;
			float _Speed;
			float _RepeatAmt;
			float4 _Scale;
			float4 _Color1;
			float4 _Color2;
			float4 _Color3;
			half _Glossiness;
			half _Metallic;

			struct Input
			{
				float3 objPos;
				float2 uv_MainTex;
				float4 screenPos;
				float3 worldPos;
				float3 worldScale;
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

			void vert(inout appdata_full v, out Input o) {
				UNITY_INITIALIZE_OUTPUT(Input, o);
				o.objPos = v.vertex;
				o.worldScale = float3(
					length(float3(unity_ObjectToWorld[0].x, unity_ObjectToWorld[1].x, unity_ObjectToWorld[2].x)), // scale x axis
					length(float3(unity_ObjectToWorld[0].y, unity_ObjectToWorld[1].y, unity_ObjectToWorld[2].y)), // scale y axis
					length(float3(unity_ObjectToWorld[0].z, unity_ObjectToWorld[1].z, unity_ObjectToWorld[2].z))  // scale z axis
					);
			}

			void surf(Input IN, inout SurfaceOutputStandard o)
			{
				fixed4 col = fixed4(1, 1, 1, 1);
				//float noiseImg = PerlinNoise(_Density, _Radius, i.worldPos.xz);
				float scaledTime = _Time.y * _Speed;
				float finalValue = 0;
				float noiseImg = PerlinNoise4D(_Density, _Radius, float4(IN.objPos.xyz * _Scale.xyz * IN.worldScale, scaledTime));
				float fracNoise = frac(noiseImg * _RepeatAmt) - 0.05;
				noiseImg = abs(fracNoise)*(step(fracNoise, 0) * 19 + 1);
				noiseImg += PerlinNoise4D(_Density * 100, _Radius, float4(IN.objPos.xyz * _Scale.xyz * IN.worldScale, scaledTime));
				noiseImg += PerlinNoise4D(_Density * 200, _Radius, float4(IN.objPos.xyz * _Scale.xyz * IN.worldScale, scaledTime))*0.7;
				//noiseImg += PerlinNoise4D(_Density * 400, _Radius, float4(IN.objPos.xyz * _Scale.xyz, scaledTime))*0.4;
				noiseImg = saturate(noiseImg);
				col = lerp(_Color1, _Color2, noiseImg);
				col.a = 1;
				UNITY_APPLY_FOG(i.fogCoord, col);
				o.Albedo = col;
				o.Metallic = _Metallic;
				o.Smoothness = _Glossiness;
			}
			ENDCG
		}
}
