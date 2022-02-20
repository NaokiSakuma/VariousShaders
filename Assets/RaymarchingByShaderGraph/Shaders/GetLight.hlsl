void GetLight_float(out float3 direction, out half3 color)
{
    // shader graphのpreviewからライトを取得できないので適当な値を渡す
    #ifdef SHADERGRAPH_PREVIEW
    direction = half3(0.5, 0.5, 0);
    color = 1;
    #else
    Light light = GetMainLight();
    direction = light.direction;
    color = light.color;
    #endif
}
