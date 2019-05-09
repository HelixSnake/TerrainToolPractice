using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.TerrainAPI;

// TODO: Investigate if there are any platforms where reading/writing out of bounds will cause problems. If so, compute shader may need to be re-written.
namespace UnityEditor.Experimental.TerrainAPI
{
    public class TerrainToolDiamondFractal : TerrainPaintTool<TerrainToolDiamondFractal>
    {
        Material m_Material = null;
        float _heightMax = 0;
        float _heightMin = 0;
        float _roughness = 0.5f;
        float _brushSize = 20;
        int _resoMag = 10; // Resolution magnitude; the texture resolution will be 2 ^ _resoMag + 1, and the number of iterations will be equal to Resomag
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
            TerrainPaintUtilityEditor.ShowDefaultPreviewBrush(terrain, _renderTexture, _brushSize);
        }

        public override void OnInspectorGUI(Terrain terrain, Experimental.TerrainAPI.IOnInspectorGUI editContext)
        {
            _brushSize = EditorGUILayout.Slider("Brush Size", _brushSize, 0.1f, 1100);
            _heightMax = EditorGUILayout.Slider("Max Height", _heightMax, 0, 1000);
            _heightMin = EditorGUILayout.Slider("Min Height", _heightMin, 0, 1000);
            GUIContent roughnessText = new GUIContent("Roughness", "How bumpy you want the fractal to be, ");
            _roughness = EditorGUILayout.Slider(roughnessText, _roughness, 0, 0.95f);
            GUIContent resomagText = new GUIContent("Resolution Magnitude", "The resolution of the final texture will be 2^n + 1, where n is the value you've chosen");
            _resoMag = EditorGUILayout.IntSlider(resomagText, _resoMag, 4, 13);
            _seed = EditorGUILayout.IntSlider("Random Seed", _seed, 0, 10000000);
            if (GUILayout.Button("Generate"))
            {
                GenerateFractal();
            }
            GUIStyle textureDisplay = new GUIStyle();
            GUILayout.Box(_renderTexture, GUILayout.Width(256), GUILayout.Height(256));
        }
        public override bool OnPaint(Terrain terrain, IOnPaint editContext)
        {
            if (Event.current.type == EventType.MouseDrag)
                return true;

            Material mat = TerrainPaintUtility.GetBuiltinPaintMaterial();

            float rotationDegrees = 0.0f;
            BrushTransform brushXform = TerrainPaintUtility.CalculateBrushTransform(terrain, editContext.uv, _brushSize, rotationDegrees);
            PaintContext paintContext = TerrainPaintUtility.BeginPaintHeightmap(terrain, brushXform.GetBrushXYBounds());

            float height = _heightMax / terrain.terrainData.size.y;

            // apply brush
            Vector4 brushParams = new Vector4(1.0f, 0.0f, height, 0);
            mat.SetTexture("_BrushTex", _renderTexture);
            mat.SetVector("_BrushParams", brushParams);
            TerrainPaintUtility.SetupTerrainToolMaterialProperties(paintContext, brushXform, mat);

            Graphics.Blit(paintContext.sourceRenderTexture, paintContext.destinationRenderTexture, mat, (int)TerrainPaintUtility.BuiltinPaintMaterialPasses.StampHeight);

            TerrainPaintUtility.EndPaintHeightmap(paintContext, "Terrain Paint - Diamond Square Fractal");
            return false;
        }

