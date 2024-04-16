Shader "Unlit/RaymarchingSphere"
{
    Properties {}
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {
            Cull Off// カリングを無効
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };


            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = float4(v.vertex.xy * 2.0, 0.5, 1.0);
                o.uv = v.uv;
                #if UNITY_UV_STARTS_AT_TOP
                o.uv.y = 1 - o.uv.y;
                #endif
                return o;
            }

            float sdSphere(float3 p, float r)
            {
                return length(p) - r;
            }

            float map(float3 p)
            {
                return sdSphere(p, 1.0);
            }

            // 偏微分から法線を計算します
            float3 calcNormal(float3 p)
            {
                float eps = 0.001;
                
                return normalize(float3(
                    map(p + float3(eps, 0.0, 0.0)) - map(p + float3(-eps, 0.0, 0.0)),
                    map(p + float3(0.0, eps, 0.0)) - map(p + float3(0.0, -eps, 0.0)),
                    map(p + float3(0.0, 0.0, eps)) - map(p + float3(0.0, 0.0, -eps))
                ));
            }

            fixed4 frag(v2f input) : SV_Target
            {
                float3 col = float3(0.0, 0.0, 0.0);
                float2 uv = 2.0 * input.uv - 1.0;

                uv.x *= _ScreenParams.x / _ScreenParams.y;

                float3 cameraOrigin = float3(0.0, 0.0, -4.0);
                float3 cameraTarget = float3(0.0, 0.0, 0.0);
                float3 cmaeraUp = float3(0.0, 1.0, 0.0);
                float cameraFov = 60.0;

                float3 forward = normalize(cameraTarget - cameraOrigin);
                float3 right = normalize(cross(cmaeraUp, forward));
                float3 up = normalize(cross(forward, right));

                float pi = 3.14159265359;
                float3 ray = normalize(
                    right * uv.x +
                    up * uv.y +
                    forward / tan(cameraFov / 360 * pi)
                );

                // レイマーチング
                float t = 0.0; // レイの進んだ距離
                float3 p = cameraOrigin; // レイの先端の座標
                bool hit = false; // オブジェクトに衝突したかどうか

                for (int i = 0; i < 99; i++)
                {
                    float d = map(p); // 最短距離を計算します

                    // 最短距離を0に近似できるなら、オブジェクトに衝突したとみなして、ループを抜けます
                    if (d < 0.0001)
                    {
                        hit = true;
                        break;
                    }

                    t += d; // 最短距離だけレイを進めます
                    p = cameraOrigin + ray * t; // レイの先端の座標を更新します
                }


                if (hit)
                {
                    // 何かに衝突したら白
                    //col = float3(1, 1, 1);
                    // 法線を計算して、法線を色にします
                    //col = calcNormal(p);


                    float3 normal = calcNormal(p);// 法線
                    float3 light = normalize(float3(1, 1, -1));// 平行光源の方向ベクトル
                    col = saturate(dot(normal, light));// 内積でライティング（拡散反射）
                }
                else
                {
                    // 何にも衝突しなかったら黒
                    col = float3(0, 0, 0);
                }

                return float4(col, 1);
            }
            ENDCG
        }
    }
}