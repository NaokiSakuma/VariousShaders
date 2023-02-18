Shader "ConvertBlitter/ConvertBlitterGrayScale"
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
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            #if SHADER_API_GLES
                struct GrayscaleAttributes
                {
                    float4 positionOS : POSITION;
                    float2 uv : TEXCOORD0;
                };
            #else
                struct GrayscaleAttributes
                {
                    uint vertexID : SV_VertexID;
                };
            #endif

            struct GrayscaleVaryings
            {
                float2 uv : TEXCOORD0;
                float4 positionHCS : SV_POSITION;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            GrayscaleVaryings vert (GrayscaleAttributes IN)
            {
                GrayscaleVaryings OUT;
                #if SHADER_API_GLES
                    float4 pos = input.positionOS;
                    float2 uv  = input.uv;
                #else
                    float4 pos = GetFullScreenTriangleVertexPosition(IN.vertexID);
                    float2 uv  = GetFullScreenTriangleTexCoord(IN.vertexID);
                #endif

                OUT.positionHCS = pos;
                OUT.uv = uv;
                return OUT;
            }

            half4 frag (GrayscaleVaryings IN) : SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearRepeat, IN.uv);
                half gray = dot(col.rgb, half3(0.299, 0.587, 0.114));
                return half4(gray, gray, gray, col.a);
            }
            ENDHLSL
        }
    }
}
