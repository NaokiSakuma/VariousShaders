Shader "GrayScale"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Renderpipeline"="UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
                #if UNITY_VERSION < 202220
                    // FxaaVaryingsを使用する
                    #pragma vertex vert
                #else
                    // Blit.hlslのものを使用する
                    #pragma vertex Vert
                #endif
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #if UNITY_VERSION >= 202220
                #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #endif

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };
            
            struct Varyings
            {
                float2 texcoord : TEXCOORD0;
                float4 positionHCS : SV_POSITION;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.texcoord = TRANSFORM_TEX(IN.texcoord, _MainTex);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.texcoord);
                half gray = dot(col.rgb, half3(0.299, 0.587, 0.114));
                return half4(gray, gray, gray, col.a);
            }
            ENDHLSL
        }
    }
}
