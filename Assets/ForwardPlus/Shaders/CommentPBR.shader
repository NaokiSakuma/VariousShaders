Shader "ForwardPlus/CommentPRB"
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

        half4 UniversalFragmentPBR2(InputData inputData, SurfaceData surfaceData)
        {
            #if defined(_SPECULARHIGHLIGHTS_OFF)
            bool specularHighlightsOff = true;
            #else
            bool specularHighlightsOff = false;
            #endif
            BRDFData brdfData;

            // NOTE: can modify "surfaceData"...
            InitializeBRDFData(surfaceData, brdfData);

            #if defined(DEBUG_DISPLAY)
            half4 debugColor;

            if (CanDebugOverrideOutputColor(inputData, surfaceData, brdfData, debugColor))
            {
                return debugColor;
            }
            #endif

            // Clear-coat calculation...
            BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);
            half4 shadowMask = CalculateShadowMask(inputData);
            AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
            uint meshRenderingLayers = GetMeshRenderingLayer();
            Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

            // NOTE: We don't apply AO to the GI here because it's done in the lighting calculation below...
            MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

            LightingData lightingData = CreateLightingData(inputData, surfaceData);

            lightingData.giColor = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                                                      inputData.bakedGI, aoFactor.indirectAmbientOcclusion, inputData.positionWS,
                                                      inputData.normalWS, inputData.viewDirectionWS, inputData.normalizedScreenSpaceUV);
        #ifdef _LIGHT_LAYERS
            if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
        #endif
            {
                lightingData.mainLightColor = LightingPhysicallyBased(brdfData, brdfDataClearCoat,
                                                                      mainLight,
                                                                      inputData.normalWS, inputData.viewDirectionWS,
                                                                      surfaceData.clearCoatMask, specularHighlightsOff);
            }

            // .. ↑今回のForwardPlusには関係ない

            // このdefinedはForwardPlusにするだけで強制的に定義される
            #if defined(_ADDITIONAL_LIGHTS)
                // ForwardPlusだと0が帰ってくる
                uint pixelLightCount = GetAdditionalLightsCount();

                #if USE_FORWARD_PLUS
                    // URP_FP_DIRECTIONAL_LIGHTS_COUNT : DirectionalLightの数
                    // MAX_VISIBLE_LIGHTS : 256
                    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
                    {
                        // #if USE_FORWARD_PLUS && defined(LIGHTMAP_ON) && defined(LIGHTMAP_SHADOW_MIXING)
                        // ↑なら、indexのaが0以上ならcontinueしてる -> なんで？ｗ
                        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

                        // RealtimeLights.hlsl
                        // GetPerObjectLightIndex()でライトのインデックスを取得してる、FowardPlusの時点でindexが帰ってくる
                        // GetAdditionalPerObjectLight()
                        // USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA -> ビルトイン以外でtrue
                        // StructuredBuffer経由で入ってきたLightBufferからLightの情報を取得する
                        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

                        #ifdef _LIGHT_LAYERS
                            if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
                        #endif
                        {
                            // BRDFを元にライティング
                            lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                                                          surfaceData.clearCoatMask, specularHighlightsOff);
                        }
                    }
                #endif

                LIGHT_LOOP_BEGIN(pixelLightCount)
                    Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

            #ifdef _LIGHT_LAYERS
                    if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
            #endif
                    {
                        lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                                      inputData.normalWS, inputData.viewDirectionWS,
                                                                                      surfaceData.clearCoatMask, specularHighlightsOff);
                    }
                LIGHT_LOOP_END
            #endif

            // ForwardLights.cs 424側で定義、ForwardPlusだと強制的にtrue
            // これ無くても色変わらんけど
            #if defined(_ADDITIONAL_LIGHTS_VERTEX)
                lightingData.vertexLightingColor += inputData.vertexLighting * brdfData.diffuse;
            #endif

            return CalculateFinalColor(lightingData, surfaceData.alpha);
        }

     #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

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

            half4 resultColor = UniversalFragmentPBR2(inputData, surfaceData);

            #if USE_FORWARD_PLUS
            uint a = URP_FP_DIRECTIONAL_LIGHTS_COUNT;

             int b = min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS);
                        if (b == 0)
            {
                // return half4(1,1,1,1);
            }

            #endif

            int pixelLightCount = GetAdditionalLightsCount();
            if (pixelLightCount == 0)
            {
                return half4(pixelLightCount,pixelLightCount,pixelLightCount,1);
            }


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

                #pragma multi_compile _ _FORWARD_PLUS

            #pragma multi_compile _ LIGHTMAP_ON
            // #pragma multi_compile _ _FORWARD_PLUS
            ENDHLSL
        }
    }
}
