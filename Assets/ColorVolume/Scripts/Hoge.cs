using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Serialization;
using UnityEngine.UI;

namespace ColorVolume
{
    public class Hoge : MonoBehaviour
    {
        [FormerlySerializedAs("vignetteRenderer")] [SerializeField]
        private ColorRendererFeature colorRenderer;

        [SerializeField]
        private Slider slider;

        private void Awake()
        {
            slider.onValueChanged.AddListener(x =>
            {
                // colorRenderer.Hoge(x);
            });

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
                    // (rendererFeature as ColorRendererFeature).Hoge(1);
                }
            }
        }
    }
}
