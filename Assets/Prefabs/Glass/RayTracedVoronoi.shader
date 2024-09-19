Shader "Custom/RayTracedVoronoi"
{
    Properties
    {
        _CubeSize("Cube Size", Float) = 5
        _MaxBounces("Max Bounces", Int) = 5
        _BorderThickness("Border Thickness", Float) = 0.05
        _BorderColor("Border Color", Color) = (0, 0, 0, 1)
        _BackgroundColor("Background Color", Color) = (0, 0, 0, 1)
        _ColorIntensity("Color Intensity", Float) = 1.5
        _AnimationSpeed("Animation Speed", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off // 内側から見えるようにカリングをオフにします。

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            float _CubeSize;
            int _MaxBounces;
            float _BorderThickness;
            float4 _BorderColor;
            float4 _BackgroundColor;
            float _ColorIntensity;
            float _AnimationSpeed;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            // ランダムな値を生成する関数
            float rand(float3 co)
            {
                return frac(sin(dot(co, float3(12.9898, 78.233, 45.164))) * 43758.5453);
            }

            // ボロノイ図の計算
            void Voronoi(float3 p, out float minDist, out float3 cellID)
            {
                float3 pi = floor(p);
                float3 pf = frac(p);
                minDist = 1.0;
                cellID = pi;

                for (int x = -1; x <= 1; x++)
                {
                    for (int y = -1; y <= 1; y++)
                    {
                        for (int z = -1; z <= 1; z++)
                        {
                            float3 neighbor = float3(x, y, z);
                            float3 pointPos = neighbor + rand(pi + neighbor);
                            float dist = length(pf - pointPos);
                            if (dist < minDist)
                            {
                                minDist = dist;
                                cellID = pi + neighbor;
                            }
                        }
                    }
                }
            }

            half4 frag(v2f i) : SV_Target
            {
                // レイの原点と方向
                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDir = normalize(i.worldPos - _WorldSpaceCameraPos);

                // キューブの境界
                float3 boxMin = float3(-_CubeSize, -_CubeSize, -_CubeSize);
                float3 boxMax = float3(_CubeSize, _CubeSize, _CubeSize);

                float3 color = _BackgroundColor.rgb; // 背景色を初期値に設定
                float3 atten = float3(1, 1, 1);

                int maxBounces = _MaxBounces;

                [loop]
                for (int bounce = 0; bounce < maxBounces; ++bounce)
                {
                    float tMin, tMax;
                    // レイとボックスの交差判定
                    bool hitBox = true;
                    {
                        float3 invDir = 1.0 / rayDir;
                        float3 t0s = (boxMin - rayOrigin) * invDir;
                        float3 t1s = (boxMax - rayOrigin) * invDir;

                        float3 tsmaller = min(t0s, t1s);
                        float3 tbigger = max(t0s, t1s);

                        tMin = max(max(tsmaller.x, tsmaller.y), tsmaller.z);
                        tMax = min(min(tbigger.x, tbigger.y), tbigger.z);

                        if (tMax < max(tMin, 0.0))
                        {
                            hitBox = false;
                        }
                    }

                    if (!hitBox)
                    {
                        break;
                    }

                    // レイを交点まで進める
                    float t = tMin > 0 ? tMin : tMax;
                    if (t < 0)
                    {
                        break;
                    }

                    rayOrigin = rayOrigin + rayDir * t;

                    // 当たった面の法線を取得
                    float3 hitNormal = float3(0, 0, 0);
                    {
                        float epsilon = 1e-4;
                        if (abs(rayOrigin.x - boxMin.x) < epsilon) hitNormal = float3(-1, 0, 0);
                        else if (abs(rayOrigin.x - boxMax.x) < epsilon) hitNormal = float3(1, 0, 0);
                        else if (abs(rayOrigin.y - boxMin.y) < epsilon) hitNormal = float3(0, -1, 0);
                        else if (abs(rayOrigin.y - boxMax.y) < epsilon) hitNormal = float3(0, 1, 0);
                        else if (abs(rayOrigin.z - boxMin.z) < epsilon) hitNormal = float3(0, 0, -1);
                        else if (abs(rayOrigin.z - boxMax.z) < epsilon) hitNormal = float3(0, 0, 1);
                    }

                    // レイを反射
                    rayDir = reflect(rayDir, hitNormal);

                    // ボロノイ図の計算
                    float3 p = rayOrigin * 0.2 + _Time.y * _AnimationSpeed; // スケール調整と動きの追加
                    float minDist;
                    float3 cellID;
                    Voronoi(p, minDist, cellID);

                    // 境界の描画
                    float edgeThickness = _BorderThickness;
                    if (minDist < edgeThickness)
                    {
                        color = lerp(color, _BorderColor.rgb * _ColorIntensity, atten);
                    }
                    else
                    {
                        // 細胞ごとにランダムな色を生成し、鮮やかさを向上
                        float3 cellColor = float3(
                            rand(cellID + 0.1),
                            rand(cellID + 0.2),
                            rand(cellID + 0.3)
                        );
                        cellColor = saturate(cellColor * _ColorIntensity);
                        color = lerp(color, cellColor, atten);
                    }

                    // 色の減衰
                    atten *= 0.8; // 反射ごとに減衰
                }

                // 最終的な色を返す
                return float4(color, 1.0);
            }

            ENDCG
        }
    }
}
