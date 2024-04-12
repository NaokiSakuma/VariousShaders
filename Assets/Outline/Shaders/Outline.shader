Shader "Outline/Normal"
{
    Properties
    {
        [Header(Forward)]
        _MainTex ("Texture", 2D) = "white" {}
        _ForwardColor ("Foraward Color", Color) = (1, 1, 1, 1)
        
        [Header(Outline)]
        _OutlineWidth ("Outline Width", float) = 1
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
        }
        
        Pass
        {
            Name "Forward"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
                #include "Forward.hlsl"
                #pragma vertex vert
                #pragma fragment frag
            ENDHLSL
        }
        
        Pass
        {
            Name "OutlineNormal"

            Tags
            {
                "LightMode" = "OutlineNormal"
            }
            
            Cull Front
            ZWrite On

            HLSLPROGRAM
                #include "OutlineNormal.hlsl"
                #pragma vertex vert
                #pragma fragment frag
            ENDHLSL
        }
    }
}
