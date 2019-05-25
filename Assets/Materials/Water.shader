Shader "Custom/Water"
{
    Properties
    {
		_Tess("Tessellation", Range(1,512)) = 4
		_WaveNoiseMap("Wave Noise Height Map", 2D) = "white" {}
		_WaveNoiseNormMap("Wave Noise Normal Map", 2D) = "normal" {}
        _Color ("Color", Color) = (1,1,1,1)
		_EdgeGlow("EdgeGlow", Color) = (1,1,1,1)
		_ReflectionColor("Reflection Color", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_NormalMap ("Normal Map", 2D) = "normal" {}
		_Cube("Cubemap", CUBE) = "" {}
		_NormalHeight("Normal Height", Float) = 1.0
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
		_InvFade("Fade Factor", Range(0.01,3.0)) = 1.0
		_AlphaFade("Alpha Fade Factor", Range(0.01,3.0)) = 1.0
		_Speed("Speed", Float) = 1.0
		_Refraction("Refraction Amount", Float) = 10.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Transparent" }
        LOD 200
		ZWrite On

		GrabPass {
			Name "WaterGrab"
		}

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert tessellate:tessDistance alpha:blend

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 4.6
		 #include "Tessellation.cginc"
		#include "UnityCG.cginc"


        sampler2D _MainTex;
		sampler2D _NormalMap;
		sampler2D _WaveNoiseMap;
		sampler2D _WaveNoiseNormMap;
		sampler2D _GrabTexture;
		float4 _GrabTexture_TexelSize;
		samplerCUBE _Cube;
		float _NormalHeight;

        struct Input
        {
            float2 uv_MainTex; 
			float4 screenPos;
			float3 worldPos;
			float3 worldRefl;
			INTERNAL_DATA
        };

        half _Glossiness;
        half _Metallic;
		half _InvFade;
		half _AlphaFade;
		half _Speed;
		half _Refraction;
        fixed4 _Color;
		fixed4 _EdgeGlow;
		fixed4 _ReflectionColor;
		UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

		float _Tess;

		float4 tessDistance(appdata_full v0, appdata_full v1, appdata_full v2) {
			float minDist = 500.0;
			float maxDist = 2000.0;
			return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tess);
		}

		void vert (inout appdata_full v)
        {
			float time = _Time.x * 0.5;
			float4 worldposv = mul(unity_ObjectToWorld, v.vertex);
			float noiseOffset1 = tex2Dlod(_WaveNoiseMap, float4(worldposv.xz * 0.001 + time.xx, 0, 1));
			float noiseOffset2 = tex2Dlod(_WaveNoiseMap, float4(-worldposv.zx * 0.001 - time.xx, 0, 1));
			float noiseOffset3 = tex2Dlod(_WaveNoiseMap, float4(-worldposv.xz * 0.001 + float2(time.x, -time.x), 0, 1));
			float noiseOffset4 = tex2Dlod(_WaveNoiseMap, float4(worldposv.zx * 0.001 - float2(time.x, -time.x), 0, 1));
			float noiseOffset = (noiseOffset1 + noiseOffset2 + noiseOffset3 + noiseOffset4) * 5;

			v.vertex += mul(unity_WorldToObject, float4(0, noiseOffset, 0, 0));
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			float sceneZ = LinearEyeDepth(tex2D(_CameraDepthTexture, IN.screenPos.xy / IN.screenPos.w));
			float partZ = LinearEyeDepth(IN.screenPos.z / IN.screenPos.w);
			float fade = saturate(_InvFade * (sceneZ - partZ));
			float alphaFade = saturate(_AlphaFade * (sceneZ - partZ));
			//float whitefade = 0;
            // Albedo comes from a texture tinted by color
			float2 uvs = IN.worldPos.xz / 100;
            fixed4 c = tex2D (_MainTex, uvs) * _Color;
            o.Albedo = lerp(float3(1, 1, 1), c.rgb, alphaFade);
            // Metallic and smoothness come from slider variables
            o.Metallic = lerp(0, _Metallic, alphaFade);
            o.Smoothness = _Glossiness;
            o.Alpha = alphaFade;
			float time = _Time.y * _Speed;
			float noisetime = _Time.x * 0.5;

			// normals from vertex offset noise
			float3 noiseNormal1 = UnpackNormal(tex2Dlod(_WaveNoiseNormMap, float4(IN.worldPos.xz * 0.001 + noisetime.xx, 0, 1)));
			float3 noiseNormal2 = UnpackNormal(tex2Dlod(_WaveNoiseNormMap, float4(-IN.worldPos.zx * 0.001 - noisetime.xx, 0, 1)));
			float3 noiseNormal3 = UnpackNormal(tex2Dlod(_WaveNoiseNormMap, float4(-IN.worldPos.xz * 0.001 + float2(noisetime.x, -noisetime.x), 0, 1)));
			float3 noiseNormal4 = UnpackNormal(tex2Dlod(_WaveNoiseNormMap, float4(IN.worldPos.zx * 0.001 - float2(noisetime.x, -noisetime.x), 0, 1)));
			float3 noiseNormal;
			noiseNormal.xy = (noiseNormal1.xy + noiseNormal2.xy + noiseNormal3.xy + noiseNormal4.xy) * 0.1;
			noiseNormal.z = (noiseNormal1.z * noiseNormal2.z * noiseNormal3.z * noiseNormal4.z);
			noiseNormal = normalize(noiseNormal);

			float3 normal1 = UnpackNormal(tex2D(_NormalMap, uvs + float2(1.5, time * 0.6)));
			float3 normal2 = UnpackNormal(tex2D(_NormalMap, uvs * float2(1.05, 1.05) + float2(1.3, -time * 0.61)));
			float3 normal3 = UnpackNormal(tex2D(_NormalMap, uvs * float2(1.1, 1.1) + float2(time * 0.62, 1.3)));
			float3 normal4 = UnpackNormal(tex2D(_NormalMap, uvs * float2(1.15, 1.15) + float2(-time * 0.63, 1.5)));
			float3 normal5 = UnpackNormal(tex2D(_NormalMap, uvs * float2(2.2, 2.2) + float2(1.5, time * 0.41)));
			float3 normal6 = UnpackNormal(tex2D(_NormalMap, uvs * float2(2.25, 2.25) + float2(1.3, -time * 0.42)));
			float3 normal7 = UnpackNormal(tex2D(_NormalMap, uvs * float2(2.3, 2.3) + float2(time * 0.43, 1.3)));
			float3 normal8 = UnpackNormal(tex2D(_NormalMap, uvs * float2(2.35, 2.35) + float2(-time * 0.44, 1.5)));
			o.Normal.xy = (normal1.xy + normal2.xy + normal3.xy + normal4.xy + normal5.xy + normal6.xy + normal7.xy + normal8.xy) * fade * _NormalHeight;
			o.Normal.z = normal1.z * normal2.z * normal3.z * normal4.z * normal5.z * normal6.z * normal7.z * normal8.z;
			o.Normal = normalize(o.Normal);
			o.Normal.xy += noiseNormal.xy;
			o.Normal.z *= noiseNormal.z;
			o.Normal = normalize(o.Normal);
			float3 viewDir = UNITY_MATRIX_IT_MV[2].xyz;

			float2 offset = o.Normal.xy * _Refraction; 
			offset /= float2(_ScreenParams.x, _ScreenParams.y);
			//offset /= float2(_ScreenParams.x, _ScreenParams.y);
			float2 newUVs = (IN.screenPos.xy / IN.screenPos.w + offset / partZ);
			sceneZ = LinearEyeDepth(tex2D(_CameraDepthTexture, newUVs.xy));
			float whitefade = saturate(_InvFade * 0.9 * (sceneZ - partZ));

			o.Emission = texCUBE(_Cube, WorldReflectionVector(IN, o.Normal)).rgb * (1 - dot(o.Normal, -viewDir)) * _ReflectionColor;
			o.Albedo.rgb = lerp(float3(0,0,0), o.Albedo.rgb, whitefade);
			o.Emission = lerp(tex2D(_GrabTexture, newUVs.xy), o.Emission, whitefade);
			o.Emission += lerp(_EdgeGlow, float3(0, 0, 0), whitefade);
        }
        ENDCG
    }
}
