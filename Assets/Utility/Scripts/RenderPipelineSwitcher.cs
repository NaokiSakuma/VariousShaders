using UnityEngine;
using UnityEngine.Rendering;

namespace Utility
{
    public class RenderPipelineSwitcher : MonoBehaviour
    {
        [SerializeField]
        private RenderPipelineAsset renderPipelineAsset;

        private void OnValidate()
        {
            if (GraphicsSettings.renderPipelineAsset == renderPipelineAsset)
            {
                return;
            }

            GraphicsSettings.renderPipelineAsset = renderPipelineAsset;
        }
    }
}
