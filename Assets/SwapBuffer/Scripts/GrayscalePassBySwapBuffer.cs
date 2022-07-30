using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace SwapBuffer
{
    public class GrayscalePassBySwapBuffer : ScriptableRenderPass
    {
        private const string ProfilerTag = nameof(GrayscalePassBySwapBuffer);

        private readonly Material material;

        public GrayscalePassBySwapBuffer(Shader shader)
        {
            material = CoreUtils.CreateEngineMaterial(shader);
            renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get(ProfilerTag);
            // Blit1回で良くなった
            Blit(cmd, ref renderingData, material);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}
