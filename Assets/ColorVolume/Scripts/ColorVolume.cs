using System;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ColorVolume
{
    [Serializable]
    [VolumeComponentMenuForRenderPipeline("MyVolume/Color", typeof(UniversalRenderPipeline))]
    public class ColorVolume : VolumeComponent, IPostProcessComponent
    {
        public ClampedFloatParameter power = new(0, 0, 1);
        public BoolParameter isEnabled = new(false);

        public bool IsActive() => isEnabled.value;
        public bool IsTileCompatible() => false;
    }
}
