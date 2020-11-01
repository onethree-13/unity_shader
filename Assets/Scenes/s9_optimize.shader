Shader "Custom/s9_optimize"
{
    Properties
    {
        _Color ("Color", Color) = (0.671, 0.31, 0.31)
        _MainTex ("Diffuse Texture", 2D) = "White" {}
        _BumpMap ("Normal Texture (bump)", 2D) = "bump" {}
        _EmitMap ("Emission Texture", 2D) = "black" {}
        _SpecMap ("Specular Texture", 2D) = "black" {}
        _SpecColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)        
        _Shininess ("Shininess", Range(0, 1)) = 0.1
        _RimColor ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
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
            uniform half4 _MainTex_ST;
            uniform sampler2D _BumpMap;
            uniform half4 _BumpMap_ST;
            uniform sampler2D _EmitMap;
            uniform half4 _EmitMap_ST;
            uniform sampler2D _SpecMap;
            uniform half4 _SpecMap_ST;
            uniform fixed4 _Color;
            uniform fixed4 _SpecColor;
            uniform fixed4 _RimColor;
            uniform half _Shininess;
            uniform half _RimPower;
            uniform fixed _EmitStrength;


            // unity defined
            uniform half4 _LightColor0;

            struct appdata
            {
                half4 vertex : POSITION;
                half3 normal : NORMAL;
                half4 tangent : TANGENT;
                half4 uv : TEXCOORD0;
            };

            struct v2f
            {
                half4 pos : SV_POSITION;
                half4 uv : TEXCOORD0;
                fixed4 lightDirection : TEXCOORD1;
                fixed3 viewDirection : TEXCOORD2;
                fixed3 normalW : TEXCOORD3;
                fixed3 tangentW : TEXCOORD4;
                fixed3 binormalW : TEXCOORD5;
            };

            v2f vert(appdata v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                half3 posW = mul(v.vertex, unity_ObjectToWorld).xyz;
                o.tangentW = normalize(mul(unity_ObjectToWorld, v.tangent.xyz).xyz);
                o.normalW = normalize(mul(half4(v.normal, 0.0), unity_ObjectToWorld).xyz);
                o.binormalW = normalize(cross(o.normalW, o.tangentW) * v.tangent.w);

                half3 vertex2LightSrc = _WorldSpaceLightPos0.xyz - posW;
                o.lightDirection = fixed4(
                normalize(lerp(_WorldSpaceLightPos0.xyz, vertex2LightSrc, _WorldSpaceLightPos0.w)), // lightDirection
                lerp(1.0, 1.0/length(vertex2LightSrc), _WorldSpaceLightPos0.w)// atten
                );
                o.viewDirection =  normalize(_WorldSpaceCameraPos.xyz- posW); 
                return o;
            }

            fixed4 frag(v2f i) : COLOR {      
                // texture maps
                fixed4 tex = tex2D(_MainTex, _MainTex_ST.xy * i.uv.xy + _MainTex_ST.zw);
                fixed4 texN = tex2D(_BumpMap, _BumpMap_ST.xy * i.uv.xy + _BumpMap_ST.zw);
                fixed4 texE = tex2D(_EmitMap, _EmitMap_ST.xy * i.uv.xy + _EmitMap_ST.zw);
                // specular map is a monochromatic map, sometimes it is stored in the alpha channel of the normal map
                fixed4 texS = tex2D(_SpecMap, _SpecMap_ST.xy * i.uv.xy + _SpecMap_ST.zw);
                
                // unpack normal
                fixed3 localCoords = fixed3(2.0 * texN.ag - fixed2(1.0, 1.0), 0.0);
                // z = sqrt(1 - x^2 - y^2), see function UnpackNormal in "UnityCG.cginc"
                // the following is an approx
                localCoords.z = 1.0 - 0.5 * dot(localCoords, localCoords);

                // TBN, calculate normal
                fixed3x3 local2WorldTranspose = fixed3x3(i.tangentW, i.binormalW, i.normalW);
                fixed3 normal = normalize(mul(localCoords, local2WorldTranspose));

                // lighting 
                fixed nDotL = saturate(dot(i.lightDirection.xyz, normal));
                fixed3 diffuseReflection =nDotL *  i.lightDirection.w * _LightColor0.xyz ;
                fixed3 specularReflection = nDotL * i.lightDirection.w * _LightColor0.xyz
                * _SpecColor.xyz * pow(saturate(dot(reflect(-i.lightDirection.xyz,  normal), i.viewDirection)), _Shininess);
                // rim lighting
                half rim = 1 - saturate(dot(i.viewDirection, i.normalW));
                fixed3 rimLighting =  nDotL * i.lightDirection.w * _LightColor0.xyz * _RimColor * pow(rim, _RimPower);

                fixed3 lightFinal = specularReflection * texS.x + diffuseReflection + rimLighting + UNITY_LIGHTMODEL_AMBIENT.xyz + texE.xyz * _EmitStrength;
                return fixed4(tex * lightFinal * _Color.rgb, 1.0);
            } 
            ENDCG
        }

        Pass
        {
            Tags{"LightMode" = "ForwardAdd"}
            Blend One One
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            // user defined
            uniform sampler2D _MainTex;
            uniform half4 _MainTex_ST;
            uniform sampler2D _BumpMap;
            uniform half4 _BumpMap_ST;
            uniform sampler2D _EmitMap;
            uniform half4 _EmitMap_ST;
            uniform sampler2D _SpecMap;
            uniform half4 _SpecMap_ST;
            uniform fixed4 _Color;
            uniform fixed4 _SpecColor;
            uniform fixed4 _RimColor;
            uniform half _Shininess;
            uniform half _RimPower;
            uniform fixed _EmitStrength;


            // unity defined
            uniform half4 _LightColor0;

            struct appdata
            {
                half4 vertex : POSITION;
                half3 normal : NORMAL;
                half4 tangent : TANGENT;
                half4 uv : TEXCOORD0;
            };

            struct v2f
            {
                half4 pos : SV_POSITION;
                half4 uv : TEXCOORD0;
                fixed4 lightDirection : TEXCOORD1;
                fixed3 viewDirection : TEXCOORD2;
                fixed3 normalW : TEXCOORD3;
                fixed3 tangentW : TEXCOORD4;
                fixed3 binormalW : TEXCOORD5;
            };

            v2f vert(appdata v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                half3 posW = mul(v.vertex, unity_ObjectToWorld).xyz;
                o.tangentW = normalize(mul(unity_ObjectToWorld, v.tangent.xyz).xyz);
                o.normalW = normalize(mul(half4(v.normal, 0.0), unity_ObjectToWorld).xyz);
                o.binormalW = normalize(cross(o.normalW, o.tangentW) * v.tangent.w);

                half3 vertex2LightSrc = _WorldSpaceLightPos0.xyz - posW;
                o.lightDirection = fixed4(
                normalize(lerp(_WorldSpaceLightPos0.xyz, vertex2LightSrc, _WorldSpaceLightPos0.w)), // lightDirection
                lerp(1.0, 1.0/length(vertex2LightSrc), _WorldSpaceLightPos0.w)// atten
                );
                o.viewDirection =  normalize(_WorldSpaceCameraPos.xyz- posW); 
                return o;
            }

            fixed4 frag(v2f i) : COLOR {      
                // texture maps
                fixed4 tex = tex2D(_MainTex, _MainTex_ST.xy * i.uv.xy + _MainTex_ST.zw);
                fixed4 texN = tex2D(_BumpMap, _BumpMap_ST.xy * i.uv.xy + _BumpMap_ST.zw);
                // specular map is a monochromatic map, sometimes it is stored in the alpha channel of the normal map
                fixed4 texS = tex2D(_SpecMap, _SpecMap_ST.xy * i.uv.xy + _SpecMap_ST.zw);
                
                // unpack normal
                fixed3 localCoords = fixed3(2.0 * texN.ag - fixed2(1.0, 1.0), 0.0);
                // z = sqrt(1 - x^2 - y^2), see function UnpackNormal in "UnityCG.cginc"
                // the following is an approx
                localCoords.z = 1.0 - 0.5 * dot(localCoords, localCoords);

                // TBN, calculate normal
                fixed3x3 local2WorldTranspose = fixed3x3(i.tangentW, i.binormalW, i.normalW);
                fixed3 normal = normalize(mul(localCoords, local2WorldTranspose));

                // lighting 
                fixed nDotL = saturate(dot(i.lightDirection.xyz, normal));
                fixed3 diffuseReflection =nDotL *  i.lightDirection.w * _LightColor0.xyz ;
                fixed3 specularReflection = nDotL * i.lightDirection.w * _LightColor0.xyz
                * _SpecColor.xyz * pow(saturate(dot(reflect(-i.lightDirection.xyz,  normal), i.viewDirection)), _Shininess);
                // rim lighting
                half rim = 1 - saturate(dot(i.viewDirection, i.normalW));
                fixed3 rimLighting =  nDotL * i.lightDirection.w * _LightColor0.xyz * _RimColor * pow(rim, _RimPower);

                fixed3 lightFinal = specularReflection * texS.x + diffuseReflection + rimLighting;
                return fixed4(tex * lightFinal * _Color.rgb, 1.0);
            } 
            ENDCG
        }
    }
    FallBack "Diffuse"
}