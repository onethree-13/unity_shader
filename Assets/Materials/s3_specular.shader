Shader "Custom/s3_specular"
{
    Properties
    {
        _Color ("Diffuse Color", Color) = (0.671, 0.31, 0.31)
        _SpecColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Shininess ("Shininess", Float) = 10
    }
    SubShader
    {
        Pass{
            Tags{"LightMode" = "ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            // user defined
            uniform float4 _Color;
            uniform float4 _SpecColor;
            uniform float _Shininess;

            // unity defined
            uniform float4 _LightColor0;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 normalDir : TEXCOORD0;
                float3 posW : TEXCOORD1;
            };

            v2f vert(appdata v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normalDir = normalize(mul(float4(v.normal, 0.0), unity_ObjectToWorld).xyz);
                o.posW = mul(v.vertex, unity_ObjectToWorld).xyz;
                return o;
            }

            float4 frag(v2f i) : COLOR {      
                float atten = 1.0;
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDirection =  normalize(_WorldSpaceCameraPos.xyz- i.posW); 
                
                float3 diffuseReflection =max(0, dot(lightDirection,i.normalDir))
                *  atten * _LightColor0.xyz ;
                float3 specularReflection = max(0, dot(lightDirection,i.normalDir))
                * atten * _LightColor0.xyz
                * _SpecColor.xyz * pow(max(0, dot(reflect(-lightDirection, i.normalDir), viewDirection)), _Shininess);
                float3 lightFinal = specularReflection + diffuseReflection + UNITY_LIGHTMODEL_AMBIENT.xyz;
                return float4(lightFinal * _Color.rgb, 1.0);
            } 
            ENDCG
        }
    }
    FallBack "Diffuse"
}