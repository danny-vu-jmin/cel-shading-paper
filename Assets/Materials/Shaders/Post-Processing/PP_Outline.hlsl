#ifndef PP_OUTLINE_INCLUDED
#define PP_OUTLINE_INCLUDED

float getDepth(float2 uv)
{
	return SHADERGRAPH_SAMPLE_SCENE_DEPTH(uv.xy);
	return min(1, LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(uv.xy), _ZBufferParams)*0.001);
}

float Outline_scale(float scale, float width, float height, float4 uv, float fresnel)
{
    float depth = getDepth(uv.xy);

	float depth_threshold = (0.05 + depth*0.5);

	float halfScaleFloor = floor(scale*0.5);
	float halfScaleCeil = ceil(scale*0.5);

	float2 bottomLeftuv = uv - float2(1/width, 1/height) * halfScaleFloor;
	float2 topRightuv = uv + float2(1/width, 1/height) * halfScaleCeil;  
	float2 bottomRightuv = uv + float2(1/width * halfScaleCeil, - 1/height * halfScaleFloor);
	float2 topLeftuv = uv + float2(- 1/width * halfScaleFloor, 1/height * halfScaleCeil);

	float depth0 = getDepth(bottomLeftuv);
	float depth1 = getDepth(topRightuv);
	float depth2 = getDepth(bottomRightuv);
	float depth3 = getDepth(topLeftuv);
    

	float depthFiniteDifference0 = depth1 - depth0;
	float depthFiniteDifference1 = depth3 - depth2;
	
	float edgeDepth = sqrt(pow(depthFiniteDifference0, 2) + pow(depthFiniteDifference1, 2)) * 100;

    
    depth_threshold = depth_threshold * (0.25 + (1+pow(65*depth,1))*(fresnel+0.05)) *(scale+0.5*scale) ;
	
	edgeDepth = edgeDepth > depth_threshold ? 1 : 0;
	float normal_threshold = 0.75 + 0.08*scale;

	float3 normal0 = SHADERGRAPH_SAMPLE_SCENE_NORMAL(bottomLeftuv);
	float3 normal1 = SHADERGRAPH_SAMPLE_SCENE_NORMAL(topRightuv);
	float3 normal2 = SHADERGRAPH_SAMPLE_SCENE_NORMAL(bottomRightuv);
	float3 normal3 = SHADERGRAPH_SAMPLE_SCENE_NORMAL(topLeftuv);
    
	float3 normalFiniteDifference0 = normal1 - normal0;
	float3 normalFiniteDifference1 = normal3 - normal2;

	float edgeNormal = sqrt(dot(normalFiniteDifference0, normalFiniteDifference0) + dot(normalFiniteDifference1, normalFiniteDifference1));
	edgeNormal = edgeNormal > normal_threshold ? 1 : 0;
	float _line = max(edgeNormal,edgeDepth);

	return _line;
}

void Outline_float(float width, float height, float4 uv, float fresnel, float depth, out float3 Out)
{
    Out = SHADERGRAPH_SAMPLE_SCENE_COLOR(uv.xy);
	float scale = min(6,round(1.25+(depth*30*1.6)));
    float _line = Outline_scale(scale, width, height, uv, fresnel);

	Out = Out*saturate(1-_line+0.25*float3(0.3,0.25,0.25));

}


#endif //PP_OUTLINE_INCLUDED