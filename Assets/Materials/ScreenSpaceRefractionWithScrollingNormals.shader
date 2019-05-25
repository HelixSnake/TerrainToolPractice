// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "CustomVRChat/ScreenSpaceRefractionWithScrollingNormals"
{
	Properties
	{
		_Color("Base Color", Color) = (0,0,0,0)
		_Refraction("Refraction", Range(0.00, 10.0)) = 1.0
		_Power("Refraction Power", Range(1.00, 10.0)) = 1.0
		_AlphaPower("Vertex Alpha Power", Range(1.00, 10.0)) = 1.0
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Normal Map Height", Float) = 1.0
		_ScrollXSpeed("Normal X scroll speed", Range(-10, 10)) = 0
		_ScrollYSpeed("Normal Y scroll speed", Range(-10, 10)) = 0

		_RimColor("Rim Color", Color) = (0.0,0.0,0.0,0.0)
		_RimPower("Rim Edge Intensity", Range(0.1,10.0)) = 3.0

		_Cull("Face Culling", Int) = 2
	}

		SubShader
		{
			Tags { "Queue" = "Transparent+1" }

			GrabPass
			{
				"_GrabTexture"
			}

			Pass
			{
				Cull[_Cull]

				CGPROGRAM
					#pragma target 3.0
					#pragma vertex vert
					#pragma fragment frag
					#include "UnityCG.cginc"
					#include "UnityLightingCommon.cginc"
					#include "UnityStandardUtils.cginc"
					#include "UnityStandardInput.cginc"

			// From Valve's Lab Renderer, Copyright (c) Valve Corporation, All rights reserved. 
			float3 Vec3TsToWs(float3 vVectorTs, float3 vNormalWs, float3 vTangentUWs, float3 vTangentVWs)
			{
				float3 vVectorWs;
				vVectorWs.xyz = vVectorTs.x * vTangentUWs.xyz;
				vVectorWs.xyz += vVectorTs.y * vTangentVWs.xyz;
				vVectorWs.xyz += vVectorTs.z * vNormalWs.xyz;
				return vVectorWs.xyz; // Return without normalizing
			}

		// From Valve's Lab Renderer, Copyright (c) Valve Corporation, All rights reserved. 
		float3 Vec3TsToWsNormalized(float3 vVectorTs, float3 vNormalWs, float3 vTangentUWs, float3 vTangentVWs)
		{
			return normalize(Vec3TsToWs(vVectorTs.xyz, vNormalWs.xyz, vTangentUWs.xyz, vTangentVWs.xyz));
		}

		struct VS_INPUT
		{
			float4 vPosition : POSITION;
			float3 vNormal : NORMAL;
			//float2 vTexcoord0 : TEXCOORD0;
			float4 vTangentUOs_flTangentVSign : TANGENT;
			float4 vColor : COLOR;
		};
		
		struct PS_INPUT
		{
			float4 vGrabPos : TEXCOORD0;
			float4 vPos : SV_POSITION;
			///
			float4 vWorldPos : TEXCOORD5;
			///
			float4 vColor : COLOR;
			float2 vTexCoordX : TEXCOORD6;
			float2 vTexCoordY : TEXCOORD7;
			float2 vTexCoordZ : TEXCOORD8;
			float3 vNormalWs : TEXCOORD2;
			float3 vTangentXUWs : TEXCOORD3;
			float3 vTangentXVWs : TEXCOORD4;
			float3 vTangentYUWs : TEXCOORD9;
			float3 vTangentYVWs : TEXCOORD10;
			float3 vTangentZUWs : TEXCOORD11;
			float3 vTangentZVWs : TEXCOORD12;

			
		};

		

		sampler2D _GrabTexture;
		float _Refraction;
		float _Power;
		float _AlphaPower;

		float _ScrollXSpeed;
		float _ScrollYSpeed;

		float4 _RimColor;
		float _RimPower;

		float4 _BumpMap_ST;

		PS_INPUT vert(VS_INPUT i)
		{
			PS_INPUT o;


			// Clip space position
			o.vPos = UnityObjectToClipPos(i.vPosition);

			o.vWorldPos = mul(unity_ObjectToWorld, i.vPosition);
			///

			// Grab position
			o.vGrabPos = ComputeGrabScreenPos(o.vPos);

			// World space normal
			o.vNormalWs = UnityObjectToWorldNormal(i.vNormal);

			// Tangent
			//o.vTangentUWs.xyz = UnityObjectToWorldDir(i.vTangentUOs_flTangentVSign.xyz); // World space tangent
			//o.vTangentVWs.xyz = cross(o.vNormalWs.xyz, o.vTangentUWs.xyz) * i.vTangentUOs_flTangentVSign.w;
			o.vTangentXUWs.xyz = float3(0, 0, 1); // World space tangent
			o.vTangentXVWs.xyz = normalize(cross(o.vNormalWs.xyz, o.vTangentXUWs.xyz));
			o.vTangentXUWs.xyz = cross(o.vNormalWs.xyz, o.vTangentXVWs.xyz);

			o.vTangentYUWs.xyz = float3(0, 0, 1); // World space tangent
			o.vTangentYVWs.xyz = normalize(cross(o.vNormalWs.xyz, o.vTangentYUWs.xyz));
			o.vTangentYUWs.xyz = cross(o.vNormalWs.xyz, o.vTangentYVWs.xyz);

			o.vTangentZUWs.xyz = float3(1, 0, 0); // World space tangent
			o.vTangentZVWs.xyz = normalize(cross(o.vNormalWs.xyz, o.vTangentZUWs.xyz));
			o.vTangentZUWs.xyz = cross(o.vNormalWs.xyz, o.vTangentZVWs.xyz);

			// Texture coordinates
			o.vTexCoordX.xy = (o.vWorldPos.yz);
			o.vTexCoordY.xy = (o.vWorldPos.xz);
			o.vTexCoordZ.xy = (o.vWorldPos.xy);

			// Color
			o.vColor = i.vColor+_Color;
			//o.Albedo = _Color.rgb;


			return o;
		}

		float4 frag(PS_INPUT i) : SV_Target
		{
			fixed NormaloffsetX = _ScrollXSpeed * _Time;
			fixed NormaloffsetY = _ScrollYSpeed * _Time;
			fixed2 NormaloffsetUV = fixed2(NormaloffsetX, NormaloffsetY);
			float xFalloff = smoothstep(0.3f, 0.7f, abs(i.vNormalWs.x));
			float yFalloff = smoothstep(0.3f, 0.7f, abs(i.vNormalWs.y));
			float zFalloff = smoothstep(0.3f, 0.7f, abs(i.vNormalWs.z));
			//float xFalloff = abs(i.vNormalWs.x);
			//float yFalloff = abs(i.vNormalWs.y);
			//float zFalloff = abs(i.vNormalWs.z);
			// Tangent space normals
			float3 vNormalXTs1 = UnpackNormal(tex2D(_BumpMap, i.vTexCoordX.xy + NormaloffsetUV));
			vNormalXTs1.xy *= xFalloff;
			float3 vNormalYTs1 = UnpackNormal(tex2D(_BumpMap, i.vTexCoordY.xy + NormaloffsetUV * 1.051));
			vNormalYTs1.xy *= yFalloff;
			float3 vNormalZTs1 = UnpackNormal(tex2D(_BumpMap, i.vTexCoordZ.xy + NormaloffsetUV * 1.101));
			vNormalZTs1.xy *= zFalloff;
			float3 vNormalXTs2 = UnpackNormal(tex2D(_BumpMap, i.vTexCoordX.xy - NormaloffsetUV.yx * 1.151));
			vNormalXTs2.xy *= xFalloff;
			float3 vNormalYTs2 = UnpackNormal(tex2D(_BumpMap, i.vTexCoordY.xy - NormaloffsetUV.yx * 1.201));
			vNormalYTs2.xy *= yFalloff;
			float3 vNormalZTs2 = UnpackNormal(tex2D(_BumpMap, i.vTexCoordZ.xy - NormaloffsetUV.yx * 1.251));
			vNormalZTs2.xy *= zFalloff;
			float3 vNormalXTs, vNormalYTs, vNormalZTs;
			//vNormalTs.xy = vNormalXTs1.xy + vNormalYTs1.xy + vNormalZTs1.xy + vNormalXTs2.xy + vNormalYTs2.xy + vNormalZTs2.xy;
			//vNormalTs.z = vNormalXTs1.z * vNormalYTs1.z * vNormalZTs1.z * vNormalXTs2.z * vNormalYTs2.z * vNormalZTs2.z * 5;
			//vNormalTs = normalize(vNormalTs);
			vNormalXTs.xy = (vNormalXTs1.xy + vNormalXTs2.xy) * _BumpScale;
			vNormalYTs.xy = (vNormalYTs1.xy + vNormalYTs2.xy) * _BumpScale;
			vNormalZTs.xy = (vNormalZTs1.xy + vNormalZTs2.xy) * _BumpScale;
			vNormalXTs.z = vNormalXTs1.z * vNormalXTs2.z;
			vNormalYTs.z = vNormalYTs1.z * vNormalYTs2.z;
			vNormalZTs.z = vNormalZTs1.z * vNormalZTs2.z;
			vNormalXTs = normalize(vNormalXTs);
			vNormalYTs = normalize(vNormalYTs);
			vNormalZTs = normalize(vNormalZTs);

			// Tangent space -> World space
			float3 vNormalXWs = Vec3TsToWsNormalized(vNormalXTs.xyz, i.vNormalWs.xyz, i.vTangentXUWs, i.vTangentXVWs);
			float3 vNormalYWs = Vec3TsToWsNormalized(vNormalYTs.xyz, i.vNormalWs.xyz, i.vTangentYUWs, i.vTangentYVWs);
			float3 vNormalZWs = Vec3TsToWsNormalized(vNormalZTs.xyz, i.vNormalWs.xyz, i.vTangentZUWs, i.vTangentZVWs);
			float3 vNormalWs = normalize(vNormalXWs + vNormalYWs + vNormalZWs);

			// World space -> View space
			float3 vNormalVs = normalize(mul((float3x3)UNITY_MATRIX_V, vNormalWs));

			// Calculate offset
			float2 offset = vNormalVs.xy * _Refraction;
			offset *= pow(length(vNormalVs.xy), _Power);

			// Scale to pixel size
			offset /= float2(_ScreenParams.x, _ScreenParams.y);

			// Scale with screen depth
			offset /= i.vPos.z;

			// Scale with vertex alpha
			offset *= pow(i.vColor.a, _AlphaPower);

			//half rim = 1.0 - saturate(dot(normalize(vNormalVs), vNormalTs));
			half rim = 1.0 - saturate(dot(vNormalWs, normalize(_WorldSpaceCameraPos.xyz - i.vWorldPos.xyz)));
			float3 Emission = _RimColor.rgb * pow(rim, _RimPower);

			// Sample grab texture
			float4 vDistortColor = tex2Dproj(_GrabTexture, i.vGrabPos + float4(offset, 0.0, 0.0)) + float4(Emission,0.0) + _Color;

			// Debug normals
			// return float4(vNormalVs * 0.5 + 0.5, 1);

			return vDistortColor;
		}
	ENDCG
}
		}
}