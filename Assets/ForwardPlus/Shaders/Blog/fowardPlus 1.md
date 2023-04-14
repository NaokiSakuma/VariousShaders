= UnityにおけるForward+

== はじめに

最近、モバイルにおけるUnityのレンダリングパイプラインはURPが主流になりつつあります。
URPのアップデートによる新しい機能の追加に伴い、より幅広い表現ができるようになっています。
そこで、この章ではUniversalRP14から追加された Forward+ Rendering Path について深掘りしていきます。
※UniversalRP12で追加されていますが、experimentalなため14とさせて頂きます。

== 動作環境

Unity 2022.2.2f1
Universal RP 14.0.4

== レンダリングの手法

どのようなレンダリング手法があるのか、またどういった特徴があるのかを挙げさせていただきます。

=== Forward Renderingとは

一般的なレンダリング手法で、Unityでデフォルトのレンダリング設定になっています。

Unityでは、 BasePass と AdditionalPass で行われ、どちらも各ピクセル単位でライトの計算を行います。
この処理はライトごとに行われるため、ライトが増えれば増えるほどパフォーマンスに影響が出てきてしまいます。
そのためリアルタイムライトの数は制限されており、最大8つとなっています。

=== Deferred Renderingとは

リアルタイムライトの数の制限を無くしたレンダリング手法で、UE4だとデフォルトのレンダリング設定のものになります。
 DeferredRendering では、フラグメントシェーダーでライティングの計算を行わず、ラスタライズ時に G-Buffer という独自のテクスチャにライトの情報を書き込みます。
具体的には、 Diffuse や Specular 、 Normal といったものがあります。
この G-Buffer を元にライティングを行うので、リアルタイムライトの数の制限がありません。

これだけ聞くと DeferredRendering の方が良さそうですが、欠点があります。
一例を挙げると、半透明の描画が苦手です。
ラスタライズ時に G-Buffer に情報をテクスチャに書き込みます。
この段階ではブレンドを行うことが出来ず、不透明と半透明の情報を同時に保持することができません。
そうなるとオブジェクト同士の前後関係が無くなってしまいます。
これを防ぐためにForwardパスが使用されるのですが、そうなると DeferredRendering の強みがなくなってしまいます。

また、Unityではカメラスタッキングにも影響が出てきてしまいます。
 RenderType が Base のカメラは DeferredRendering パスで描画されますが、 Overlay のカメラは ForwardRendering パスで描画されてしまいます。
※ Universal RP 14.0.4 時点では、そもそも Overlay が選択できなくなっています。

=== Forward+ Renderingとは

そこで、ForwardRenderingの良いところも残しつつ多数のリアルタイムライトに対応したのがこのレンダリング手法になります。
まず、カメラ視錐台をいくつかのグリッド上に区切ります。
このグリッドの大きさはは8x8や16x16、32x32などがあり16x16が一般的のようです。
次にライトのカリングを行います。
先程計算したグリッドに影響があるライトを計算し、リストとして分割します。
最後に、ピクセルをレンダリングする際に、そのピクセルのスクリーン上の位置を計算し、ライトのリストから自身のピクセルと影響のあるライトのみを取り出してきて、シェーディングを行います。

 ForwardRendering では、この際に全てのリアルタイムライトからライトの影響を計算してしまいますが、 Forward+Rendering ですと事前に計算しているので、多光源にも対応することが可能になります。

このレンダリング手法が最適解のように見えますが、この手法にもデメリットが存在します。
事前にカメラ視錐台をグリッド上に区切るのが前提の手法となっています。
なので、そもそもライトが存在しなかったりライトが1個といったライトの影響がオブジェクトに対して限りなく少ない場合、 ForwardRendering の方が早い可能性があります。

また、Unityでも2つ影響があります。

1つめは対応していないものがあることです。
具体的には、XRプラットフォーム、そして Orthographic なカメラになります。
以下forumに対応予定とは記載していますが Universal RP 14.0.4 時点では未実装になります。
https://forum.unity.com/threads/forward-rendering-in-2022-2-beta.1340198/

また、実際に Forward+Rendering でカメラを Orthographic に変えると以下の警告がでます。

//image[nsakuma/OrthographicWarning][Orthographicに変えたときの警告]{
//}

