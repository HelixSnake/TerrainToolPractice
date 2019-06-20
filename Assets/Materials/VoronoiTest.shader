Shader "Unlit/VoronoiTest"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
		//_DistortMap("Distort Map", 2D) = "normal" {}
		//_DistortFactor("Distort Factor", Float) = 1.0
		_CellDensity("Cell Density", Float) = 1.0
		_Radius("Cell Radius", Float) = 3.0
		_Speed("Movement Speed", Float) = 1.0
		_Power("Power", Float) = 1.0
		_Octaves("Octaves", Int) = 8
		_FracMag("FractalMagnitude", Range(0, 1)) = 0.5
		[HDR]
		_Color1("Color 1", Color) = (1, 1, 1, 1)
		[HDR]
		_Color2("Color 2", Color) = (0, 0, 0, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
		Tags { "Queue" = "Transparent" }
        LOD 100

        Pass
        {

			Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
			#include "../Shaders/Includes/Noise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
				float4 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			sampler2D _DistortMap;
			float4 _DistortMap_ST;
			float _DistortFactor;
			float _CellDensity;
			float _Radius;
			float _Speed;
			float _Power;
			float _FracMag;
			float4 _Color1;
			float4 _Color2;
			int _Octaves;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
				fixed4 col = fixed4(1, 1, 1, 1);
				//float2 DistortMapUVs = i.worldPos.xz / 100 * _DistortMap_ST.xy + float2(_Time.x, _Time.x) * _DistortMap_ST.zw;
				//float2 VoronoiUVs = i.worldPos.xz;
				//float4 distortNormalRGB = tex2D(_DistortMap, DistortMapUVs);
				//float3 distortNormal = UnpackNormal(distortNormalRGB);
				//VoronoiUVs += distortNormal.xy * _DistortFactor;
				//float VoronoiImg = VoronoiNormalized(_CellDensity, VoronoiUVs, _Radius);
				//float VoronoiImg = VoronoiAnimated5x5Normalized(_CellDensity, VoronoiUVs, _Radius, _Speed, 0.8, 0.2);
				float VoronoiImg = 0;
				float densityMult = 1;
				float magnitude = 1;
				int clampedOctaves = min(_Octaves, 30);
				float newRadius = _Radius / _CellDensity;
				float divFactor = 0;
				for (int j = 0; j < clampedOctaves; j++)
				{
					VoronoiImg += (Voronoi4D(_CellDensity * densityMult, float4(i.worldPos.xyz, _Time.y * _Speed), newRadius / densityMult) - 0.5) * magnitude;
					divFactor += densityMult;
					densityMult *= 2;
					magnitude *= _FracMag;
				}
				VoronoiImg = saturate((VoronoiImg+0.5));
				col = lerp(_Color1, _Color2, pow(VoronoiImg, _Power));
				//float2 grid = smoothstep(float2(0, 0), float2(0.05, 0.05), abs(frac(VoronoiUVs * _CellDensity) - float2(0.05, 0.05)));
				//col.rgb *= grid.x * grid.y;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
