Shader "Custom/VoronoiTest2Surf"
{
    Properties
    {
		_CellDensity("Cell Density", Float) = 1.0
		_Radius("Cell Radius", Float) = 3.0
		[HDR]
		_Color1("Color 1", Color) = (1, 1, 1, 1)
		[HDR]
		_Color2("Color 2", Color) = (0, 0, 0, 1)
		_NormalHeight("NormalHeight", Float) = 1
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

		#include "../Shaders/Includes/Noise.cginc"

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
			float3 worldPos;
        };

		float _CellDensity;
		float _Radius;
		float _Speed;
		float _Power;
		float _FracMag;
		float _NormalHeight;
		float4 _Color1;
		float4 _Color2;
        half _Glossiness;
        half _Metallic;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
			float VoronoiImg = 0;
			float newRadius = _Radius / _CellDensity;
			float divFactor = 0;
			float2 dir;
			VoronoiImg = saturate(VoronoiNormalized2(_CellDensity, IN.worldPos.xy, newRadius, dir));
			//VoronoiImg += (1 - VoronoiCornerTest(_CellDensity, IN.uv_MainTex, newRadius / 10));
			float4 c = lerp(_Color1, _Color2, VoronoiImg);
			//float2 grid = smoothstep(float2(0, 0), float2(0.05, 0.05), abs(frac(IN.uv_MainTex * _CellDensity + float2(0.05, 0.05)) - float2(0.05, 0.05)));
			//c.rgb *= max(grid.x * grid.y, 0.5);
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
			o.Normal = normalize(float3(dir, 1/max(_NormalHeight, 0.0001)));
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
