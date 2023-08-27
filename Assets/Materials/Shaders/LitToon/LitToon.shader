Shader "Anime/LitToon"
{
    Properties
    {
        [Header(Surface options)]
        [MainTexture] _ColorMap("Color", 2D) = "white" {}
        [MainColor] _ColorTint("Tint", Color) = (1, 1, 1, 1)
        [NoScaleOffset][Normal] _NormalMap("Normal", 2D) = "bump" {}
        [MainTexture] _AlphaMap("Alpha", 2D) = "white" {}
        _Metallic("Metallic", Range(0,1)) = 0.0
        [Header(Shadows)]
        _ShadowStepMap("Shadow Step", 2D) = "white" {}
        _CastShadowIntensity("Cast Shadow Intensity", Range(0,1)) = 1.0
        _ShadowIntensity("Shadow Intensity", Range(0,1)) = 1.0
        [Header(Outlines PostProcessing)]
        _NormalOutlines("NormalOutlines", Range(0,1)) = 1.0
        [Header(Outlines Forward)]
        _OutlineThickness("Outline Thickness", Range(0,1)) = 0.0
        _OutlineWidthMap("Outline Width Map", 2D) = "gray" {}
        _OutlineColor("OutlineColor", Color) = (0.1,0.05,0.05,1)
    }
     SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline"}
        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
                "RenderType" = "Opaque"
            }

            Cull Off
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM

            #define _SPECULAR_COLOR
            #pragma target 3.0
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "LitToonInput.hlsl"
            #include "LitToonForwardLitPass.hlsl"
            ENDHLSL
        }

                Pass
        {
            Name "DepthNormal" 
            Tags
            {
                "LightMode" = "DepthNormals"
                "RenderType" = "Opaque"
            } 
            
            Cull Off
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM

            #define _SPECULAR_COLOR
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "LitToonInput.hlsl"
            #include "LitToonDepthNormalPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}
            ColorMask 0
            Cull Off
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "LitToonCasterPass.hlsl"
            ENDHLSL
        }

                Pass
        {
            Name "Outline" 
            Tags
            {
                "LightMode" = "SRPDefaultUnlit"
                "RenderType" = "Opaque"
            } 
            
            Cull Front
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM

            #define _SPECULAR_COLOR
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "LitToonInput.hlsl"
            #include "LitToonOutlinePass.hlsl"
            ENDHLSL
        }
    }
}
