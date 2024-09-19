Shader "Custom/InfiniteSpinningCube"
{
    Properties
    {
        _CubeSize("Cube Size", Float) = 5
        _ObjectSize("Object Size", Float) = 1
        _MaxBounces("Max Bounces", Int) = 10
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
            #include "UnityShaderVariables.cginc"

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
            float _ObjectSize;
            int _MaxBounces;

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

            // レイと球体の交差判定
            bool RaySphereIntersection(float3 rayOrigin, float3 rayDir, float3 sphereCenter, float sphereRadius, out float t)
            {
                float3 oc = rayOrigin - sphereCenter;
                float a = dot(rayDir, rayDir);
                float b = 2.0 * dot(oc, rayDir);
                float c = dot(oc, oc) - sphereRadius * sphereRadius;
                float discriminant = b * b - 4 * a * c;
                if (discriminant < 0)
                {
                    t = -1.0;
                    return false;
                }
                else
                {
                    float sqrtDisc = sqrt(discriminant);
                    float t0 = (-b - sqrtDisc) / (2.0 * a);
                    float t1 = (-b + sqrtDisc) / (2.0 * a);

                    t = t0;
                    if (t < 0) t = t1;
                    return t >= 0;
                }
            }

            float3 Reflect(float3 dir, float3 normal)
            {
                return dir - 2.0 * dot(dir, normal) * normal;
            }

            float3 GetNormalAtBoxSurface(float3 pos, float3 boxMin, float3 boxMax)
            {
                float3 normal = float3(0, 0, 0);
                float epsilon = 1e-4;

                if (abs(pos.x - boxMin.x) < epsilon) normal = float3(-1, 0, 0);
                else if (abs(pos.x - boxMax.x) < epsilon) normal = float3(1, 0, 0);
                else if (abs(pos.y - boxMin.y) < epsilon) normal = float3(0, -1, 0);
                else if (abs(pos.y - boxMax.y) < epsilon) normal = float3(0, 1, 0);
                else if (abs(pos.z - boxMin.z) < epsilon) normal = float3(0, 0, -1);
                else if (abs(pos.z - boxMax.z) < epsilon) normal = float3(0, 0, 1);

                return normal;
            }

            // HSVからRGBへの変換
            float3 HSVtoRGB(float3 hsv)
            {
                float h = hsv.x;
                float s = hsv.y;
                float v = hsv.z;

                float c = v * s;
                float x = c * (1 - abs(fmod(h * 6, 2) - 1));
                float m = v - c;

                float3 rgb;

                if (0 <= h && h < 1.0 / 6.0) rgb = float3(c, x, 0);
                else if (1.0 / 6.0 <= h && h < 2.0 / 6.0) rgb = float3(x, c, 0);
                else if (2.0 / 6.0 <= h && h < 3.0 / 6.0) rgb = float3(0, c, x);
                else if (3.0 / 6.0 <= h && h < 4.0 / 6.0) rgb = float3(0, x, c);
                else if (4.0 / 6.0 <= h && h < 5.0 / 6.0) rgb = float3(x, 0, c);
                else rgb = float3(c, 0, x);

                return rgb + m;
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

                // 動的に生成されるオブジェクトの数
                int objectCount = 5;

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
                    float3 hitNormal = GetNormalAtBoxSurface(rayOrigin, boxMin, boxMax);

                    // 壁の色を変化させる
                    float hue = frac((_Time.y + bounce * 0.1) * 0.2);
                    float3 wallColor = HSVtoRGB(float3(hue, 1, 1));

                    // 色を加算
                    color += atten * wallColor * 0.1;

                    // レイを反射
                    rayDir = Reflect(rayDir, hitNormal);

                    // 複数の回転するオブジェクトとの交差判定
                    bool hitObject = false;
                    for (int obj = 0; obj < objectCount; ++obj)
                    {
                        float time = _Time.y * (1.0 + obj * 0.2);
                        float angle = time + obj * 1.0;
                        float3 sphereCenter = float3(sin(angle), cos(angle * 0.5), sin(angle * 0.3)) * (_CubeSize * 0.5);

                        float tSphere;
                        if (RaySphereIntersection(rayOrigin, rayDir, sphereCenter, _ObjectSize, tSphere))
                        {
                            float3 hitPoint = rayOrigin + rayDir * tSphere;
                            float3 normal = normalize(hitPoint - sphereCenter);

                            // オブジェクトの色をHSVで変化させる
                            float hueObj = frac((time + obj) * 0.1);
                            float3 objectColor = HSVtoRGB(float3(hueObj, 1, 1));

                            // 照明計算（ディフューズシェーディング）
                            float3 lightDir = normalize(float3(1, 1, 1));
                            float diffuse = max(0, dot(normal, lightDir));
                            color += atten * objectColor * diffuse;

                            hitObject = true;
                            break; // オブジェクトに当たったらループを抜ける
                        }
                    }

                    if (hitObject)
                    {
                        break; // オブジェクトに当たったので反射を終了
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
