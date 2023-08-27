#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes {
	float3 positionOS : POSITION;
    float2 uv : TEXCOORD0;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
};

struct Frag2Vert {
	float4 positionCS : SV_POSITION;
	float2 uv : TEXCOORD0;
    float3 normalWS : TEXCOORD1;
    float3 positionWS : TEXCOORD2;
    float4 tangentWS : TEXCOORD3;
};


Frag2Vert Vertex(Attributes input) {
	Frag2Vert output;

	// function from URP/ShaderLib/ShaderVariablesFunctions.hlsl
	// transform object space values into world and clip space
	VertexPositionInputs posnInputs = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);

	// Pass position and orientation data to the fragment function
	output.positionCS = posnInputs.positionCS;
	output.uv = TRANSFORM_TEX(input.uv, _ColorMap);
    output.normalWS = normInputs.normalWS;
    output.tangentWS = float4(normInputs.tangentWS, input.tangentOS.w);
    output.positionWS = posnInputs.positionWS;

	return output;
}

float4 Fragment(Frag2Vert input, float facing : VFACE) : SV_TARGET
{
    float2 uv = input.uv;
    // sample alpha map for alpha cutoff
    float4 alpha = SAMPLE_TEXTURE2D(_AlphaMap, sampler_AlphaMap, uv);
    // detect back faces
    float3 orientationMultiplier = (facing<0?-1:1).xxx;
	// Sample the color map
	float4 colorSample = SAMPLE_TEXTURE2D(_ColorMap, sampler_ColorMap, uv);
    clip(alpha.r*colorSample.a - 0.5);

    float3 color = colorSample.rgb * _ColorTint.rgb;

    // initialize input data
    InputData lightingInput = (InputData)0;
    lightingInput.positionWS = input.positionWS;
    lightingInput.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    lightingInput.shadowCoord = TransformWorldToShadowCoord(input.positionWS);

    // Normal calculation
    float3 normalWS = normalize(input.normalWS)*orientationMultiplier;
    float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv));
    float3x3 tangentToWorld = CreateTangentToWorld(normalWS, input.tangentWS.xyz, input.tangentWS.w);
    
    normalWS = normalize(TransformTangentToWorld(normalTS, tangentToWorld)); // WSNormal with applied Normal Map
    lightingInput.normalWS = normalWS;

    half4 shadowMask = CalculateShadowMask(lightingInput);
    AmbientOcclusionFactor aoFactor = (AmbientOcclusionFactor)0;
    Light mainLight = GetMainLight(lightingInput, shadowMask, aoFactor);

    // Main Lighting
    half3 attenuatedLightColor = mainLight.distanceAttenuation;
    half3 lightDiffuseColor = LightingLambert(attenuatedLightColor, mainLight.direction, lightingInput.normalWS);
    float4 steppedLightColor = SAMPLE_TEXTURE2D(_ShadowStepMap, sampler_ShadowStepMap, float2(lightDiffuseColor.r, 0.5));
    float4 steppedShadowColor = 1-SAMPLE_TEXTURE2D(_ShadowStepMap, sampler_ShadowStepMap, float2(mainLight.shadowAttenuation, 0.5));
    steppedShadowColor = _CastShadowIntensity*steppedShadowColor;
    steppedShadowColor.w = 1.0;
    steppedLightColor = (1-_ShadowIntensity) + (_ShadowIntensity)*steppedLightColor;
    steppedLightColor.w = 1.0;

    float2 metallicUV = dot(normalWS, normalize(lightingInput.viewDirectionWS+mainLight.direction));
    float4 metallicLevel = SAMPLE_TEXTURE2D(_ShadowStepMap, sampler_ShadowStepMap, metallicUV);
    metallicLevel = float4((metallicLevel.xyz+1)*metallicLevel.xyz*metallicLevel.xyz, 1.0);

    float4 finalLightingColor = (max(metallicLevel*(float4(_Metallic.xxx, 1.0) - steppedShadowColor),0)
                                    + float4((1).xxx, 1.0)*saturate(steppedLightColor-steppedShadowColor))
                                *float4(mainLight.color,1.0);


    // ============= Additional Lights =============

    // Extra Light Sources
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0; lightIndex < pixelLightCount; lightIndex++)
    {
        Light light = GetAdditionalLight(lightIndex, lightingInput, shadowMask, aoFactor);
        half3 attenuatedLightColorCurr = light.distanceAttenuation;
        half3 lightDiffuseColorCurr = LightingLambert(attenuatedLightColorCurr, light.direction, lightingInput.normalWS);
        float4 steppedLightColorCurr = SAMPLE_TEXTURE2D(_ShadowStepMap, sampler_ShadowStepMap, float2(lightDiffuseColorCurr.r, 0.5));
        float2 metallicUVCurr = (attenuatedLightColorCurr+0.25)*dot(normalWS, normalize(lightingInput.viewDirectionWS+light.direction));
        float4 metallicLevelCurr = SAMPLE_TEXTURE2D(_ShadowStepMap, sampler_ShadowStepMap, metallicUVCurr);
        float4 finalLightingColorCurr = (max(metallicLevelCurr*(float4(_Metallic.xxx, 1.0)),0)
                                            + float4((1).xxx, 1.0)*saturate(steppedLightColorCurr))
                                        *float4(light.color,1.0);;
        finalLightingColor += float4(finalLightingColorCurr.rgb,1.0);                                    
    }

    // Ambient light
    float3 ambientLightColor = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
    finalLightingColor += float4(ambientLightColor,1.0);



    // ========== Back lighting ==============
    // Fresnel Rim
    float3 rim_color = float3(0.03, 0.08, 0.12)*1.5;

    // Fresnel wih threshold
    float rimValue = (1.0-dot(normalize(normalWS), normalize(lightingInput.viewDirectionWS)))>0.9;
    
    /*
    // Regular Fresnel
    float rimValue = (1.0-dot(normalize(normalWS), normalize(lightingInput.viewDirectionWS)));
    rimValue = rimValue * rimValue;
    rimValue = rimValue * rimValue;
    */

    finalLightingColor += float4(rim_color*rimValue*0.75,0.0);
    
    /*
    // Fake directional Lights
    float3 rim_color_1 = float3(0.4, 0.4, 0.1)*0.6;
    float3 rim_color_2 = float3(0.05, 0.4, 0.6)*0.5;

    float3 no_yviewDirectionWS = normalize(float3(lightingInput.viewDirectionWS.x, 0, lightingInput.viewDirectionWS.z));
    
    float3 rim_direction = float3(0, -0.25, 0.0);
    rim_direction += float3(no_yviewDirectionWS.z,0,-no_yviewDirectionWS.x)*0.75;
    float3 rim_direction_2 = float3(0, 0.25, 0.0);
    rim_direction_2 += float3(no_yviewDirectionWS.z,0,-no_yviewDirectionWS.x)*-0.75;
    
    float3 rimValue_1 = LightingLambert(1.0, rim_direction, lightingInput.normalWS);
    rimValue_1 = rimValue_1*rimValue_1;
    rimValue_1 = SAMPLE_TEXTURE2D(_ShadowStepMap, sampler_ShadowStepMap, float2(rimValue_1.r, 0.5));
    
    float3 rimValue_2 = LightingLambert(1.0, rim_direction_2, lightingInput.normalWS);
    rimValue_2 = rimValue_2*rimValue_2;
    rimValue_2 = SAMPLE_TEXTURE2D(_ShadowStepMap, sampler_ShadowStepMap, float2(rimValue_2.r, 0.5));

    finalLightingColor += float4(3*rim_color_1*rimValue_1,0.0);
    finalLightingColor += float4(3*rim_color_2*rimValue_2,0.0);
    */


    return saturate(float4(color*finalLightingColor,colorSample.z));
}

