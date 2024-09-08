Shader "MinimumExamples/MinimalLit"
{
       Properties
    { 
        [NoScaleOffset]_BaseMap("Base Color Map",2D) = "white" {}
        _SpecularColor("Specular Color",Color) = (1,1,1,1)
        [NoScaleOffset]_NormalMap("Normal Map",2D) = "bump" {}
        [NoScaleOffset]_MSAMap("MSA Map",2D) = "white" {}
    }
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Geometry" }

        Pass
        {
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3x3 tbn : TEXCOORD1; //  TEXCOORD 1-3
                float3 sh : TEXCOORD4;
                float3 positionWS : TEXCOORD5;
                float fogFactor: TEXCOORD6;
            };

            CBUFFER_START(UnityPerMaterial)
                sampler2D _BaseMap;
                float3 _SpecularColor;
                sampler2D _NormalMap;
                sampler2D _MSAMap;
            CBUFFER_END
            
            Varyings vert(Attributes IN)
            {
                Varyings o;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
                o.positionHCS = vertexInput.positionCS;
                o.positionWS = vertexInput.positionWS;
                
                o.fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);
                float3 normalWS = normalInputs.normalWS;
                float3 tangentWS = normalInputs.tangentWS;
                float3 bitangentWS = normalInputs.bitangentWS;
                
                o.tbn = float3x3(tangentWS,bitangentWS,normalWS);

                o.sh = SampleSH(normalWS);
                
                o.uv = IN.uv;

                return o;
            }
            
            half4 frag(Varyings i) : SV_Target
            {
                // Textures
                float3 albedo = tex2D(_BaseMap,i.uv).rgb;
                float3 specular = _SpecularColor;
                float3 msa = tex2D(_MSAMap,i.uv).rgb;
                float metallic = msa.r;
                float smoothness = msa.b;
                float ao = msa.g;

                float4 normalMap = tex2D(_NormalMap,i.uv);
                float3 normalUnpacked = UnpackNormal(normalMap);
                float3 normalWS = mul(normalUnpacked,i.tbn);
                normalWS = normalize(normalWS);
                
                // Init BRDFData
                BRDFData brdfData = (BRDFData)0;
                float alpha = 1;
                InitializeBRDFData(albedo,metallic,specular,smoothness,alpha,brdfData);
                
                // Direct Specular + Diffuse
                float3 viewDirectionWS = normalize(_WorldSpaceCameraPos.xyz - i.positionWS.xyz);
                Light mainLight = GetMainLight(TransformWorldToShadowCoord(i.positionWS), i.positionWS, 0);
                
                float3 direct = LightingPhysicallyBased(brdfData,mainLight,normalWS,viewDirectionWS);
                
                // Direct Specular + Diffuse for Additional Lights
                uint pixelLightCount = GetAdditionalLightsCount();
                LIGHT_LOOP_BEGIN(pixelLightCount)
                        Light additionalLight = GetAdditionalLight(lightIndex, i.positionWS, 0);
                
                #ifdef _LIGHT_LAYERS
                        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
                #endif
                        {
                            direct += LightingPhysicallyBased(brdfData,mainLight,normalWS,viewDirectionWS);
                        }
                LIGHT_LOOP_END
                
                // Indirect Specular + Diffuse (GI)
                float3 bakedGI = i.sh;
                MixRealtimeAndBakedGI(mainLight,normalWS,bakedGI,1);
                float3 gi = GlobalIllumination(brdfData,bakedGI,ao,i.positionWS,normalWS,viewDirectionWS);

                // Combining
                float3 model = direct + gi;
                model = MixFog(model, i.fogFactor);
                return half4(model,1);
            }
            ENDHLSL
        }
    }
}