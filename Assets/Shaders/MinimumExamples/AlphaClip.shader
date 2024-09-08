Shader "MinimumExamples/AlphaClip"
{
    Properties
    { 
        _BaseMap("Base Map", 2D) = "white" {}
        _AlphaClipThreshold("Alpha Clip Threshold", Range(0,1)) = 0.5
    }
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" }
        
        Pass
        {
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS  : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                sampler2D _BaseMap;
                float _AlphaClipThreshold;
            CBUFFER_END
            
            Varyings vert(Attributes IN)
            {
                Varyings o;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
                o.positionCS = vertexInput.positionCS;

                o.uv = IN.uv;

                return o;
            }
            
            half4 frag(Varyings i) : SV_Target
            {
                half4 baseMap = tex2D(_BaseMap,i.uv);
                clip(baseMap.a - _AlphaClipThreshold);
                return half4(baseMap.rgb,1);   
            }
            
            ENDHLSL
        }

    }
}