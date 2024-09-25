#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

// Returns rendering game object's world space position.
float3 GetObjectPositionWS()
{
    return unity_ObjectToWorld._m03_m13_m23;
}