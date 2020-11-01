Shader "Custom/s1_flat"
{
    Properties
    {
        _Color ("Diffuse Color", Color) = (0.671, 0.31, 0.31)
    }
    SubShader
    {
        Pass {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            uniform float4 _Color;

            struct appdata{
                float4 vertex: POSITION;
            };

            struct vo{
                float4 pos: SV_POSITION;
            };

            vo vert(appdata v){
                vo o;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            float4 frag(vo i) : COLOR{
                return _Color;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
