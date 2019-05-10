Shader "Custom/StandardWithSnow"
{
    Properties
    {
        _Color ("Main Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_SnowColor("Snow Color", Color) = (1,1,1,1)
		_SnowTex("Snow Texture (RGB)", 2D) = "white" {}
		_DogTex("Dog Texture", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
		_SnowMinHeight("Snow Min Height", Float) = 0.0
		_SnowMaxSlope("Cosine of Max Slope Angle", Float) = 0.707
		_SnowFalloff("Snow Height Falloff", Float) = 0.5
		_SnowAngleFalloff("Snow Angle Falloff", Float) = 0.1
		_DogAmount("Amount Of Dog", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		static const int4x4 DITHERING_MATRIX = int4x4(1,9,3,11,13,5,15,7,4,12,2,10,16,8,14,6); //dithering matrix
        sampler2D _MainTex;
		sampler2D _SnowTex;
		sampler2D _DogTex;

        struct Input
        {
            float2 uv_MainTex;
			float3 worldNormal;
			float3 worldPos;
			float4 screenPos;
			float3 viewDir;
        };

        half _Glossiness;
        half _Metallic;
		float _SnowMinHeight;
		float _SnowMaxSlope;
		float _SnowFalloff;
		float _SnowAngleFalloff;
		float _DogAmount;
        fixed4 _Color;
		fixed4 _SnowColor;
        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			fixed4 c2 = tex2D (_SnowTex, IN.uv_MainTex) * _SnowColor;
			float snowHeightAmount = smoothstep(_SnowMinHeight - _SnowFalloff, _SnowMinHeight, IN.worldPos.y);

			float snowAngleAmount = smoothstep(_SnowMaxSlope - _SnowAngleFalloff, _SnowMaxSlope, dot(IN.worldNormal, float3(0, 1, 0)));

			float snowTotalAmount = snowHeightAmount * snowAngleAmount;

			o.Albedo = c.rgb * (1 - snowTotalAmount) + c2.rgb * snowTotalAmount;
			float newDogAmount = _DogAmount * dot(IN.viewDir, IN.worldNormal);

			//ordered dithering code because I feel like doing something fancy
			uint2 newDogPixelDither = (uint2)(IN.screenPos.xy / IN.screenPos.w * _ScreenParams.xy);
			newDogPixelDither = uint2(newDogPixelDither.x % 4, newDogPixelDither.y % 4);
			newDogAmount = step(DITHERING_MATRIX[newDogPixelDither.x][newDogPixelDither.y], ceil(newDogAmount * 16));

			o.Albedo = o.Albedo * (1 - newDogAmount) + tex2D(_DogTex, (IN.screenPos.xy) / IN.screenPos.w) * newDogAmount * dot(IN.viewDir, IN.worldNormal);
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
