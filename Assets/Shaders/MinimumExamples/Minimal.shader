Shader "MinimumExamples/Minimal"
{
    Properties
    { 
        
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
            };

            struct Varyings
            {
                float4 positionCS  : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
                
            CBUFFER_END
            
            Varyings vert(Attributes IN)
            {
                Varyings o;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
                o.positionCS = vertexInput.positionCS;

                return o;
            }
            
            
            half4 frag(Varyings i) : SV_Target
            {
                return 1;   
            }

            ENDHLSL
        }

    }
}