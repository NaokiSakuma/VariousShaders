using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GrayscalePass : ScriptableRenderPass
{
    private const string ProfilerTag = nameof(GrayscalePass);
    private new readonly ProfilingSampler profilingSampler = new(ProfilerTag);

    private readonly Material material;

#if UNITY_2022_2_OR_NEWER
    private RTHandle tmpRenderTargetHandle;
    private RTHandle cameraColorTarget;
#else
    private RenderTargetHandle tmpRenderTargetHandle;
    private RenderTargetIdentifier cameraColorTarget;
#endif

    public GrayscalePass(Shader shader)
    {
        material = CoreUtils.CreateEngineMaterial(shader);
        renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
#if !UNITY_2022_2_OR_NEWER
        tmpRenderTargetHandle.Init("_TempRT");
#endif
    }

#if UNITY_2022_2_OR_NEWER
    public void SetRenderTarget(RTHandle target)
#else
    public void SetRenderTarget(RenderTargetIdentifier target)
#endif
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

        var descriptor = renderingData.cameraData.cameraTargetDescriptor;
        descriptor.depthBufferBits = 0;

        using (new ProfilingScope(cmd, profilingSampler))
        {
    #if UNITY_2022_2_OR_NEWER
            // RenderingUtils.ReAllocateIfNeededでRenderTextureを確保する
            RenderingUtils.ReAllocateIfNeeded(ref tmpRenderTargetHandle, descriptor, name: "_TempRT");
            Blit(cmd, cameraColorTarget, tmpRenderTargetHandle, material);
            Blit(cmd, tmpRenderTargetHandle, cameraColorTarget);
            // MEMO : この例だとBlit(cmd, ref renderingData, material);の方が好ましい
    #else
            cmd.GetTemporaryRT(tmpRenderTargetHandle.id, descriptor);
            cmd.Blit(cameraColorTarget, tmpRenderTargetHandle.Identifier(), material);
            cmd.Blit(tmpRenderTargetHandle.Identifier(), cameraColorTarget);
            cmd.ReleaseTemporaryRT(tmpRenderTargetHandle.id);
    #endif
        }

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
    
#if UNITY_2022_2_OR_NEWER
    public void Dispose()
    {
        CoreUtils.Destroy(material);
        tmpRenderTargetHandle?.Release();
        cameraColorTarget?.Release();
    }
#endif
}
