using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;

namespace ColorVolume
{
    public class ColorParameter : MonoBehaviour
    {
        [SerializeField]
        private Toggle toggle;
        [SerializeField]
        private Slider slider;

        [SerializeField]
        private Volume volume;

        private ColorVolume colorVolume;

        private void Awake()
        {
            if (!volume.profile.TryGet(out colorVolume))
            {
                return;
            }

            toggle.onValueChanged.AddListener(x =>
            {
                colorVolume.isEnabled.value = x;
            });

            slider.onValueChanged.AddListener(x =>
            {
                colorVolume.power.value = x;
            });
        }
    }
}
