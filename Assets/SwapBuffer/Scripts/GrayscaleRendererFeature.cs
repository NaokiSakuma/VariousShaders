using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace SwapBuffer
{
    public class GrayscaleRendererFeature : ScriptableRendererFeature
    {
        [SerializeField]
        private Shader shader;

        private GrayscalePass grayscalePass;

        // 初期化
        public override void Create()
        {
            grayscalePass = new GrayscalePass(shader);
        }

        // 1つ、または複数のパスを追加する
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            grayscalePass.SetRenderTarget(renderer.cameraColorTarget);
            renderer.EnqueuePass(grayscalePass);
        }
    }
}