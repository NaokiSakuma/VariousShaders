Shader "BoatAttack/Cliff"
{
    Properties
    {
        _CliffTex ("Cliff Texture", 2D) = "white" {}
        _CliffNormalAO ("CliffNormal AO", 2D) = "white" {}
        _GrassBaseMap ("Grass Base Map", 2D) = "white" {}
        _GrassNormal ("Grass Normal", 2D) = "bump" {}
        [Normal]_RockDetail ("Rock Detail", 2D) = "bump" {}
        _RockSmoothness ("Rock Smoothness", Range(0, 1)) = 0.5
        _GrassHeightBlend ("Grass Height Blend", Range(1, 100)) = 1
        _GrassAngle ("Grass Angle", Range(0, 90)) = 60
        _DetailScale ("DetailScale", float) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "Renderpipeline"="UniversalPipeline"
            "UniversalMaterialType" = "Lit"
            "IgnoreProjector" = "True"
            "Queue" = "Geometry"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
                float2 lightmapUV : TEXCOORD1;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float3 binormalWS : TEXCOORD4;
                float3 viewDir : TEXCOORD5;
                half fogFactor : TEXCOORD6;
                half3 vertexLight : TEXCOORD7;
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                float4 shadowCoord : TEXCOORD8;
                #endif
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 9);
            };

            TEXTURE2D(_CliffTex);
            SAMPLER(sampler_CliffTex);
            TEXTURE2D(_CliffNormalAO);
            SAMPLER(sampler_CliffNormalAO);
            TEXTURE2D(_GrassBaseMap);
            SAMPLER(sampler_GrassBaseMap);
            TEXTURE2D(_GrassNormal);
            SAMPLER(sampler_GrassNormal);
            TEXTURE2D(_RockDetail);
            SAMPLER(sampler_RockDetail);

            CBUFFER_START(UnityPerMaterial)
            float4 _CliffTex_ST;
            float4 _CliffNormalAO_ST;
            float _CliffNormalScale;
            half _RockSmoothness;
            half _GrassHeightBlend;
            half _GrassAngle;
            half _DetailScale;
            CBUFFER_END

            // 草と岩が互いに混ざり合っている場所のマスクを作成する
            // ワールド空間の「Y」位置と法線に基づき生成する
            // これにより、草の表面と岩の表面の間の補完で使用できる白黒のマスクが生成される
            float GrassMask(float worldPositionY, float worldSpaceNormalY)
            {
                // ワールド空間のYを元にどのくらいブレンドするか決める
                half blendHeight = 10;
                float blendRate = smoothstep(_GrassHeightBlend - blendHeight, _GrassHeightBlend + blendHeight, worldPositionY);
                float mask = blendRate * worldSpaceNormalY;

                // _GrassAngleが大きいほうが草を生やしたいので1から減算
                // _GrassAngleが0~100で、maskに入ってくる値が0~1なので、合わせるために0.01を乗算
                float oneMinusAngle = 1 - (_GrassAngle * 0.01f);

                // なめらかにするために、軽微な値で保管する
                return 1 - saturate(smoothstep(oneMinusAngle - 0.05f, oneMinusAngle + 0.05f, mask));
            }

            // 接空間をワールド空間へと変換する
            float3 ConvertWorldSpaceNormal(half3 cliffNormal, float3 normal, float3 tangent, float3 binormal)
            {
                float3x3 transposeTangent = transpose(float3x3(tangent, binormal, normal));
                float3 worldNormal = mul(transposeTangent, cliffNormal).xyz;
                return worldNormal;
            }

            // オブジェクトのスケールを使用し、サンプリングするディティールテクスチャのUVもスケールさせる
            float3 DetailRockNormal(float2 uv)
            {
                // Length(Model座標の同じ行の1~3列目)で各スケールが取得できる
                float scaleX = length(float3(unity_ObjectToWorld[0].x, unity_ObjectToWorld[1].x, unity_ObjectToWorld[2].x));
                float scaleY = length(float3(unity_ObjectToWorld[0].y, unity_ObjectToWorld[1].y, unity_ObjectToWorld[2].y));
                float scaleZ = length(float3(unity_ObjectToWorld[0].z, unity_ObjectToWorld[1].z, unity_ObjectToWorld[2].z));
                float scaleLength = length(float3(scaleX, scaleY, scaleZ)) * _DetailScale * 30;

                float2 tilingOffset = uv * scaleLength;

                return UnpackNormal(SAMPLE_TEXTURE2D(_RockDetail, sampler_RockDetail, tilingOffset));
            }
            
            // リマップ
            float Remap(half In, half2 InMinMax, half2 OutMinMax)
            {
                return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
            }

            // ワールド空間のY座標に基づき、水が濡れている場所（0）と乾いている場所（1）を定義するマスクを作成する
            // また、完全に水没している場合は、水面が濡れているようには見えないので、乾燥状態（1）にします。
            // また、AOマップを使用して、ひび割れや隙間の濡れた状態をより鮮明に表現しています。
            float WetnessMask(float cliffAO, float worldPositionY)
            {
                // 適応させるAOを計算
                float cliffAOBase = ((cliffAO - 0.5) * 4 + worldPositionY) * 0.33;
                // 濡れている場所が0,乾いている場所が1なので反転させる
                float remapY = Remap(worldPositionY, half2(-1, -0.25), half2(1, 0));
                // しきい値以下は濡れているような表現をする必要がないので1にする
                float mask = max(cliffAOBase, remapY);
                return clamp(mask, 0.1, 1);
            }

            // 岩のSmoothnessをRチャンネルとAチャンネルに格納されている情報を元に作成する
            float RockSmoothness(float cliffA, float cliffR)
            {
                float cliff = 1 - abs(cliffA - 0.5);
                return cliff * cliffR * _RockSmoothness;
            }

            // PBR
            half4 CreateSurfaceData(float4 col, float3 normalTS, half occlusion, half smoothness, Varyings IN)
            {
                SurfaceData surfaceData;
                surfaceData.albedo = col.rgb;
                surfaceData.alpha = col.a;
                surfaceData.normalTS = normalTS;
                surfaceData.emission = 0;
                surfaceData.metallic = 0.1;
                surfaceData.occlusion = occlusion;
                surfaceData.smoothness = smoothness;
                surfaceData.specular = 0;
                surfaceData.clearCoatMask = 0;
                surfaceData.clearCoatSmoothness = 0;

                InputData inputData = (InputData)0;
                inputData.positionWS = IN.positionWS;
                inputData.normalWS = NormalizeNormalPerPixel(TransformTangentToWorld(surfaceData.normalTS, float3x3(IN.tangentWS.xyz, IN.binormalWS.xyz, IN.normalWS.xyz)));
                inputData.viewDirectionWS = SafeNormalize(IN.viewDir);
                inputData.fogCoord = IN.fogFactor;
                inputData.vertexLighting = IN.vertexLight;
                inputData.bakedGI = SAMPLE_GI(IN.lightmapUV, IN.vertexSH, inputData.normalWS);
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.positionHCS);
                inputData.shadowMask = SAMPLE_SHADOWMASK(IN.lightmapUV);
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    inputData.shadowCoord = IN.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    inputData.shadowCoord = TransformWorldToShadowCoord(IN.positionWS);
                #else
                    inputData.shadowCoord = float4(0, 0, 0, 0);
                #endif

                half4 color = UniversalFragmentPBR(inputData, surfaceData);
                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                return color;
            }

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.uv = TRANSFORM_TEX(IN.uv, _CliffTex);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.positionHCS = TransformWorldToHClip(OUT.positionWS);
                OUT.tangentWS = TransformObjectToWorldDir(IN.tangentOS.xyz);
                OUT.binormalWS = IN.tangentOS.w * cross(OUT.normalWS, OUT.tangentWS);
                OUT.viewDir = GetWorldSpaceViewDir(OUT.positionWS);
                OUT.vertexLight = VertexLighting(OUT.positionWS, OUT.normalWS);
                OUT.fogFactor = ComputeFogFactor(OUT.positionHCS.z);
                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, OUT.lightmapUV);
                OUTPUT_SH(OUT.normalWS.xyz, OUT.vertexSH);
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    OUT.shadowCoord = TransformWorldToShadowCoord(OUT.positionWS);
                #endif
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                // 草の密度
                float2 glassUv = IN.uv * 4;
                half4 grassColor = SAMPLE_TEXTURE2D(_GrassBaseMap, sampler_GrassBaseMap, glassUv);
                half3 grassNormal = UnpackNormal(SAMPLE_TEXTURE2D(_GrassNormal, sampler_GrassNormal, glassUv));

                half4 cliffColor = SAMPLE_TEXTURE2D(_CliffTex, sampler_CliffTex, IN.uv);

                // 崖のテクスチャでは、法線とAO（アンビエントオクルージョン）を同じアセットにパックしているため。Unpackはしない
                // この場合、法線マップデータを入力テクスチャの0-1の範囲から、法線ベクトルがある-1-1にリマップする必要がある
                // また、AOは法線よりも圧縮することができるので、RGBではなくGBAチャンネルを使用している
                half4 cliffNormalAO = SAMPLE_TEXTURE2D(_CliffNormalAO, sampler_CliffNormalAO, IN.uv);
                half3 cliffNormal = half3(cliffNormalAO.a, cliffNormalAO.g, cliffNormalAO.b) * 2 - 1;

                float3 worldSpaceNormal = ConvertWorldSpaceNormal(cliffNormal, IN.normalWS, IN.tangentWS, IN.binormalWS);
                float grassMask = GrassMask(IN.positionWS.y, worldSpaceNormal.y);

                float3 detailRockNormal = DetailRockNormal(IN.uv);

                // ホワイトアウトブレンディングをする
                float3 blendRockNormalCliffNormal = normalize(float3(cliffNormal.rg + detailRockNormal.rg, cliffNormal.b * detailRockNormal.b));
                float3 normal = lerp(grassNormal, blendRockNormalCliffNormal, grassMask);

                float wetnessMask = WetnessMask(cliffColor.a, IN.positionWS.y);
                float rockSmoothness = RockSmoothness(cliffColor.a, cliffColor.r) * grassMask;
                float smoothness = lerp(0.85, rockSmoothness, wetnessMask);

                float rockOcclusion = cliffNormalAO.r;
                half4 blendGrassBase = lerp(grassColor, cliffColor, grassMask) * wetnessMask;

                return CreateSurfaceData(blendGrassBase, normal, rockOcclusion, smoothness, IN);
            }
            ENDHLSL
        }
    }
}