Shader "Unlit/VoronoiTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_DistortMap("Distort Map", 2D) = "normal" {}
		_DistortFactor("Distort Factor", Float) = 1.0
		_CellDensity("Cell Density", Float) = 1.0
		_Radius("Cell Radius", Float) = 3.0
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
			#include "../Shaders/Includes/Voronoi.cginc"

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
				float2 DistortMapUVs = i.worldPos.xz / 100 + float2(_Time.x, _Time.x) * 3;
				float2 VoronoiUVs = i.worldPos.xz;
				float4 distortNormalRGB = tex2D(_DistortMap, DistortMapUVs);
				float3 distortNormal = UnpackNormal(distortNormalRGB);
				VoronoiUVs += distortNormal.xy * _DistortFactor;
				//float VoronoiImg = VoronoiNormalized(_CellDensity, VoronoiUVs, _Radius);
				float VoronoiImg = VoronoiAnimated(_CellDensity, VoronoiUVs, _Radius, 20);
				col = VoronoiImg * VoronoiImg;
				//col.a = 1;
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
