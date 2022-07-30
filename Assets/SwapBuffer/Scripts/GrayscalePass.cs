using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace SwapBuffer
{
    public class GrayscalePass : ScriptableRenderPass
    {
        private const string ProfilerTag = nameof(GrayscalePass);

        private readonly Material material;

        // 描画対象をハンドリングする
        private RenderTargetHandle tmpRenderTargetHandle;
        private RenderTargetIdentifier cameraColorTarget;

        public GrayscalePass(Shader shader)
        {
            material = CoreUtils.CreateEngineMaterial(shader);
            renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
            tmpRenderTargetHandle.Init("_TempRT");
        }

        public void SetRenderTarget(RenderTargetIdentifier target)
        {
            cameraColorTarget = target;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera)
            {
                return;
            }

            // コマンドバッファの生成
            var cmd = CommandBufferPool.Get(ProfilerTag);

            // RenderTextureDescriptorの取得
            var descriptor = renderingData.cameraData.cameraTargetDescriptor;
            // 今回深度は不要なので0に
            descriptor.depthBufferBits = 0;

            cmd.GetTemporaryRT(tmpRenderTargetHandle.id, descriptor);
            cmd.Blit(cameraColorTarget, tmpRenderTargetHandle.Identifier(), material);
            cmd.Blit(tmpRenderTargetHandle.Identifier(), cameraColorTarget);
            cmd.ReleaseTemporaryRT(tmpRenderTargetHandle.id);

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}