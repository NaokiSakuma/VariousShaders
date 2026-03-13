using TransparentDoF;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class TransparentDoFRendererFeature : ScriptableRendererFeature
{
    private TransparentDoFRenderPass renderPass;

    public override void Create()
    {
        renderPass = new TransparentDoFRenderPass
        {
            renderPassEvent = RenderPassEvent.AfterRenderingTransparents
        };
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(renderPass);
    }
    
    protected virtual void Dispose(bool disposing)
    {
        base.Dispose(disposing);
    }
}