2つめはプラットフォーム毎にライトの制限があることです。
オブジェクトに対して影響を与えるライトの数に制限はないようですが、カメラごとには制限があるようです。

* デスクトップ、コンソール : 256個
* モバイル(OpenGL ES 3.0以上) : 32個
* モバイル(OpenGL ES 3.0以前) : 16個

== UnityでのForward+Renderingの設定方法

設定方法は Universal Renderer Data の Rendering/Rendering Path から Forward+ を選択するだけです。

//image[nsakuma/ForwardPlusSettings][Forward+Renderingの設定方法]{
//}

 Forward+ を選択することによって、 Universal Render Pipeline Asset の Lighting の項目にいくつか影響がでます。

*  Main Light  : 選択した値に関係なく、 Per Pixel 扱いとなります
*  Additional Lights  : 選択した値に関係なく、 Per Pixel 扱いとなります
*  Additional Lights/Per Object Limit  : ここで選択した値を無視します
*  Reflection Probes/Probe Blending  : 選択した値に関係なく、常にチェックボックスが入っている扱いとなります

== 自前でPBRレンダリングのForwardPlusを書いてみる

これでUnityのレンダリングパスが Forward+ になりました。
URPのデフォルトで存在する Lit や SimpleLit マテリアルをオブジェクトにアタッチすることで複数リアルタイムライトがあっても反映されているかと思います。

実際にどのように動いているのかを調べるため中身を深堀りしていきます。
以下が一番シンプルな Forward+Rendering に対応したシェーダーになります。

//emlist{
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

                // Forward+用のバリアント
                #pragma multi_compile _ _FORWARD_PLUS
            ENDHLSL
        }
    }
}
//}

やっていることはコメントにも記載していますが、

*  UniversalFragmentPBR を呼び出して、PBRでレンダリングを行う
* Forward+用のバリアントである、 _FORWARD_PLUS を定義する

の2つで実装できます。

== Forward+の中身を読む

 UniversalFragmentPBR でライトの計算を行ってくれていることがわかりました。
具体的にどのような処理で行っているのかを読んでみます。

=== C#側

 ForwardLights.cs で行われています。
中身まで見ると、少し長いので割愛しながら見ていきます。

==== 視錐台の計算

まずは視錐台の計算をし、各ライトがグリッド内に収まっているかを見ます。
 JobSystem + Burst で並列処理を高速で行っています。

//emlist{
// 視錐台計算のjob
var tilingJob = new TilingJob
{
    lights = visibleLights,
    reflectionProbes = reflectionProbes,
    tileRanges = tileRanges,
    itemsPerLight = itemsPerLight,
    worldToViewMatrix = worldToViewMatrix,
    tileScale = (float2)screenResolution / m_ActualTileWidth,
    tileScaleInv = m_ActualTileWidth / (float2)screenResolution,
    viewPlaneHalfSize = fovHalfHeight * math.float2(renderingData.cameraData.aspectRatio, 1),
    viewPlaneHalfSizeInv = math.rcp(fovHalfHeight * math.float2(renderingData.cameraData.aspectRatio, 1)),
    tileCount = m_TileResolution,
    near = camera.nearClipPlane,
};

var tileRangeHandle = tilingJob.ScheduleParallel(itemsPerTile, 1, reflectionProbeMinMaxZHandle);
//}

==== シェーダーに値を渡す

以下で配列にライトの値を格納し、シェーダーに値を渡しています。

//emlist{
for (int i = 0, lightIter = 0; i < lights.Length && lightIter < maxAdditionalLightsCount; ++i)
{
    VisibleLight light = lights[i];
    if (lightData.mainLightIndex != i)
    {
        // 配列にライトの値を格納
        InitializeLightConstants(lights, i, out m_AdditionalLightPositions[lightIter],
            out m_AdditionalLightColors[lightIter],
            out m_AdditionalLightAttenuations[lightIter],
            out m_AdditionalLightSpotDirections[lightIter],
            out m_AdditionalLightOcclusionProbeChannels[lightIter],
            out _,
            out var isSubtractive);
        m_AdditionalLightColors[lightIter].w = isSubtractive ? 1f : 0f;
        lightIter++;
    }
}

