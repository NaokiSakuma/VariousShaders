float RecursiveTetrahedron(float3 p, half3 offset, half scale)
{
    float4 z = float4(p, 1.0);

    for (int i = 0; i < 8; i++)
    {
        if (z.x + z.y < 0.0)
        {
            z.xy = -z.yx;
        }

        if (z.x + z.z < 0.0)
        {
            z.xz = -z.zx;
        }

        if (z.y + z.z < 0.0)
        {
            z.zy = -z.yz;
        }

        z *= scale;
        z.xyz -= offset * (scale - 1.0);

        // 適当に動かす
        z.xyz += sin(_Time.y) * 0.5;
    }

    return (length(z.xyz) - 1.5) / z.w;
}


float Dest(float3 p)
{
    return RecursiveTetrahedron(p, 1.0, 2.0);
}

float3 CalcNormal(float3 p)
{
    // 勾配
    float2 ep = float2(0, 0.001);
    return normalize(
        float3(
            Dest(p + ep.yxx) - Dest(p),
            Dest(p + ep.xyx) - Dest(p),
            Dest(p + ep.xxy) - Dest(p)
            ));
}

// 精度のサフィックスを指定する必要がある
void RayMarching_float(float3 rayPosition, float3 rayDirection,
    out bool hit, out float3 hitPosition, out float3 hitNormal)
{
    float3 pos = rayPosition;

    for (int i = 0; i < 64; i++)
    {
        float d = Dest(pos);
        pos += d * rayDirection;

        if (d < 0.001)
        {
            hit = true;
            hitPosition = pos;
            hitNormal = CalcNormal(pos);
            return;
        }
    }
}
