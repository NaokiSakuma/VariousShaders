using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

namespace TransparentDoF
{
    public class TransparentDoFRenderPass : ScriptableRenderPass
    {
        private readonly ShaderTagId shaderTagId = new ("DepthOnly");

        internal class PassData
        {
            public RendererList RendererList;
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
            var sourceTextureHandle = resourceData.activeColorTexture;

            var descriptor = renderGraph.GetTextureDesc(sourceTextureHandle);
            descriptor.clearBuffer = true;
            descriptor.msaaSamples = MSAASamples.None;
            
            var textureHandle = renderGraph.CreateTexture(descriptor);

            var drawSettings = RenderingUtils.CreateDrawingSettings(shaderTagId, renderingData, cameraData, lightData, SortingCriteria.CommonTransparent);
            var filterSettings = new FilteringSettings(RenderQueueRange.transparent);
            var rendererListParams = new RendererListParams(renderingData.cullResults, drawSettings, filterSettings);
            var rendererList = renderGraph.CreateRendererList(rendererListParams);

            using (var builder = renderGraph.AddRasterRenderPass<PassData>("Hoge", out var passData))
            {
                passData.RendererList = rendererList;
                
                builder.SetRenderAttachment(textureHandle, 0, AccessFlags.Write);
            }
        }
    }
}
