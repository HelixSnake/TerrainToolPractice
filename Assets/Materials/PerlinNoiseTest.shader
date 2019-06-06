Shader "Unlit/PerlinNoiseTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Density("Density", Float) = 1.0
		_Radius("Radius", Float) = 1.0
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
				float noiseImg = PerlinNoise4D(_Density, _Radius, float4(i.worldPos.xyz, _Time.y * 10));
				col = noiseImg;
				col.a = 1;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
