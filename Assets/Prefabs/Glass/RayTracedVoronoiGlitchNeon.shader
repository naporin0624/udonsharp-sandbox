Shader "Custom/RayTracedVoronoiGlitchNeon"
{
    Properties
    {
        _CubeSize("Cube Size", Float) = 5
        _MaxBounces("Max Bounces", Int) = 5
        _BorderThickness("Border Thickness", Float) = 0.05
        _BorderColor("Border Color", Color) = (0, 0, 0, 1)
        _BackgroundColor("Background Color", Color) = (0, 0, 0, 1)
        _ColorIntensity("Color Intensity", Float) = 2.0
        _AnimationSpeed("Animation Speed", Float) = 1.0
        _GlitchIntensity("Glitch Intensity", Float) = 0.1
        _NeonColor("Neon Color", Color) = (0, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off // �������猩����悤�ɃJ�����O���I�t�ɂ��܂��B

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
            float _GlitchIntensity;
            float4 _NeonColor;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            // �����_���Ȓl�𐶐�����֐�
            float rand(float2 co)
            {
                return frac(sin(dot(co, float2(12.9898, 78.233))) * 43758.5453);
            }

            // �{���m�C�}�̌v�Z
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
                            float3 pointPos = neighbor + rand(pi.xy + neighbor.xy);
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
                // ���C�̌��_�ƕ���
                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDir = normalize(i.worldPos - _WorldSpaceCameraPos);

                // �L���[�u�̋��E
                float3 boxMin = float3(-_CubeSize, -_CubeSize, -_CubeSize);
                float3 boxMax = float3(_CubeSize, _CubeSize, _CubeSize);

                float3 color = _BackgroundColor.rgb; // �w�i�F�������l�ɐݒ�
                float3 atten = float3(1, 1, 1);

                int maxBounces = _MaxBounces;

                [loop]
                for (int bounce = 0; bounce < maxBounces; ++bounce)
                {
                    float tMin, tMax;
                    // ���C�ƃ{�b�N�X�̌�������
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

                    // ���C����_�܂Ői�߂�
                    float t = tMin > 0 ? tMin : tMax;
                    if (t < 0)
                    {
                        break;
                    }

                    rayOrigin = rayOrigin + rayDir * t;

                    // ���������ʂ̖@�����擾
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

                    // ���C�𔽎�
                    rayDir = reflect(rayDir, hitNormal);

                    // �O���b�`�m�C�Y�̐���
                    float glitch = rand(floor(rayOrigin.xy * 10.0 + _Time.y * 5.0)) * _GlitchIntensity;

                    // �{���m�C�}�̌v�Z
                    float3 p = rayOrigin * 0.2 + _Time.y * _AnimationSpeed; // �X�P�[�������Ɠ����̒ǉ�
                    float minDist;
                    float3 cellID;
                    Voronoi(p + glitch, minDist, cellID); // �O���b�`���ʒu�ɉ��Z

                    // ���E�̕`��
                    float edgeThickness = _BorderThickness;
                    if (minDist < edgeThickness)
                    {
                        color = lerp(color, _BorderColor.rgb * _ColorIntensity, atten);
                    }
                    else
                    {
                        // �l�I���J���[���g�p
                        float3 cellColor = _NeonColor.rgb * _ColorIntensity;
                        color = lerp(color, cellColor, atten);
                    }

                    // �F�̌���
                    atten *= 0.8; // ���˂��ƂɌ���
                }

                // �ŏI�I�ȐF��Ԃ�
                return float4(color, 1.0);
            }

            ENDCG
        }
    }
}

