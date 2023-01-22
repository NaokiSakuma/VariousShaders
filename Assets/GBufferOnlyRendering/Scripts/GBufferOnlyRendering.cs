using System;
using UnityEngine;

namespace GBuffer
{
    public class GBufferOnlyRendering : MonoBehaviour
    {
        [SerializeField] private Camera gBufferCamera;
        [SerializeField] private Material material;
        [SerializeField] private GBuffer gBufferStatus;

        private GBuffer _oldGBuffer;

        private enum GBuffer
        {
            _GB_DIFF,
            _GB_SPEC,
            _GB_NORM,
            _GB_LIGHT,
            _GB_DEPTH,
            _GB_SHADOW
        }

        private void Start()
        {
            gBufferCamera.depthTextureMode |= DepthTextureMode.Depth;
            _oldGBuffer = gBufferStatus;
            ChangeGBuffer();
        }

        [ImageEffectOpaque]
        private void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            Graphics.Blit(src, dest, material);
        }

        private void OnValidate()
        {
            ChangeGBuffer();
        }

        /// <summary>
        /// GBufferの切り替え
        /// </summary>
        private void ChangeGBuffer()
        {
            switch (gBufferStatus)
            {
                case GBuffer._GB_DIFF:
                case GBuffer._GB_SPEC:
                case GBuffer._GB_NORM:
                case GBuffer._GB_LIGHT:
                case GBuffer._GB_DEPTH:
                    gBufferCamera.renderingPath = RenderingPath.DeferredShading;
                    break;
                case GBuffer._GB_SHADOW:
                    gBufferCamera.renderingPath = RenderingPath.Forward;
                    break;
                default:
                    throw new ArgumentOutOfRangeException();
            }

            material.DisableKeyword(_oldGBuffer.ToString());
            material.EnableKeyword(gBufferStatus.ToString());
            _oldGBuffer = gBufferStatus;
        }
    }
}
