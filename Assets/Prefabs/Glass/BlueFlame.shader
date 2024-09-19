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
            float _FlameIntensity;
            float _FlameSpeed;
            float _FlameScale;

            sampler3D _NoiseTex3D; // 3D�m�C�Y�e�N�X�`��

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            // ���C�ƃ{�b�N�X�̌�������
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
                // ���C�̌��_�ƕ���
                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDir = normalize(i.worldPos - _WorldSpaceCameraPos);

                // �L���[�u�̋��E
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

                    // ���C����_�܂Ői�߂�
                    float t = tMin > 0 ? tMin : tMax;
                    if (t < 0)
                    {
                        break;
                    }

                    rayOrigin = rayOrigin + rayDir * t;

                    // ���������ʂ̖@�����擾
                    float3 hitNormal = float3(0, 0, 0);
                    float epsilon = 1e-4;

                    if (abs(rayOrigin.x - boxMin.x) < epsilon) hitNormal = float3(-1, 0, 0);
                    else if (abs(rayOrigin.x - boxMax.x) < epsilon) hitNormal = float3(1, 0, 0);
                    else if (abs(rayOrigin.y - boxMin.y) < epsilon) hitNormal = float3(0, -1, 0);
                    else if (abs(rayOrigin.y - boxMax.y) < epsilon) hitNormal = float3(0, 1, 0);
                    else if (abs(rayOrigin.z - boxMin.z) < epsilon) hitNormal = float3(0, 0, -1);
                    else if (abs(rayOrigin.z - boxMax.z) < epsilon) hitNormal = float3(0, 0, 1);

                    // ���C�𔽎�
                    rayDir = reflect(rayDir, hitNormal);

                    // ���̃p�[�e�B�N���𐶐�
                    float3 flamePos = rayOrigin;

                    // 3D�m�C�Y���g�p���ĉ��̌`����쐬
                    float3 noiseCoord = flamePos * _FlameScale + float3(0, _Time.y * _FlameSpeed, 0);
                    float noiseValue = tex3D(_NoiseTex3D, frac(noiseCoord)).r;
                    float flameThreshold = 0.5;

                    if (noiseValue > flameThreshold)
                    {
                        float intensity = (noiseValue - flameThreshold) / (1.0 - flameThreshold);
                        color += atten * float3(0.0, 0.5, 1.0) * intensity * _FlameIntensity;
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
