#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
CBUFFER_START(UnityPerMaterial)
TEXTURE2D(_ColorMap); SAMPLER(sampler_ColorMap);
TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
TEXTURE2D(_ShadowStepMap); SAMPLER(sampler_ShadowStepMap);
TEXTURE2D(_AlphaMap); SAMPLER(sampler_AlphaMap);
float4 _ColorMap_ST;
float4 _ColorTint;
float _Smoothness;
float _Metallic;
float _CastShadowIntensity;
float _ShadowIntensity;
float _NormalOutlines;
float _OutlineThickness;
float4 _OutlineColor;
TEXTURE2D(_OutlineWidthMap); SAMPLER(sampler_OutlineWidthMap);
CBUFFER_END

CBUFFER_START(UnityPerDraw)
CBUFFER_END