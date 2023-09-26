Shader "NormalMapBlend/ChangeBlend"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FirstNormalMap ("FirstNormalMap", 2D) = "bump"
        _SecondNormalMap ("SecondNormalMap", 2D) = "bump"
        [Enum(NormalMapBlend.BlendType)]_BlendType ("BlendType", float) = 0
    }

    HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        struct Attributes
        {
            float4 positionOS : POSITION;
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
            float2 uv : TEXCOORD0;
        };

        struct Varyings
        {
            float4 positionHCS : SV_POSITION;
            float2 uv : TEXCOORD0;
            float3 viewDir : TEXCOORD1;
            float3 lightDir : TEXCOORD2;
        };

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_FirstNormalMap);
        SAMPLER(sampler_FirstNormalMap);
        TEXTURE2D(_SecondNormalMap);
        SAMPLER(sampler_SecondNormalMap);

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half _BlendType;
        CBUFFER_END

        // UnityのShaderGraphのデフォルト
        float3 UnityWhiteOutBlend(float3 first, float3 second)
        {
            return normalize(float3(first.rg + second.rg, first.b * second.b));
        }

        // UnityのShaderGraphのReoriented
        // WhiteOutに比べ、高品質だがパフォーマンスが落ちる
        float3 UnityReorientedNormalBlend(float3 first, float3 second)
        {
            float3 t = first.xyz + float3(0, 0, 1);
            float3 u = second.xyz * float3(-1, -1, 1);

            return t / t.z * dot(t, u) - u;
        }

        // 2つのテクスチャの平坦化したブレンド
        float3 LinearBlend(float3 first, float3 second)
        {
            return normalize(float3(first + second));
        }

        // 強度が強い部分はより強く、弱い部分はより弱くするブレンド
        float3 OverlayBlend(float3 first, float3 second)
        {
            float3 r  = first < 0.5 ?
                2.0 * first * second :
                1.0 - 2.0 * (1.0 - first) * (1.0 - second);
            r = normalize(r * 2.0 - 1.0);
            return r * 0.5 + 0.5;
        }

        // 2つのノーマルマップの変化率をもとにブレンド
        float3 PartialDerivativeBlend(float3 first, float3 second)
        {
            half blendRate = 0.5;
            float2 pd = lerp(first.xy / first.z, second.xy / second.z, blendRate);

            return normalize(float3(pd, 1));
        }

        // WhiteOutBlendingのZ成分の乗算をやめることでパフォーマンスを良くしたもの
        float3 UnrealDeveloperNetworkBlend(float3 first, float3 second)
        {
            return normalize(float3(first.rg + second.rg, first.b));
        }

        Varyings vert(Attributes IN)
        {
            Varyings OUT;

            OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
            OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

            float3 binormal = cross(IN.normal, IN.tangent.xyz) * IN.tangent.w;
            float3x3 rotation = float3x3(IN.tangent.xyz, binormal, IN.normal);

            // ビルトインのObjSpaceViewDirと同義
            float3 objectSpaceViewDir = TransformWorldToObject(GetCameraPositionWS()) - IN.positionOS.xyz;
            OUT.viewDir = normalize(mul(rotation, objectSpaceViewDir));

            // ビルトインのObjSpaceLightDirと同義
            float3 objectSpaceLightDir = TransformWorldToObjectDir(_MainLightPosition.xyz) - IN.positionOS.xyz * _MainLightPosition.w;
            OUT.lightDir = normalize(mul(rotation, objectSpaceLightDir));
            return OUT;
        }

        half4 frag(Varyings IN) : SV_Target
        {
            half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
            float3 firstNormal = UnpackNormal(SAMPLE_TEXTURE2D(_FirstNormalMap, sampler_FirstNormalMap, IN.uv));
            float3 secondNormal = UnpackNormal(SAMPLE_TEXTURE2D(_SecondNormalMap, sampler_SecondNormalMap, IN.uv));

            float3 blendedNormal = _BlendType <= 0 ? UnityWhiteOutBlend(firstNormal, secondNormal) :
                                   _BlendType <= 1 ? UnityReorientedNormalBlend(firstNormal, secondNormal) :
                                   _BlendType <= 2 ? LinearBlend(firstNormal, secondNormal) :
                                   _BlendType <= 3 ? OverlayBlend(firstNormal, secondNormal) :
                                   _BlendType <= 4 ? PartialDerivativeBlend(firstNormal, secondNormal) :
                                   UnrealDeveloperNetworkBlend(firstNormal, secondNormal);

            half3 diffuse = max(0, dot(blendedNormal, IN.lightDir)) * _MainLightColor.rgb;
            half3 halfDir = normalize(IN.lightDir + IN.viewDir);
            half3 specular = pow (max(0, dot(blendedNormal, halfDir)), 128.0) * _MainLightColor.rgb;

            blendedNormal = mainTex.xyz * diffuse + specular;

            return float4(blendedNormal, 1);
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
