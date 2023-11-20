using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ColorVolume
{
    public class ColorRendererFeature : ScriptableRendererFeature
    {
        [SerializeField]
        private Shader shader;

        private ColorRenderPass renderPass;
        private Material material;

        public override void Create()
        {
            material = CoreUtils.CreateEngineMaterial(shader);
            renderPass = new ColorRenderPass(material)
            {
                renderPassEvent = RenderPassEvent.AfterRenderingTransparents
            };
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            renderer.EnqueuePass(renderPass);
        }

        protected override void Dispose(bool disposing)
        {
            if (material != null)
            {
                CoreUtils.Destroy(material);
                material = null;
            }
        }
    }
}