// シェーダー側に値を渡す
cmd.SetGlobalVectorArray(LightConstantBuffer._AdditionalLightsPosition, m_AdditionalLightPositions);
cmd.SetGlobalVectorArray(LightConstantBuffer._AdditionalLightsColor, m_AdditionalLightColors);
cmd.SetGlobalVectorArray(LightConstantBuffer._AdditionalLightsAttenuation, m_AdditionalLightAttenuations);
cmd.SetGlobalVectorArray(LightConstantBuffer._AdditionalLightsSpotDir, m_AdditionalLightSpotDirections);
cmd.SetGlobalVectorArray(LightConstantBuffer._AdditionalLightOcclusionProbeChannel, m_AdditionalLightOcclusionProbeChannels);
cmd.SetGlobalFloatArray(LightConstantBuffer._AdditionalLightsLayerMasks, m_AdditionalLightsLayerMasks);
//}

=== シェーダー側

以下は UniversalFragmentPBR が定義されている Lighting.hlsl のForward+部分になります。

//emlist{
    #if USE_FORWARD_PLUS
    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                                          surfaceData.clearCoatMask, specularHighlightsOff);
        }
    }
    #endif
//}

==== ライトのインデックス

まずはfor文でライトのインデックスを取得しています。

//emlist{
// URP_FP_DIRECTIONAL_LIGHTS_COUNT : DirectionalLightの数
// MAX_VISIBLE_LIGHTS : プラットフォームごとのライトの制限、モバイルなら32個
for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
{
    // Forward+かつ、ライトマップが有効かつ、ライトマップの影の混合が有効なときに
    // if (_AdditionalLightsColor[lightIndex].a > 0.0h) continue;
    // が定義される
    FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK
//}

ライティングのモードが Subtractive ですと、ライトマップにベイクしている影の上にリアルタイムライトによる影が落ちてしまい、見栄えが悪くなるのでcontinueしているようです。

==== ライトの取得

次にインデックスをもとに、ライトの情報を取得します。

//emlist{
Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
//}

 GetAdditionalLight は以下のようになっています。
 Forward+ の場合、引数に渡したインデックスそのままが使用されており、他の場合はライトの制限があるので加工されて使用されています。

//emlist{
Light GetAdditionalLight(uint i, InputData inputData, half4 shadowMask, AmbientOcclusionFactor aoFactor)
{
    Light light = GetAdditionalLight(i, inputData.positionWS, shadowMask);

    // 省略

    return light;
}

Light GetAdditionalLight(uint i, float3 positionWS, half4 shadowMask)
{
#if USE_FORWARD_PLUS
    // indexそのままの値が使用される
    int lightIndex = i;
#else
    // ライトの数に制限があるので加工される
    int lightIndex = GetPerObjectLightIndex(i);
#endif
    Light light = GetAdditionalPerObjectLight(lightIndex, positionWS);

    // 省略

    return light;
}
//}

インデックスとワールド空間の座標を元にライトの情報を取得します。<br>
 _AdditionalLightsPosition や _AdditionalLightsColor には既にC#側で値が格納されています。

//emlist{
Light GetAdditionalPerObjectLight(int perObjectLightIndex, float3 positionWS)
{
    // Vulkanでバインディングが出来ないので、現状常にfalseとなる
#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
    float4 lightPositionWS = _AdditionalLightsBuffer[perObjectLightIndex].position;
    half3 color = _AdditionalLightsBuffer[perObjectLightIndex].color.rgb;
    half4 distanceAndSpotAttenuation = _AdditionalLightsBuffer[perObjectLightIndex].attenuation;
    half4 spotDirection = _AdditionalLightsBuffer[perObjectLightIndex].spotDirection;
    uint lightLayerMask = _AdditionalLightsBuffer[perObjectLightIndex].layerMask;
#else
    float4 lightPositionWS = _AdditionalLightsPosition[perObjectLightIndex];
    half3 color = _AdditionalLightsColor[perObjectLightIndex].rgb;
    half4 distanceAndSpotAttenuation = _AdditionalLightsAttenuation[perObjectLightIndex];
    half4 spotDirection = _AdditionalLightsSpotDir[perObjectLightIndex];
    uint lightLayerMask = asuint(_AdditionalLightsLayerMasks[perObjectLightIndex]);
#endif

    // DirectionalライトはlightPositionWS.xyzに方向が入っており、wには0が入っています。
    // なので以下のように計算すると、Directionalライトでも、他のPointやSpotでも機能します。
    float3 lightVector = lightPositionWS.xyz - positionWS * lightPositionWS.w;
    float distanceSqr = max(dot(lightVector, lightVector), HALF_MIN);

    half3 lightDirection = half3(lightVector * rsqrt(distanceSqr));
    float attenuation = DistanceAttenuation(distanceSqr, distanceAndSpotAttenuation.xy) * AngleAttenuation(spotDirection.xyz, lightDirection, distanceAndSpotAttenuation.zw);

    Light light;
    light.direction = lightDirection;
    light.distanceAttenuation = attenuation;
    light.shadowAttenuation = 1.0;
    light.color = color;
    light.layerMask = lightLayerMask;

    return light;
}
//}

==== ライティング

最後に、レイヤー対応とBRDFライティングで終了になります。

//emlist{
#ifdef _LIGHT_LAYERS
        // レイヤーが同じか
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            // BRDFライティング
            lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                                          surfaceData.clearCoatMask, specularHighlightsOff);
        }
    }
    #endif
