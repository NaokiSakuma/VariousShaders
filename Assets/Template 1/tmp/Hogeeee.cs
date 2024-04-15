using UnityEngine;
using UnityEngine.Rendering.Universal;


// TODO 名前どうにかする
// [DisallowMultipleRendererFeature]
public class Hogeeee : ScriptableRendererFeature
{
    [SerializeField]
    private Shader shader;

    private GrayscalePass grayscalePass;

    public override void Create()
    {
        grayscalePass = new GrayscalePass(shader);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
#if !UNITY_2022_2_OR_NEWER
        grayscalePass.SetRenderTarget(renderer.cameraColorTarget);
#endif
        renderer.EnqueuePass(grayscalePass);
    }

#if UNITY_2022_2_OR_NEWER
    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        grayscalePass.SetRenderTarget(renderer.cameraColorTargetHandle);
    }
#endif

    private void Reset()
    {
        shader = Shader.Find("GrayScale");
    }
}
