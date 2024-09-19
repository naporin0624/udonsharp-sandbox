Shader "Custom/BlueFlame"
{
    Properties
    {
        _CubeSize("Cube Size", Float) = 5
        _MaxBounces("Max Bounces", Int) = 10
        _FlameIntensity("Flame Intensity", Float) = 1.0
        _FlameSpeed("Flame Speed", Float) = 1.0
        _FlameScale("Flame Scale", Float) = 1.0
        _NoiseTex3D("Noise Texture 3D", 3D) = "" {}
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
            float _FlameIntensity;
            float _FlameSpeed;
            float _FlameScale;

            sampler3D _NoiseTex3D; // 3Dノイズテクスチャ

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            // レイとボックスの交差判定
            bool RayBoxIntersection(float3 rayOrigin, float3 rayDir, float3 boxMin, float3 boxMax, out float tMin, out float tMax)
            {
                float3 invDir = 1.0 / rayDir;
                float3 t0s = (boxMin - rayOrigin) * invDir;
                float3 t1s = (boxMax - rayOrigin) * invDir;

                float3 tsmaller = min(t0s, t1s);
                float3 tbigger = max(t0s, t1s);

                tMin = max(max(tsmaller.x, tsmaller.y), tsmaller.z);
                tMax = min(min(tbigger.x, tbigger.y), tbigger.z);

                return tMax >= max(tMin, 0.0);
            }

            half4 frag(v2f i) : SV_Target
            {
                // レイの原点と方向
                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDir = normalize(i.worldPos - _WorldSpaceCameraPos);

                // キューブの境界
                float3 boxMin = float3(-_CubeSize, -_CubeSize, -_CubeSize);
                float3 boxMax = float3(_CubeSize, _CubeSize, _CubeSize);

                float3 color = float3(0, 0, 0);
                float3 atten = float3(1, 1, 1);

                int maxBounces = _MaxBounces;

                [loop]
                for (int bounce = 0; bounce < maxBounces; ++bounce)
                {
                    float tMin, tMax;
                    if (!RayBoxIntersection(rayOrigin, rayDir, boxMin, boxMax, tMin, tMax))
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
                    float epsilon = 1e-4;

                    if (abs(rayOrigin.x - boxMin.x) < epsilon) hitNormal = float3(-1, 0, 0);
                    else if (abs(rayOrigin.x - boxMax.x) < epsilon) hitNormal = float3(1, 0, 0);
                    else if (abs(rayOrigin.y - boxMin.y) < epsilon) hitNormal = float3(0, -1, 0);
                    else if (abs(rayOrigin.y - boxMax.y) < epsilon) hitNormal = float3(0, 1, 0);
                    else if (abs(rayOrigin.z - boxMin.z) < epsilon) hitNormal = float3(0, 0, -1);
                    else if (abs(rayOrigin.z - boxMax.z) < epsilon) hitNormal = float3(0, 0, 1);

                    // レイを反射
                    rayDir = reflect(rayDir, hitNormal);

                    // 炎のパーティクルを生成
                    float3 flamePos = rayOrigin;

                    // 3Dノイズを使用して炎の形状を作成
                    float3 noiseCoord = flamePos * _FlameScale + float3(0, _Time.y * _FlameSpeed, 0);
                    float noiseValue = tex3D(_NoiseTex3D, frac(noiseCoord)).r;
                    float flameThreshold = 0.5;

                    if (noiseValue > flameThreshold)
                    {
                        float intensity = (noiseValue - flameThreshold) / (1.0 - flameThreshold);
                        color += atten * float3(0.0, 0.5, 1.0) * intensity * _FlameIntensity;
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
