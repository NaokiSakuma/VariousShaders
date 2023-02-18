using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace ConvertBlitter
{
    public class ConvertBlitterGrayscaleRendererFeature : ScriptableRendererFeature
    {
        [SerializeField]
        private Shader shader;

        private ConvertBlitterGrayscalePass grayscalePass;

        public override void Create()
        {
            grayscalePass = new ConvertBlitterGrayscalePass(shader);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            renderer.EnqueuePass(grayscalePass);
        }

        // renderer.cameraColorTargetはSetupRenderPasses内で呼ぶ
        public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
        {
            // cameraColorTarget -> cameraColorTargetHandleにする
            grayscalePass.SetRenderTarget(renderer.cameraColorTargetHandle);
        }
    }
}
