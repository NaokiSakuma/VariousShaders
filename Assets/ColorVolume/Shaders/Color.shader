Shader "Volume/Color"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SingleColor ("Single Color", Range(0, 1)) = 0
    }

    HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

        #if SHADER_API_GLES
            struct VignetteAttributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
        #else
            struct VignetteAttributes
            {
                uint vertexID : SV_VertexID;
            };
        #endif

        struct VignetteVaryings
        {
            float2 uv : TEXCOORD0;
            float4 positionHCS : SV_POSITION;
        };

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half _SingleColor;
        CBUFFER_END

        VignetteVaryings vert(VignetteAttributes IN)
        {
            VignetteVaryings OUT;
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

        half4 frag(VignetteVaryings IN) : SV_Target
        {
            return half4(_SingleColor, _SingleColor, _SingleColor, 1);
        }
    ENDHLSL

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
        }

        Pass
        {
            HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment frag
            ENDHLSL
        }
    }
}