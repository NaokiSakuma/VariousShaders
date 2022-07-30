using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace SwapBuffer
{
    public class GrayscaleRendererFeatureBySwapBuffer : ScriptableRendererFeature
    {
        [SerializeField]
        private Shader shader;

        private GrayscalePassBySwapBuffer grayscalePass;

        // 初期化
        public override void Create()
        {
            grayscalePass = new GrayscalePassBySwapBuffer(shader);
        }

        // 1つ、または複数のパスを追加する
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            renderer.EnqueuePass(grayscalePass);
        }
    }
}
