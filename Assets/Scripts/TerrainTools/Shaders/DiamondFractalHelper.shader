Shader "CustomTerrainTools/TerrainToolDiamondFractalHelper" {

Properties{ _MainTex("Texture", any) = "" {} }

	SubShader{

		ZTest Always Cull Off ZWrite Off

		CGINCLUDE

			#include "UnityCG.cginc"
			#include "TerrainTool.cginc"

			sampler2D _MainTex;
			float4 _MainTex_TexelSize;      // 1/width, 1/height, width, height

			sampler2D _BrushTex;

			float4 _BrushParams;
			#define BRUSH_STRENGTH      (_BrushParams[0])

			struct appdata_t {
				float4 vertex : POSITION;
				float2 pcUV : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				float2 pcUV : TEXCOORD0;
			};

			v2f vert(appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.pcUV = v.pcUV;
				return o;
			}

		ENDCG
		Pass    // 0 stamp heights
		{
			Name "Stamp Heights With Replacement"

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment StampHeight

			#define BRUSH_OPACITY       (_BrushParams[0])
			#define BRUSH_ADDEDHEIGHT   (_BrushParams[1])
			#define BRUSH_STAMPHEIGHT   (_BrushParams[2])
			#define BRUSH_ALPHAFADE     (_BrushParams[3])

			float4 StampHeight(v2f i) : SV_Target
			{
				float2 brushUV = PaintContextUVToBrushUV(i.pcUV);
				float2 heightmapUV = PaintContextUVToHeightmapUV(i.pcUV);

				// out of bounds multiplier
				float oob = all(saturate(brushUV) == brushUV) ? 1.0f : 0.0f;

				float height = UnpackHeightmap(tex2D(_MainTex, heightmapUV));
				float brushShape = UnpackHeightmap(tex2D(_BrushTex, brushUV));
				float brushHeight = brushShape * BRUSH_STAMPHEIGHT + BRUSH_ADDEDHEIGHT;
				float alpha = 1;
				alpha *= smoothstep(0, BRUSH_ALPHAFADE, brushUV.x);
				alpha *= 1 -smoothstep(1 - BRUSH_ALPHAFADE, 1, brushUV.x);
				alpha *= smoothstep(0, BRUSH_ALPHAFADE, brushUV.y);
				alpha *= 1 - smoothstep(1 - BRUSH_ALPHAFADE, 1, brushUV.y);

				float targetHeight = lerp (height, brushHeight, alpha);
				targetHeight = clamp(targetHeight, 0.0f, 0.5f);          // Keep in valid range (0..0.5)
				return PackHeightmap(targetHeight);
			}
			ENDCG
		}
		Pass    // 1 Transmit Height To Texture
		{
			Name "Transmit Height To Texture"

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment TransmitHeight

			#define BRUSH_STAMPHEIGHT   (_BrushParams[2])

			float4 TransmitHeight(v2f i) : SV_Target
			{
				float2 heightmapUV = PaintContextUVToHeightmapUV(i.pcUV);

				float height = UnpackHeightmap(tex2D(_MainTex, heightmapUV));

				return height / BRUSH_STAMPHEIGHT;
			}
			ENDCG
		}

	}
	Fallback Off
}