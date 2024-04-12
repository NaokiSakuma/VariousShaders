#ifndef OUTLINE_NORMAL_INCLUDED
#define OUTLINE_NORMAL_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
};

struct Varyings
{
    float4 positionHCS : SV_POSITION;
    // lfloat2 uv : TEXCOORD0;
};


CBUFFER_START(UnityPerMaterial)
    float _OutlineWidth;
    half4 _OutlineColor;
CBUFFER_END

Varyings vert(Attributes IN)
{
    
    Varyings OUT;

    float3 normalWS = TransformObjectToWorldNormal(IN.normal);
    float3 normalCS = TransformWorldToHClipDir(normalWS);
    VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
    OUT.positionHCS = positionInputs.positionCS + float4(normalCS.xy * 0.001 * _OutlineWidth , 0, 0);
    
    return OUT;
}

half4 frag(Varyings IN) : SV_Target
{
    // half4 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
    return _OutlineColor;
}


#endif
