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
	float thickness : TEXCOORD4;
};


Frag2Vert Vertex(Attributes input) {
	Frag2Vert output;
	float3 _Object_Scale = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                             length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                             length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)));
	
	float4 outlineMapThickness = SAMPLE_TEXTURE2D_LOD(_OutlineWidthMap, sampler_OutlineWidthMap, input.uv, 0);
	float thickness = 0.0030*_OutlineThickness*(2*outlineMapThickness.r);
	float3 camPosWS = _WorldSpaceCameraPos;
	float dist = length(camPosWS-GetVertexPositionInputs(input.positionOS).positionWS);
	thickness=thickness+thickness*dist*2.5;
	float3 position = input.positionOS+normalize(input.normalOS)*thickness/_Object_Scale;
	VertexPositionInputs posnInputs = GetVertexPositionInputs(position);
    VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);

	output.positionCS = posnInputs.positionCS;
	output.uv = TRANSFORM_TEX(input.uv, _ColorMap);
    output.normalWS = normInputs.normalWS;
    output.tangentWS = float4(normInputs.tangentWS, input.tangentOS.w);
    output.positionWS = posnInputs.positionWS;
	output.thickness = thickness;

	return output;
}

float4 Fragment(Frag2Vert input) : SV_TARGET
{
	clip(input.thickness-0.0001);
	float2 uv = input.uv;
	float4 alpha = SAMPLE_TEXTURE2D(_AlphaMap, sampler_AlphaMap, uv);
	float4 colorSample = SAMPLE_TEXTURE2D(_ColorMap, sampler_ColorMap, uv);
	clip(alpha.r*colorSample.a - 0.5);
    float3 color = colorSample.rgb * _ColorTint.rgb;
	float3 outlineColor = _OutlineColor*color;
	return float4(outlineColor*0,1.0);
}

