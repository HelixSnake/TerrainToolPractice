using UnityEngine;
using UnityEditor;
using System;
using UnityEngine.Experimental.TerrainAPI;
using UnityEditor.ShortcutManagement;

namespace UnityEditor.Experimental.TerrainAPI
{
    public class TerrainToolPaintLimits : TerrainPaintTool<TerrainToolPaintLimits>
    {

        float _minHeight;
        float _maxHeight;
        float _minHeightFalloff;
        float _maxHeightFalloff;
        float _minAngle;
        float _maxAngle;
        float _minAngleFalloff;
        float _maxAngleFalloff;

        Material m_Material = null;
        Editor m_TemplateMaterialEditor = null;
        Editor m_SelectedTerrainLayerInspector = null;

        [SerializeField]
        TerrainLayer m_SelectedTerrainLayer = null;

        public override string GetName()
        {
            return "Paint Texture With Restraints";
        }

        public override string GetDesc()
        {
            return "Left click to paint.";
        }

        Material GetPaintMaterial()
        {
            if (m_Material == null)
                m_Material = new Material(Shader.Find("CustomTerrainTools/PaintWithLimits"));
            return m_Material;
        }

        public override void OnSceneGUI(Terrain terrain, IOnSceneGUI editContext)
        {
            // We're only doing painting operations, early out if it's not a repaint
            if (Event.current.type != EventType.Repaint)
                return;

            if (editContext.hitValidTerrain)
            {
                BrushTransform brushXform = TerrainPaintUtility.CalculateBrushTransform(terrain, editContext.raycastHit.textureCoord, editContext.brushSize, 0.0f);
                PaintContext ctx = TerrainPaintUtility.BeginPaintHeightmap(terrain, brushXform.GetBrushXYBounds(), 1);
                TerrainPaintUtilityEditor.DrawBrushPreview(ctx, TerrainPaintUtilityEditor.BrushPreview.SourceRenderTexture, editContext.brushTexture, brushXform, TerrainPaintUtilityEditor.GetDefaultBrushPreviewMaterial(), 0);
                TerrainPaintUtility.ReleaseContextResources(ctx);
            }
        }

        public override bool OnPaint(Terrain terrain, IOnPaint editContext)
        {
            int heightmapResolution = terrain.terrainData.heightmapResolution;
            BrushTransform brushXform = TerrainPaintUtility.CalculateBrushTransform(terrain, editContext.uv, editContext.brushSize, 0.0f);
            PaintContext paintContext = TerrainPaintUtility.BeginPaintTexture(terrain, brushXform.GetBrushXYBounds(), m_SelectedTerrainLayer);
            PaintContext normalsContext = PaintContext.CreateFromBounds(terrain, brushXform.GetBrushXYBounds(), heightmapResolution, heightmapResolution);
            PaintContext heightsContext = PaintContext.CreateFromBounds(terrain, brushXform.GetBrushXYBounds(), heightmapResolution, heightmapResolution);
            if (paintContext == null || normalsContext == null || heightsContext == null)
                return false;
            normalsContext.CreateRenderTargets(Terrain.normalmapRenderTextureFormat);
            heightsContext.CreateRenderTargets(Terrain.heightmapRenderTextureFormat);
            if (terrain.normalmapTexture != null)
            {
                normalsContext.GatherNormals();
            }
            else
            {
                if (Event.current.type != EventType.MouseDrag)
                {
                    Debug.Log("Terrain normal map missing! Make sure \"Draw Instanced\" is checked in the terrain settings if you want this to work!");
                }
            }
            heightsContext.GatherHeightmap();

            paintContext.sourceRenderTexture.filterMode = FilterMode.Bilinear;

            Material mat = GetPaintMaterial();

            // apply brush
            Vector4 brushParams = new Vector4(_minHeight, _maxHeight, _minHeightFalloff, _maxHeightFalloff);
            Vector4 brushParams2 = new Vector4(_minAngle, _maxAngle, _minAngleFalloff, _maxAngleFalloff) * Mathf.Deg2Rad;
            mat.SetTexture("_BrushTex", editContext.brushTexture);
            mat.SetTexture("_TerrainNormals", normalsContext.sourceRenderTexture);
            mat.SetTexture("_TerrainHeights", heightsContext.sourceRenderTexture);
            mat.SetVector("_BrushParams", brushParams);
            mat.SetVector("_BrushParams2", brushParams2);
            mat.SetFloat("_TerrainMaxHeight", terrain.terrainData.size.y);

            TerrainPaintUtility.SetupTerrainToolMaterialProperties(paintContext, brushXform, mat);

            Graphics.Blit(paintContext.sourceRenderTexture, paintContext.destinationRenderTexture, mat, 0);

            TerrainPaintUtility.EndPaintTexture(paintContext, "Terrain Paint With Limits - Texture");
            heightsContext.Cleanup();
            normalsContext.Cleanup();
            return true;
        }

        public override void OnInspectorGUI(Terrain terrain, IOnInspectorGUI editContext)
        {
            GUILayout.Label("Settings", EditorStyles.boldLabel);

            EditorGUI.BeginChangeCheck();

            _minHeight = EditorGUILayout.Slider("Min Height", _minHeight, 0, 2000);
            _maxHeight = EditorGUILayout.Slider("Max Height",_maxHeight, 0, 2000);
            _minHeightFalloff = EditorGUILayout.Slider("Bottom Height Falloff", _minHeightFalloff, 0, 2000);
            _maxHeightFalloff = EditorGUILayout.Slider("Top Height Falloff", _maxHeightFalloff, 0, 2000);
            _minAngle = EditorGUILayout.Slider("Min Slope Angle", _minAngle, 0, 90);
            _maxAngle = EditorGUILayout.Slider("Max Slope Angle", _maxAngle, 0, 90);
            _minAngleFalloff = EditorGUILayout.Slider("Bottom Angle Falloff", _minAngleFalloff, 0, 90);
            _maxAngleFalloff = EditorGUILayout.Slider("Top Angle Falloff", _maxAngleFalloff, 0, 90);

            EditorGUILayout.Space();
            //Editor.DrawFoldoutInspector(terrain.materialTemplate, ref m_TemplateMaterialEditor);

            EditorGUILayout.Space();

            int layerIndex = TerrainPaintUtility.FindTerrainLayerIndex(terrain, m_SelectedTerrainLayer);
            layerIndex = TerrainLayerUtility.ShowTerrainLayersSelectionHelper(terrain, layerIndex);
            EditorGUILayout.Space();

            if (EditorGUI.EndChangeCheck())
            {
                m_SelectedTerrainLayer = layerIndex != -1 ? terrain.terrainData.terrainLayers[layerIndex] : null;
                Save(true);
            }

            //TerrainLayerUtility.ShowTerrainLayerGUI(terrain, m_SelectedTerrainLayer, ref m_SelectedTerrainLayerInspector,
                //(m_TemplateMaterialEditor as MaterialEditor)?.customShaderGUI as ITerrainLayerCustomUI);
            EditorGUILayout.Space();

            editContext.ShowBrushesGUI(5);
        }
    }
}