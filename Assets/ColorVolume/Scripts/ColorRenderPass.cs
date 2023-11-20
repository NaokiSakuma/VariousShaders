using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ColorVolume
{
    public class ColorRenderPass : ScriptableRenderPass
    {
        private const string ProfilerTag = nameof(ColorRenderPass);

        private readonly Material material;
        private static readonly int Power = Shader.PropertyToID("_Power");

        public ColorRenderPass(Material material)
        {
            this.material = material;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!renderingData.postProcessingEnabled)
            {
                return;
            }

            var stack = VolumeManager.instance.stack;
            var colorVolume = stack.GetComponent<ColorVolume>();

            if (colorVolume == null || !colorVolume.IsActive())
            {
                return;
            }

            var cameraColorTarget = renderingData.cameraData.renderer.cameraColorTargetHandle;
            var cmd = CommandBufferPool.Get(ProfilerTag);

            material.SetFloat(Power, colorVolume.power.value);
            Blitter.BlitCameraTexture(cmd, cameraColorTarget, cameraColorTarget, material, 0);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}
