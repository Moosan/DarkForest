// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Sample" {
    Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BumpMap ("Normal map", 2D) = "bump" {}
        _Color   ("Main Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1.0)
        _Shininess ("Shininess", Range (0.03, 1.0)) = 0.078125
    }
    SubShader {
        ZWrite On
        Blend SrcAlpha OneMinusSrcAlpha
        Alphatest Greater [_Cutoff]

        Tags { "Queue"="Geometry" "RenderType"="Opaque"}

        Pass {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM

            float4 _LightColor0;
            float4 _Color;
            float4 _SpecColor;
            sampler2D _MainTex;
            sampler2D _BumpMap;
            half _Shininess;

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma fragmentoption ARB_fog_exp2
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma target 3.0

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct vertInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 pos      : SV_POSITION;
                float2 uv       : TEXCOORD0;
                float3 viewDir  : TEXCOORD1;
                float3 lightDir : TEXCOORD2;
                LIGHTING_COORDS(3, 4)
            };

            // Vertex shader function.
            v2f vert(appdata_tan v) {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv  = v.texcoord.xy;
                TANGENT_SPACE_ROTATION;
                o.viewDir  = mul(rotation, ObjSpaceViewDir(v.vertex));
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));

                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            // Fragment shader function.
            float4 frag(v2f i) : COLOR {
                i.viewDir  = normalize(i.viewDir);
                i.lightDir = normalize(i.lightDir);

                fixed atten = LIGHT_ATTENUATION(i);

                fixed4 tex = tex2D(_MainTex, i.uv);
                fixed  gloss = tex.a;
                tex *= _Color;
                fixed3 normal = UnpackNormal(tex2D(_BumpMap, i.uv));

                half3 h = normalize(i.lightDir + i.viewDir);

                fixed4 diff = saturate(dot(normal, i.lightDir));

                float nh = saturate(dot(normal, h));
                float spec = pow(nh, _Shininess * 128.0) * gloss;

                fixed4 color;
                color.rgb  = UNITY_LIGHTMODEL_AMBIENT.rgb * 2 * tex.rgb;
                color.rgb += (tex.rgb * _LightColor0.rgb * diff + _LightColor0.rgb * _SpecColor.rgb * spec) * (atten * 2);
                color.a    = tex.a + (_LightColor0.a * _SpecColor.a * spec * atten);

                return color;
            }

            ENDCG
        }

        // For forward add rendering pass.
        Pass {
            Tags { "LightMode"="ForwardAdd" }

            Blend One One

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd
            #pragma fragmentoption ARB_fog_exp2
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma target 3.0

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct v2f {
                float4  pos         : SV_POSITION;
                float2  uv          : TEXCOORD0;
                float3  viewDir     : TEXCOORD1;
                float3  lightDir    : TEXCOORD2;
                LIGHTING_COORDS(3, 4)
            };

            // Vertes shader function.
            v2f vert(appdata_tan v) {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv  = v.texcoord.xy;

                TANGENT_SPACE_ROTATION;

                return o;
            }

            sampler2D _MainTex;
            sampler2D _BumpMap;
            fixed4 _Color;
            half _Shininess;

            fixed4 _SpecColor;
            fixed4 _LightColor0;

            float4 frag(v2f i) : COLOR {
                i.viewDir  = normalize(i.viewDir);
                i.lightDir = normalize(i.lightDir);

                fixed atten = LIGHT_ATTENUATION(i);

                fixed4 tex = tex2D(_MainTex, i.uv);
                fixed gloss = tex.a;
                tex *= _Color;
                fixed3 normal = UnpackNormal(tex2D(_BumpMap, i.uv));

                half3 h = normalize(i.lightDir + i.viewDir);

                fixed diff = saturate(dot(normal, i.lightDir));

                float nh = saturate(dot(normal, h));
                float spec = pow(nh, _Shininess * 128.0) * gloss;

                fixed4 color;
                color.rgb = (tex.rgb * _LightColor0.rgb * diff + _LightColor0.rgb * _SpecColor.rgb * spec) * (atten * 2);
                color.a   = tex.a + _LightColor0.a * _SpecColor.a * spec * atten;

                return color;
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}