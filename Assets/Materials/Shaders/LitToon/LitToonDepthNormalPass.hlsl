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

	VertexPositionInputs posnInputs = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);

	output.positionCS = posnInputs.positionCS;
	output.uv = TRANSFORM_TEX(input.uv, _ColorMap);
    output.normalWS = normInputs.normalWS;
    output.tangentWS = float4(normInputs.tangentWS, input.tangentOS.w);
    output.positionWS = posnInputs.positionWS;

	return output;
}

void Fragment(Frag2Vert input, out half4 outNormalWS : SV_Target0)
{
    float2 uv = input.uv;
	float4 alpha = SAMPLE_TEXTURE2D(_AlphaMap, sampler_AlphaMap, uv);
	float4 colorSample = SAMPLE_TEXTURE2D(_ColorMap, sampler_ColorMap, uv);
	clip(alpha.r*colorSample.a - 0.5);

    // Normal calculation
    float3 normalWS = normalize(input.normalWS);
    float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv));
    float3x3 tangentToWorld = CreateTangentToWorld(normalWS, input.tangentWS.xyz, input.tangentWS.w);

    outNormalWS = float4(normalWS*_NormalOutlines,0.0);
}

