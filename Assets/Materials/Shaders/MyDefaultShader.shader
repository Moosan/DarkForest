Shader "Custom/MyDefaultShader"
{
	Properties
    {
        // テクスチャのプロパティ
        _MainTex ("Main Texture (RGB)", 2D) = "white" {}
        _Color ("Color (RGB)", Color) = (1, 1, 1, 1)
		_Shininess("Shininess",float) = 20.0
		_Metalness("Metalness",Range(0.0,1.0)) = 0.0
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                half4 vertex : POSITION;
                half2 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };

            struct v2f
            {
                half4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
                half3 normal: TEXCOORD1;
				half3 halfDir : TEXCOORD2;
				half3 lightDir : TEXCOORD3;
				half3 viewDir : TEXCOORD4;
				half3 reflDir : TEXCOORD5;
            };
			
            #define F0        0.04f

            sampler2D _MainTex;
            half4 _MainTex_ST;

            half4 _Color;
            half4 _LightColor0;
			half _Shininess;
			half _Metalness;

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.vertex);
				half3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos.xyz);
                o.lightDir = normalize(_WorldSpaceLightPos0.xyz);
				o.halfDir = normalize(o.lightDir + o.viewDir);
                o.normal = UnityObjectToWorldNormal(v.normal);
				o.reflDir = reflect(-o.viewDir,o.normal);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
				half4 base = tex2D(_MainTex,i.uv) * _Color;
				half3 specColor = lerp(1.0,base.rgb,_Metalness);
				half3 indirectLighting = ShadeSH9(half4(i.normal, 1));
				half3 directDiff = base * (max(0.0,dot(i.normal,i.lightDir)) * _LightColor0.rgb + indirectLighting.rgb);
				half3 direcSpec = pow(max(0.0,dot(i.normal,i.halfDir)),_Shininess) * _LightColor0.rgb * specColor;

				half fresnel = F0 + (1 - F0) * pow(1 - dot(i.viewDir, i.normal), 5);
                half indirectRefl = lerp(fresnel, 1, _Metalness);
				
                half3 indirectSpec = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, i.reflDir) * specColor;
				
                fixed4 col;
                col.rgb = lerp(directDiff,direcSpec,_Metalness) + indirectSpec * indirectRefl;
				return col;
            }
            ENDCG
        }
    }
}