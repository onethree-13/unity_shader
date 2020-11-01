Shader "Custom/s2_lambert"
{
    Properties
    {
        _Color ("Diffuse Color", Color) = (0.671, 0.31, 0.31)
    }
    SubShader
    {
        Pass {
            Tags{"LightMode" = "ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            // user defined
            uniform float4 _Color;

            // unity defined
            uniform float4 _LightColor0;

            struct appdata{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f{
                float4 pos : SV_POSITION;
                float3 normalDir : TEXCOORD0;
            };

            v2f vert(appdata v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normalDir = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
                return o;
            }

            float4 frag(v2f i) : COLOR{
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float atten = 1.0;
                float3 diffuseReflection = atten * _LightColor0.xyz  * max(0, dot(i.normalDir, lightDir));
                float3 lightFinal = diffuseReflection + UNITY_LIGHTMODEL_AMBIENT.xyz;
                return float4(lightFinal*_Color.rgb, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}