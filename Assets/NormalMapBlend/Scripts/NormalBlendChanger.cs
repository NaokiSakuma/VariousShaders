using TMPro;
using UnityEngine;

namespace NormalMapBlend
{
    public enum BlendType
    {
        WhiteOut,
        Reoriented,
        Linear,
        Overlay,
        PartialDerivative,
        UnrealDeveloperNetwork
    }

    [ExecuteAlways]
    public class NormalBlendChanger : MonoBehaviour
    {
        private readonly int blendTypeProp = Shader.PropertyToID("_BlendType");

        [SerializeField] private MeshRenderer meshRenderer;
        [SerializeField] private TextMeshProUGUI blendName;
        [SerializeField] private BlendType blendType;

        private void OnValidate()
        {
            meshRenderer.sharedMaterial.SetFloat(blendTypeProp, (float)blendType);
            blendName.text = blendType.ToString();
        }
    }
}
