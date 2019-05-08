using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.TerrainAPI;

namespace UnityEditor.Experimental.TerrainAPI
{
    public class TerrainToolDiamondFractal : TerrainPaintTool<TerrainToolDiamondFractal>
    {
        Material m_Material = null;
        float _heightMax = 0;
        float _heightMin = 0;
        float _roughness = 0.5f;
        int _resoMag = 10;
        int _seed = 0;
        CustomRenderTexture _renderTexture;
        ComputeShader _computeShader;
        Material GetPaintMaterial()
        {
            if (m_Material == null)
                m_Material = new Material(Shader.Find("Hidden/Terrain/PaintHeight"));
            return m_Material;
        }

        public override void OnEnable()
        {
            _computeShader = (ComputeShader)Resources.Load("SquareDiamondRandomFractal");
            if (!_computeShader)
            {
                Debug.LogError("Compute shader for Square Diamond Fractal Terrain Tool not found!");
            }
        }

        public override string GetName()
        {
            return "Square Diamond Fractal Terrain Generator";
        }

        public override string GetDesc()
        {
            return "TODO: Create description after tool has been created";
        }
        public override void OnSceneGUI(Terrain terrain, IOnSceneGUI editContext)
        {
            TerrainPaintUtilityEditor.ShowDefaultPreviewBrush(terrain, editContext.brushTexture, editContext.brushSize);
        }

        public override void OnInspectorGUI(Terrain terrain, Experimental.TerrainAPI.IOnInspectorGUI editContext)
        {
            _heightMax = EditorGUILayout.Slider("Max Height", _heightMax, 0, 1000);
            _heightMin = EditorGUILayout.Slider("Min Height", _heightMin, 0, 1000);
            GUIContent roughnessText = new GUIContent("Roughness", "How bumpy you want the fractal to be, ");
            _roughness = EditorGUILayout.Slider(roughnessText, _roughness, 0, 0.95f);
            GUIContent resomagText = new GUIContent("Resolution Magnitude (2^n)", "The resolution of the final texture will be 2^n + 1, where n is the value you've chosen");
            _resoMag = EditorGUILayout.IntSlider(resomagText, _resoMag, 1, 13);
            _seed = EditorGUILayout.IntField("Random Seed", _seed);
            if (GUILayout.Button("Generate"))
            {
                GenerateFractal();
            }
            GUILayout.Box(_renderTexture, GUILayout.Width(256), GUILayout.Height(256), GUILayout.ExpandWidth(true), GUILayout.ExpandHeight(true));
        }
        public override bool OnPaint(Terrain terrain, IOnPaint editContext)
        {
            Material mat = TerrainPaintUtility.GetBuiltinPaintMaterial();

            float rotationDegrees = 0.0f;
            BrushTransform brushXform = TerrainPaintUtility.CalculateBrushTransform(terrain, editContext.uv, editContext.brushSize, rotationDegrees);
            PaintContext paintContext = TerrainPaintUtility.BeginPaintHeightmap(terrain, brushXform.GetBrushXYBounds());

            // apply brush
            Vector4 brushParams = new Vector4(editContext.brushStrength * 0.01f, 0.0f, 0.0f, 0.0f);
            mat.SetTexture("_BrushTex", editContext.brushTexture);
            mat.SetVector("_BrushParams", brushParams);
            TerrainPaintUtility.SetupTerrainToolMaterialProperties(paintContext, brushXform, mat);

            Graphics.Blit(paintContext.sourceRenderTexture, paintContext.destinationRenderTexture, mat, (int)TerrainPaintUtility.BuiltinPaintMaterialPasses.RaiseLowerHeight);

            TerrainPaintUtility.EndPaintHeightmap(paintContext, "Terrain Paint - MyPaintHeightTool");
            return false;
        }

        public void GenerateFractal()
        {
            if (!_computeShader)
            {
                Debug.LogError("Compute shader for Square Diamond Fractal Terrain Tool not found!");
            }
            // Generate resolution
            int resolution = 2;
            for (int i = 1; i < _resoMag; i++)
            {
                resolution *= 2;
            }
            resolution += 1;
            if (!_renderTexture)
            {
                // Create our render texture
                _renderTexture = new CustomRenderTexture(resolution, resolution, RenderTextureFormat.R16);
                _renderTexture.enableRandomWrite = true;
                _renderTexture.Create();
            }
            else if (_renderTexture.width != resolution || _renderTexture.height != resolution)
            {
                // Recreate render texture of proper size
                _renderTexture.Release();
                _renderTexture = new CustomRenderTexture(resolution, resolution, RenderTextureFormat.R16);
                _renderTexture.enableRandomWrite = true;
                _renderTexture.Create();
            }

            // Use the compute shader to clear our render texture to 0.5
            int kernelHandle = _computeShader.FindKernel("Clear");
            _computeShader.SetTexture(kernelHandle, "write", _renderTexture);
            _computeShader.Dispatch(kernelHandle, resolution / 8, resolution / 8, 1);

            CustomRenderTexture _renderTexture2 = new CustomRenderTexture(resolution, resolution, RenderTextureFormat.R16);
            _renderTexture2.enableRandomWrite = true;
            _renderTexture2.Create();

            Graphics.Blit(_renderTexture, _renderTexture2);

            _renderTexture2.Release();
        }
    }
}