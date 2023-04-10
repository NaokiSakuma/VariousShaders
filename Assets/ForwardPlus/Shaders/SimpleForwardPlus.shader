Shader "ForwardPlus/SimpleForwardPlus"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        struct Attributes
        {
            float4 positionOS    : POSITION;
            float3 normalOS      : NORMAL;
            float4 tangentOS     : TANGENT;
            float2 texcoord      : TEXCOORD0;
        };

        struct Varyings
        {
            float2 uv : TEXCOORD0;
            float3 positionWS : TEXCOORD1;
            half3  normalWS : TEXCOORD2;
            float4 positionCS : SV_POSITION;
        };

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
        CBUFFER_END

        Varyings vert(Attributes IN)
        {
            Varyings OUT;
            OUT.positionWS = TransformObjectToWorld(IN.positionOS);
            OUT.positionCS = TransformWorldToHClip(OUT.positionWS);
            OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);

            OUT.uv = TRANSFORM_TEX(IN.texcoord, _MainTex);
            return OUT;
        }

        half4 frag(Varyings IN) : SV_Target
        {
            half4 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

            SurfaceData surfaceData = (SurfaceData)0;
            surfaceData.albedo = mainColor.rgb;
            surfaceData.alpha = mainColor.a;
            surfaceData.smoothness = 1;
            surfaceData.normalTS = half3(0, 0, 1);
            surfaceData.occlusion = 1;

            InputData inputData = (InputData)0;
            inputData.positionWS = IN.positionWS;
            inputData.normalWS = IN.normalWS;
            half3 viewDirWS = GetWorldSpaceNormalizeViewDir(inputData.positionWS);
            viewDirWS = SafeNormalize(viewDirWS);
            inputData.viewDirectionWS = viewDirWS;
            inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.positionCS);

            // PBRでレンダリング
            half4 resultColor = UniversalFragmentPBR(inputData, surfaceData);

            return resultColor;
        }
    ENDHLSL

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque"
            "LightMode" = "UniversalForward"
            "UniversalMaterialType" = "Lit"
        }

        Pass
        {
            HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                // ForwardPlus用のバリアント
                #pragma multi_compile _ _FORWARD_PLUS
            ENDHLSL
        }
    }
}
