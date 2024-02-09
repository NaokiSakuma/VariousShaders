using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ColorVolume
{
    public class BadSamples : MonoBehaviour
    {
        // リフレクションを使ってやるのはちょっと無理やりな気がする
        private void Sample1()
        {
            var renderer = (GraphicsSettings.currentRenderPipeline as UniversalRenderPipelineAsset).GetRenderer(0);
            var property = typeof(ScriptableRenderer).GetProperty("rendererFeatures", BindingFlags.NonPublic | BindingFlags.Instance);
            if (property == null)
            {
                return;
            }

            var rendererFeatures = property.GetValue(renderer) as List<ScriptableRendererFeature>;

            foreach (var rendererFeature in rendererFeatures)
            {
                if (rendererFeature.GetType() == typeof(ColorRendererFeature))
                {
                    // e.g. rendererFeature.SetColor()
                }
            }
        }

        // ビルドするとURPが別のインスタンスIDにするので、動作しない
        // UnityEditor前提なら良いかも
        [SerializeField]
        private ColorRendererFeature colorRendererFeature;

        private void Sample2()
        {
            // e.g. colorRendererFeature.SetColor()
        }
    }
}
