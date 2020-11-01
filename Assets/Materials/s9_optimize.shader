Shader "Custom/s9_optimize"
{
    Properties
    {
        _Color ("Diffuse Color", Color) = (0.671, 0.31, 0.31)
        _MainTex ("Diffuse Texture", 2D) = "White" {}
        _BumpMap ("Normal Texture (bump)", 2D) = "bump" {}
        _EmitMap ("Emission Texture", 2D) = "black" {}
        _SpecMap ("Specular Texture", 2D) = "black" {}
        _SpecColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)        
        _Shininess ("Shininess", Range(0, 1)) = 0.1
        _RimColor ("Rim Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _RimPower ("Rim Power", Range(0.1, 10)) = 3.0
        _EmitStrength ("Emission Strength", Range(0.0, 2.0)) = 1
    }
    SubShader
    {
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            // user defined
            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform sampler2D _BumpMap;
            uniform float4 _BumpMap_ST;
            uniform sampler2D _EmitMap;
            uniform float4 _EmitMap_ST;
            uniform sampler2D _SpecMap;
            uniform float4 _SpecMap_ST;
            uniform float4 _Color;
            uniform float4 _SpecColor;
            uniform float4 _RimColor;
            uniform float _Shininess;
            uniform float _RimPower;
            uniform float _EmitStrength;


            // unity defined
            uniform float4 _LightColor0;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 posW : TEXCOORD0;
                float4 uv : TEXCOORD1;
                float3 normalW : TEXCOORD2;
                float3 tangentW : TEXCOORD3;
                float3 binormalW : TEXCOORD4;
            };

            v2f vert(appdata v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.posW = mul(v.vertex, unity_ObjectToWorld).xyz;
                o.uv = v.uv;
                o.tangentW = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
                o.normalW = normalize(mul(float4(v.normal, 0.0), unity_ObjectToWorld).xyz);
                o.binormalW = normalize(cross(o.normalW, o.tangentW) * v.tangent.w);
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
                half rim = 1 - saturate(dot(viewDirection, i.normalW));
                
                float4 tex = tex2D(_MainTex, _MainTex_ST.xy * i.uv.xy + _MainTex_ST.zw);
                float4 texN = tex2D(_BumpMap, _BumpMap_ST.xy * i.uv.xy + _BumpMap_ST.zw);
                float4 texE = tex2D(_EmitMap, _EmitMap_ST.xy * i.uv.xy + _EmitMap_ST.zw);
                // specular map is a monochromatic map, sometimes it is stored in the alpha channel of the normal map
                float4 texS = tex2D(_SpecMap, _SpecMap_ST.xy * i.uv.xy + _SpecMap_ST.zw);
                
                float3 localCoords = float3(2.0 * texN.ag - float2(1.0, 1.0), 0.0);
                // z = sqrt(1 - x^2 - y^2), see function UnpackNormal in "UnityCG.cginc"
                // the following is an approx
                localCoords.z = 1.0 - 0.5 * dot(localCoords, localCoords);

                float3x3 local2WorldTranspose = float3x3(
                i.tangentW,
                i.binormalW,
                i.normalW
                );
                float3 normal = normalize(mul(localCoords, local2WorldTranspose));

                float3 diffuseReflection =saturate(dot(lightDirection,normal))
                *  atten * _LightColor0.xyz ;
                float3 specularReflection = saturate(dot(lightDirection,normal))
                * atten * _LightColor0.xyz
                * _SpecColor.xyz * pow(saturate(dot(reflect(-lightDirection, normal),viewDirection)), _Shininess);
                float3 rimLighting =  saturate(dot(lightDirection,normal))
                * atten * _LightColor0.xyz
                * _RimColor * pow(rim, _RimPower);
                float3 lightFinal = specularReflection * texS.x + diffuseReflection + rimLighting + UNITY_LIGHTMODEL_AMBIENT.xyz + texE.xyz * _EmitStrength;
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
            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform sampler2D _BumpMap;
            uniform float4 _BumpMap_ST;
            uniform sampler2D _EmitMap;
            uniform float4 _EmitMap_ST;
            uniform sampler2D _SpecMap;
            uniform float4 _SpecMap_ST;
            uniform float4 _Color;
            uniform float4 _SpecColor;
            uniform float4 _RimColor;
            uniform float _Shininess;
            uniform float _RimPower;
            uniform float _EmitStrength;


            // unity defined
            uniform float4 _LightColor0;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 posW : TEXCOORD0;
                float4 uv : TEXCOORD1;
                float3 normalW : TEXCOORD2;
                float3 tangentW : TEXCOORD3;
                float3 binormalW : TEXCOORD4;
            };

            v2f vert(appdata v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.posW = mul(v.vertex, unity_ObjectToWorld).xyz;
                o.uv = v.uv;
                o.tangentW = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
                o.normalW = normalize(mul(float4(v.normal, 0.0), unity_ObjectToWorld).xyz);
                o.binormalW = normalize(cross(o.normalW, o.tangentW) * v.tangent.w);
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
                half rim = 1 - saturate(dot(viewDirection, i.normalW));
                
                float4 tex = tex2D(_MainTex, _MainTex_ST.xy * i.uv.xy + _MainTex_ST.zw);
                float4 texN = tex2D(_BumpMap, _BumpMap_ST.xy * i.uv.xy + _BumpMap_ST.zw);
                float4 texE = tex2D(_EmitMap, _EmitMap_ST.xy * i.uv.xy + _EmitMap_ST.zw);
                // specular map is a monochromatic map, sometimes it is stored in the alpha channel of the normal map
                float4 texS = tex2D(_SpecMap, _SpecMap_ST.xy * i.uv.xy + _SpecMap_ST.zw);
                
                float3 localCoords = float3(2.0 * texN.ag - float2(1.0, 1.0), 0.0);
                // z = sqrt(1 - x^2 - y^2), see function UnpackNormal in "UnityCG.cginc"
                // the following is an approx
                localCoords.z = 1.0 - 0.5 * dot(localCoords, localCoords);

                float3x3 local2WorldTranspose = float3x3(
                i.tangentW,
                i.binormalW,
                i.normalW
                );
                float3 normal = normalize(mul(localCoords, local2WorldTranspose));

                float3 diffuseReflection =saturate(dot(lightDirection,normal))
                *  atten * _LightColor0.xyz ;
                float3 specularReflection = saturate(dot(lightDirection,normal))
                * atten * _LightColor0.xyz
                * _SpecColor.xyz * pow(saturate(dot(reflect(-lightDirection, normal),viewDirection)), _Shininess);
                float3 rimLighting =  saturate(dot(lightDirection,normal))
                * atten * _LightColor0.xyz
                * _RimColor * pow(rim, _RimPower);
                float3 lightFinal = specularReflection * texS.x + diffuseReflection + rimLighting;
                return float4(tex * lightFinal * _Color.rgb, 1.0);
            } 
            ENDCG
        }
    }
    FallBack "Diffuse"
}