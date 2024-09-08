Shader "MinimumExamples/NormalMap_TextureType_Default"
{
    Properties
    { 
        _NormalMap("Normal Map",2D) = "bump" {} // Texture Importer must have Texture Type = Default (RG | Normal; BA | Whatever you want
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
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS  : SV_POSITION;
                float2 uv : TEXCOORD0; 
                float3x3 tbn : TEXCOORD1; //  TEXCOORD 1-3
            };

            CBUFFER_START(UnityPerMaterial)
                sampler2D _NormalMap;
            CBUFFER_END
            
            Varyings vert(Attributes IN)
            {
                Varyings o;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
                o.positionCS = vertexInput.positionCS;

                VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);
                float3 normalWS = normalInputs.normalWS;
                float3 tangentWS = normalInputs.tangentWS;
                float3 bitangentWS = normalInputs.bitangentWS;
                
                o.tbn = float3x3(tangentWS,bitangentWS,normalWS);

                o.uv = IN.uv;
                
                return o;
            }
            
            half4 frag(Varyings i) : SV_Target
            {
                float4 normalMap = tex2D(_NormalMap,i.uv);
                float3 normalUnpacked;
                normalUnpacked.xy = normalMap.rg * 2 - 1;
                normalUnpacked.z = max(1.0e-16, sqrt(1.0 - saturate(dot(normalUnpacked.xy, normalUnpacked.xy))));
                float3 normalWS = mul(normalUnpacked,i.tbn);
								normalWS = normalize(normalWS);
                
                return half4(normalWS,1);   
            }
            
            ENDHLSL
        }

    }
}