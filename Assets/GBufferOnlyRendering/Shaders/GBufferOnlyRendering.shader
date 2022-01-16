Shader "GBufferOnlyRendering"
{
    Properties
    {
        [KeywordEnum(DIFF, SPEC, NORM, LIGHT, DEPTH, SHADOW)]
        _GB ("G-Buffer", float) = 0
    }
    SubShader
    {
        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            // バリアント
            #pragma multi_compile _GB_DIFF _GB_SPEC _GB_NORM _GB_LIGHT _GB_DEPTH _GB_SHADOW
            // _ShadowMapTextureを有効化にする
            #define SHADOWS_SCREEN

            #include "UnityCG.cginc"

            // 拡散反射光(RBG), occlusion(A)
            sampler2D _CameraGBufferTexture0;
            // 鏡面反射光(RBG), roughness(A)
            // memo : roughness = 1.0 - smoothness
            sampler2D _CameraGBufferTexture1;
            // 法線ベクトル(RBG), 未使用(A)
            sampler2D _CameraGBufferTexture2;
            // Emission + lighting + lightmaps + reflection probes
            // memo : カメラがHDRレンダリングを使用している場合、Emission + lightingのRenderTargetsは生成されない
            // 代わりに、カメラがレンダリングするターゲットがRT3として使用される
            sampler2D _CameraGBufferTexture3;
            // Light occlusion(RGBA)
            // memo : ShadowmaskかDistanceShadowmaskのライトモードを使用している場合に使える
            sampler2D _CameraGBufferTexture4;
            // Depth + Stencil
            // sampler2D _CameraDepthTexture;

            fixed4 frag (v2f_img i) : SV_Target
            {
                #ifdef _GB_DIFF
                    return tex2D(_CameraGBufferTexture0, i.uv);
                #elif _GB_SPEC
                    return tex2D(_CameraGBufferTexture1, i.uv);
                #elif _GB_NORM
                    return tex2D(_CameraGBufferTexture2, i.uv);
                #elif _GB_LIGHT
                    return tex2D(_CameraGBufferTexture3, i.uv);
                #elif _GB_DEPTH
                    // 深度値を0~1にする
                    return Linear01Depth(tex2D(_CameraDepthTexture, i.uv).r);
                #else
                    return tex2D(_ShadowMapTexture, i.uv);
                #endif
            }
            ENDCG
        }
    }
}
