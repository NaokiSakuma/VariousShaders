using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ConvertBlitter
{
    public class ConvertBlitterGrayscalePass : ScriptableRenderPass
    {
        private const string ProfilerTag = nameof(ConvertBlitterGrayscalePass);

        private readonly Material material;

        private RTHandle cameraColorTarget;

        public ConvertBlitterGrayscalePass(Shader shader)
        {
            material = CoreUtils.CreateEngineMaterial(shader);
            renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        }

        public void SetRenderTarget(RTHandle target)
        {
            cameraColorTarget = target;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera)
            {
                return;
            }

            var cmd = CommandBufferPool.Get(ProfilerTag);
            // Blitterで描画する
            Blitter.BlitCameraTexture(cmd, cameraColorTarget, cameraColorTarget, material, 0);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}