//}

ですので、PBRやBRDF以外でリアルタイムライトの計算を行いたい場合は、以下で可能になります。

//emlist{
#if USE_FORWARD_PLUS
    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
    }
#endif
//}

== パフォーマンス

今回は簡易的に Statistics で行いました。
また、シンプルにPlaneの上に適当にPointLightを並べて検証しています。

//image[nsakuma/SimplePlane][検証したScene]{
//}

 UniversalRendererData の設定は以下になります。

//image[nsakuma/UniversalRendererPipelineSettings][UniversalRendererData の設定]{
//}


=== ライト8個

//table[forward8][Forward]{
.	1回目	2回目	3回目
\--------------------------------------------
CPU	12.1ms	13.9ms	11.6ms
renderer thread	1.6ms	3.9ms	1.6ms
//}

//table[forwardPlus8][Forward+]{
.	1回目	2回目	3回目
\--------------------------------------------
CPU	14.0ms	12.9ms	13.9ms
renderer thread	2.4ms	2.3ms	3.0ms
//}

=== ライト32個

//table[forward32][Forward]{
.	1回目	2回目	3回目
\--------------------------------------------
CPU	13.2ms	12.8ms	14.6ms
renderer thread	1.6ms	2.2ms	3.5ms
//}

//table[forwardPlus32][Forward+]{
.	1回目	2回目	3回目
\--------------------------------------------
CPU	14.7ms	14.6ms	13.6ms
renderer thread	1.7ms	1.9ms	1.8ms
//}

=== ライト256個

//table[forward256][Forward]{
.	1回目	2回目	3回目
\--------------------------------------------
CPU	10.5ms	9.3ms	10.5ms
renderer thread	2.7ms	2.7ms	3.0ms

//table[forwardPlus256][Forward+]{
.	1回目	2回目	3回目
\--------------------------------------------
CPU	107.0ms	75.2ms	60.3ms
renderer thread	2.9ms	3.2ms	3.2ms

デスクトップの限界である256までやるとさすがに重いですが、32個程度でしたら ForwardRendering と同パフォーマンスでリアルタイムライトを配置できるので良さそうに見えます。<br>
256で顕著に差が出る理由は、

*  USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA が常にfalseで Forward+Rendering がまだ最適化しきれていない
*  ForwardRendering 側でライトを間引いている

のが要因なのかなと思います。
まだLTSではないので、LTSが来たらもっと良くなっているかもしれません。

== まとめ

 Universal RP 14.0.4 時点ではXRプラットフォームと、 Orthographic カメラで Forward+Rendering の影響を受けることは出来ないですがそれでもプロジェクトによっては利用する価値があるのではないでしょうか。
リアルタイムライトを複数使うことでよりリッチな表現にチャレンジしていけたら良いなと思います。

== 参考文献

* Forward vs Deferred vs Forward+ Rendering with DirectX 11 https://www.3dgep.com/forward-plus/
* Forward+ Rendering Path https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@14.0/manual/rendering/forward-plus-rendering-path.html