        public void GenerateFractal()
        {
            // Visit https://en.wikipedia.org/wiki/Diamond-square_algorithm if you need a visual aid on what this shader is doing!
            if (!_computeShader)
            {
                Debug.LogError("Compute shader for Square Diamond Fractal Terrain Tool not found!");
            }
            // Generate resolution
            int resolution = 1 << _resoMag; // bitshift to get 2 ^ _resoMag
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

            // Create our "reading" render texture so we aren't reading and writing to our render texture at the same time (we don't need to do this but it makes debugging easier)
            CustomRenderTexture renderTexture2 = new CustomRenderTexture(resolution, resolution, RenderTextureFormat.R16);
            renderTexture2.Create();

            // Initialize compute shader variables
            _computeShader.SetInt("widthMinusOne", resolution - 1);
            _computeShader.SetInt("randomSeed", _seed);

            // Use the compute shader to clear our render texture to 0.5
            int kernelHandle = _computeShader.FindKernel("Clear");
            _computeShader.SetTexture(kernelHandle, "write", _renderTexture);
            _computeShader.Dispatch(kernelHandle, resolution / 8 + 1, resolution / 8 + 1, 1); // We have to add 1 extra line on the x and y to account for our strange resolution

           /*kernelHandle = _computeShader.FindKernel("RandomTest");
            _computeShader.SetTexture(kernelHandle, "write", _renderTexture);
            _computeShader.SetInt("textureWidth", resolution);
            _computeShader.SetInt("randomSeed", _seed);
            _computeShader.Dispatch(kernelHandle, resolution / 8, resolution / 8, 1);*/

            //initialize the corners
            kernelHandle = _computeShader.FindKernel("StartCorners");
            _computeShader.SetTexture(kernelHandle, "write", _renderTexture);
            _computeShader.Dispatch(kernelHandle, 1, 1, 1);
            
            // Copy to our readable render texture
            Graphics.Blit(_renderTexture, renderTexture2);

            float variation = 1;
            // MAIN LOOP
            for (int i = 1; i <= _resoMag; i++)
            {
                _computeShader.SetInt("iteration", i);

                // Diamond Pass
                int numBlocks = 1 << (i - 1); // bitshift to get 2 ^ (i - 1)
                int threadgroups = Mathf.Max(numBlocks / 8, 1);
                variation *= _roughness;
                _computeShader.SetFloat("variation", variation);
                kernelHandle = _computeShader.FindKernel("Diamond");
                _computeShader.SetTexture(kernelHandle, "write", _renderTexture);
                _computeShader.SetTexture(kernelHandle, "read", renderTexture2);
                _computeShader.Dispatch(kernelHandle, threadgroups, threadgroups, 1);

                Graphics.Blit(_renderTexture, renderTexture2);

                // Square Pass
                int numBlocksX = numBlocks + 1; // Always 1 more than our previous pass
                int numBlocksY = numBlocks * 2 + 1; // How many blocks we need vertically
                int threadgroupsX = Mathf.Max(numBlocksX / 4, 1);
                int threadgroupsY = Mathf.Max(numBlocksY / 8, 1);
                variation *= _roughness;
                _computeShader.SetFloat("variation", variation);
                kernelHandle = _computeShader.FindKernel("Square");
                _computeShader.SetTexture(kernelHandle, "write", _renderTexture);
                _computeShader.SetTexture(kernelHandle, "read", renderTexture2);
                _computeShader.Dispatch(kernelHandle, threadgroupsX, threadgroupsY, 1);

                // Edge corrections for Square Pass
                int threadgroupsEdges = Mathf.Max(numBlocksX / 8, 1);

                kernelHandle = _computeShader.FindKernel("SquareLeftSide");
                _computeShader.SetTexture(kernelHandle, "write", _renderTexture);
                _computeShader.SetTexture(kernelHandle, "read", renderTexture2);
                _computeShader.Dispatch(kernelHandle, 1, threadgroupsEdges, 1);

                kernelHandle = _computeShader.FindKernel("SquareRightSide");
                _computeShader.SetTexture(kernelHandle, "write", _renderTexture);
                _computeShader.SetTexture(kernelHandle, "read", renderTexture2);
                _computeShader.Dispatch(kernelHandle, 1, threadgroupsEdges, 1);

                kernelHandle = _computeShader.FindKernel("SquareTopSide");
                _computeShader.SetTexture(kernelHandle, "write", _renderTexture);
                _computeShader.SetTexture(kernelHandle, "read", renderTexture2);
                _computeShader.Dispatch(kernelHandle, threadgroupsEdges, 1, 1);

                kernelHandle = _computeShader.FindKernel("SquareBottomSide");
                _computeShader.SetTexture(kernelHandle, "write", _renderTexture);
                _computeShader.SetTexture(kernelHandle, "read", renderTexture2);
                _computeShader.Dispatch(kernelHandle, threadgroupsEdges, 1, 1);

                Graphics.Blit(_renderTexture, renderTexture2);
            }

            renderTexture2.Release();
        }
    }
}