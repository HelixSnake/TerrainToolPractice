Shader "Unlit/PerlinNoiseTest2D"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
		_Density("Density", Float) = 1.0
		_Radius("Radius", Float) = 1.0
		_Speed("Speed", Float) = 1.0
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
			float _Density;
			float _Radius;
			float _Speed;
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
				//float noiseImg = PerlinNoise(_Density, _Radius, i.worldPos.xz);
				float scaledTime = _Time.y * _Speed;
				float noiseImg = 0;
				float densityMult = 1;
				float magnitude = 1;
				int clampedOctaves = min(_Octaves, 30);
				float3(i.worldPos.x, i.worldPos.y, scaledTime);
				for (int j = 0; j < clampedOctaves; j++)
				{
					noiseImg += PerlinNoise4D(_Density * densityMult, _Radius, float4(i.worldPos.x, i.worldPos.y + scaledTime, i.worldPos.z, scaledTime)) * magnitude;
					densityMult *= 2;
					magnitude *= _FracMag;
				}
				noiseImg = (noiseImg + 1) / 2;
				noiseImg = saturate(noiseImg);
				col = lerp(_Color1, _Color2, noiseImg);
				col.a = 1;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
