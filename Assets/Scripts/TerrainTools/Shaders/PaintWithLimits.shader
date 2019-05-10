Shader "CustomTerrainTools/PaintWithLimits"
{
	Properties{ _MainTex("Texture", any) = "" {} }

	SubShader{

		ZTest Always Cull Off ZWrite Off

		CGINCLUDE

			#include "UnityCG.cginc"
			#include "TerrainTool.cginc"

			sampler2D _MainTex;
			sampler2D _TerrainNormals;
			sampler2D _TerrainHeights;
			float _TerrainMaxHeight;
			float4 _MainTex_TexelSize;      // 1/width, 1/height, width, height

			sampler2D _BrushTex;

			float4 _BrushParams;
			float4 _BrushParams2;
			#define BRUSH_MINHEIGHT      (_BrushParams[0])
			#define BRUSH_MAXHEIGHT  (_BrushParams[1])
			#define BRUSH_MINHEIGHTFALLOFF  (_BrushParams[2])
			#define BRUSH_MAXHEIGHTFALLOFF  (_BrushParams[3])

			#define BRUSH_MINANGLE      (_BrushParams2[0])
			#define BRUSH_MAXANGLE  (_BrushParams2[1])
			#define BRUSH_MINANGLEFALLOFF  (_BrushParams2[2])
			#define BRUSH_MAXANGLEFALLOFF  (_BrushParams2[3])

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

			float ApplyBrush(float height, float brushStrength)
			{
				float targetHeight = 1.0; // This is just a texture painter, this value is always 1.0
				if (targetHeight > height)
				{
					height += brushStrength;
					height = height < targetHeight ? height : targetHeight;
				}
				else
				{
					height -= brushStrength;
					height = height > targetHeight ? height : targetHeight;
				}
				return height;
			}

		ENDCG
		Pass    // 0
		{
			Name "Paint Texture With Limits"

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment PaintSplatAlphamap

			float4 PaintSplatAlphamap(v2f i) : SV_Target
			{
				float2 brushUV = PaintContextUVToBrushUV(i.pcUV);
				float2 heightmapUV = PaintContextUVToHeightmapUV(i.pcUV);

				float angle = acos(dot(UnpackNormal(tex2D(_TerrainNormals, heightmapUV)), float3(0, 1, 0)));
				float height = UnpackHeightmap(tex2D(_TerrainHeights, heightmapUV)) * _TerrainMaxHeight;

				float alpha = 1.0;
				alpha *= smoothstep(BRUSH_MINHEIGHT - BRUSH_MINHEIGHTFALLOFF, BRUSH_MINHEIGHT, height);
				alpha *= 1 - smoothstep(BRUSH_MAXHEIGHT, BRUSH_MAXHEIGHT + BRUSH_MAXHEIGHTFALLOFF, height);

				alpha *= smoothstep(BRUSH_MINANGLE - BRUSH_MINANGLEFALLOFF, BRUSH_MINANGLE, angle);
				alpha *= 1 - smoothstep(BRUSH_MAXANGLE, BRUSH_MAXANGLE + BRUSH_MAXANGLEFALLOFF, angle);

				// out of bounds multiplier
				float oob = all(saturate(brushUV) == brushUV) ? 1.0f : 0.0f;

				float brushStrength = oob * UnpackHeightmap(tex2D(_BrushTex, brushUV)) * alpha;
				float alphaMap = tex2D(_MainTex, i.pcUV).r;
				return brushStrength;
			}

			ENDCG
		}
	}
	Fallback Off
}
