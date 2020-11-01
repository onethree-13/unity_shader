Shader "Custom/s6_texture"
{
    Properties
    {
        _Color ("Diffuse Color", Color) = (0.671, 0.31, 0.31)
        _MainTex ("Diffuse Texture", 2D) = "White" {}
        _SpecColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)        
        _Shininess ("Shininess", Range(0, 1)) = 0.1
        _RimColor ("Rim Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _RimPower ("Rim Power", Range(0.1, 10)) = 3.0
    }
    SubShader
    {
        Pass{
            Tags{"LightMode" = "ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            // user defined
            uniform sampler2D _MainTex;
            uniform float4 _Color;
            uniform float4 _SpecColor;
            uniform float4 _RimColor;
            uniform float4 _MainTex_ST;
            uniform float _Shininess;
            uniform float _RimPower;

            // unity defined
            uniform float4 _LightColor0;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 normalDir : TEXCOORD0;
                float3 posW : TEXCOORD1;
                float4 tex : TEXCOORD2;
            };

            v2f vert(appdata v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normalDir = normalize(mul(float4(v.normal, 0.0), unity_ObjectToWorld).xyz);
                o.posW = mul(v.vertex, unity_ObjectToWorld).xyz;
                o.tex = v.texcoord;
                return o;
            }

            float4 frag(v2f i) : COLOR {      
                float atten;
                float3 lightDirection;
                if(0.0 == _WorldSpaceLightPos0.w) // directional light
                {
                    atten = 1.0;
                    lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                }
                else{
                    float3 vertex2LightSrc = _WorldSpaceLightPos0.xyz - i.posW;
                    atten =  1.0/length(vertex2LightSrc);
                    lightDirection = normalize(vertex2LightSrc);
                }
                float3 viewDirection =  normalize(_WorldSpaceCameraPos.xyz- i.posW); 
                half rim = 1 - saturate(dot(viewDirection, i.normalDir));
                
                float4 tex = tex2D(_MainTex, _MainTex_ST.xy * i.tex.xy + _MainTex_ST.zw);

                float3 diffuseReflection =saturate(dot(lightDirection,i.normalDir))
                *  atten * _LightColor0.xyz ;
                float3 specularReflection = saturate(dot(lightDirection,i.normalDir))
                * atten * _LightColor0.xyz
                * _SpecColor.xyz * pow(saturate(dot(reflect(-lightDirection, i.normalDir),viewDirection)), _Shininess);
                float3 rimLighting =  saturate(dot(lightDirection,i.normalDir))
                * atten * _LightColor0.xyz
                * _RimColor * pow(rim, _RimPower);
                float3 lightFinal = specularReflection + diffuseReflection + rimLighting + UNITY_LIGHTMODEL_AMBIENT.xyz;
                return float4(tex * lightFinal * _Color.rgb, 1.0);
            } 
            ENDCG
        }

        Pass{
            Tags{"LightMode" = "ForwardAdd"}
            Blend One One
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            // user defined
            uniform float4 _Color;
            uniform float4 _SpecColor;
            uniform float4 _RimColor;
            uniform float _Shininess;
            uniform float _RimPower;

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
                float atten;
                float3 lightDirection;
                if(0.0 == _WorldSpaceLightPos0.w) // directional light
                {
                    atten = 1.0;
                    lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                }
                else{
                    float3 vertex2LightSrc = _WorldSpaceLightPos0.xyz - i.posW;
                    atten =  1.0/length(vertex2LightSrc);
                    lightDirection = normalize(vertex2LightSrc);
                }
                float3 viewDirection =  normalize(_WorldSpaceCameraPos.xyz- i.posW); 
                half rim = 1 - saturate(dot(viewDirection, i.normalDir));
                
                float3 diffuseReflection =max(0,dot(lightDirection,i.normalDir))
                *  atten * _LightColor0.xyz ;
                float3 specularReflection = max(0,dot(lightDirection,i.normalDir))
                * atten * _LightColor0.xyz
                * _SpecColor.xyz * pow(max(0, dot(reflect(-lightDirection, i.normalDir),viewDirection)), _Shininess);
                float3 rimLighting =  max(0,dot(lightDirection,i.normalDir))
                * atten * _LightColor0.xyz
                * _RimColor * pow(rim, _RimPower);
                float3 lightFinal = specularReflection + diffuseReflection + rimLighting;
                return float4(lightFinal * _Color.rgb, 1.0);
            } 
            ENDCG
        }
    }
    FallBack "Diffuse"
}