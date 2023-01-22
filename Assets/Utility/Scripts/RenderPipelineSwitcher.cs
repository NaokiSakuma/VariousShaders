using UnityEngine;
using UnityEngine.Rendering;

namespace Utility
{
    [ExecuteAlways]
    public class RenderPipelineSwitcher : MonoBehaviour
    {
        [SerializeField]
        private RenderPipelineAsset renderPipelineAsset;

        private void Awake()
        {
            ChangeRenderPipeline();
        }

        private void OnValidate()
        {
            ChangeRenderPipeline();
        }

        private void ChangeRenderPipeline()
        {
            if (GraphicsSettings.renderPipelineAsset == renderPipelineAsset)
            {
                return;
            }

            GraphicsSettings.renderPipelineAsset = renderPipelineAsset;
        }
    }
}
