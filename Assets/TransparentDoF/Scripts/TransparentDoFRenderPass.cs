using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

namespace TransparentDoF
{
    public class TransparentDoFRenderPass : ScriptableRenderPass
    {
        private static int transparentDepthTextureID = Shader.PropertyToID("_TransparentDepthTexture");
        private readonly ShaderTagId shaderTagId = new ("DepthOnly");

        internal class PassData
        {
            public RendererListHandle RendererListHandle;
        }

        public TransparentDoFRenderPass()
        {

        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            var resourceData = frameData.Get<UniversalResourceData>();
            var renderingData = frameData.Get<UniversalRenderingData>();
            var cameraData = frameData.Get<UniversalCameraData>();
            var lightData = frameData.Get<UniversalLightData>();
            var sourceTextureHandle = resourceData.activeDepthTexture;

            var descriptor = renderGraph.GetTextureDesc(sourceTextureHandle);
            descriptor.clearBuffer = false;
            descriptor.msaaSamples = MSAASamples.None;
            descriptor.name = "_TransparentDepthTexture";
            descriptor.depthBufferBits = DepthBits.Depth32;
            // descriptor.colorFormat = GraphicsFormat.R32_SFloat;

            var textureHandle = renderGraph.CreateTexture(descriptor);

            var drawSettings = RenderingUtils.CreateDrawingSettings(shaderTagId, renderingData, cameraData, lightData, SortingCriteria.CommonTransparent);
            var filterSettings = new FilteringSettings(RenderQueueRange.transparent);
            var rendererListParams = new RendererListParams(renderingData.cullResults, drawSettings, filterSettings);
            var rendererList = renderGraph.CreateRendererList(rendererListParams);
            using (var builder = renderGraph.AddRasterRenderPass<PassData>("Hoge", out var passData))
            {
                passData.RendererListHandle = rendererList;

                builder.SetRenderAttachmentDepth(textureHandle, AccessFlags.Write);
                builder.UseRendererList(rendererList);
                builder.AllowGlobalStateModification(true);
                builder.AllowPassCulling(false);
                builder.SetGlobalTextureAfterPass(textureHandle, transparentDepthTextureID);


                builder.SetRenderFunc(static (PassData data, RasterGraphContext context) =>
                {
                    // context.cmd.ClearRenderTarget(true, true, Color.black);
                    context.cmd.DrawRendererList(data.RendererListHandle);
                });
            }
        }
    }
}
