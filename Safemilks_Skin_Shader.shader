// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Safemilk/Safemilks_Skin_Shader"
{
	Properties
	{
		_SubSurfaceColor("Sub Surface Color", Color) = (1,0.5804797,0.3784602,1)
		_Thickness("Thickness", Float) = 1
		_ThicknessMap("Thickness Map", 2D) = "white" {}
		_TranslucentPower("Translucent Power", Float) = 1
		_Scale("Scale", Range( 0.001 , 100)) = 1
		_NormalDistortion("Normal Distortion", Float) = 1
		_Albedo("Albedo", 2D) = "white" {}
		_SpecMap("Spec Map", 2D) = "white" {}
		_AO("AO", 2D) = "white" {}
		_SmoothnessMask("Smoothness Mask", 2D) = "white" {}
		_BRDF("BRDF", 2D) = "white" {}
		_DetailNormal("Detail Normal", 2D) = "bump" {}
		_NormalMap("Normal Map", 2D) = "bump" {}
		_AlbedoTinting("Albedo Tinting", Color) = (1,1,1,0)
		_SpecTint("Spec Tint", Color) = (1,1,1,0)
		_Smoothness("Smoothness", Range( 0.005 , 1)) = 1
		_SecondarySpecLobeColor("Secondary Spec Lobe Color", Color) = (1,1,1,0)
		_SkinDetailTiling("Skin Detail Tiling", Float) = 1
		_DetailIntensity("Detail Intensity", Range( 0 , 1)) = 1
		_BentNormal("Bent Normal", 2D) = "bump" {}
		_CurveBias("Curve Bias", Range( 0.005 , 1)) = 0.005
		_Cavity("Cavity", 2D) = "white" {}
		_RimPower("Rim Power", Float) = 3.22
		_Rim("Rim", Float) = 3.22
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IgnoreProjector" = "True" }
		Cull Back
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#include "UnityStandardUtils.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#pragma multi_compile_instancing
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float3 worldNormal;
			INTERNAL_DATA
			float2 uv_texcoord;
			float3 worldPos;
			float3 viewDir;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		uniform sampler2D _NormalMap;
		uniform float4 _NormalMap_ST;
		uniform float _NormalDistortion;
		uniform float _TranslucentPower;
		uniform float _Scale;
		uniform float4 _SubSurfaceColor;
		uniform sampler2D _ThicknessMap;
		uniform float4 _ThicknessMap_ST;
		uniform float _Thickness;
		uniform sampler2D _Albedo;
		uniform float4 _Albedo_ST;
		uniform float4 _AlbedoTinting;
		uniform sampler2D _BRDF;
		uniform float _CurveBias;
		uniform float _DetailIntensity;
		uniform sampler2D _DetailNormal;
		uniform float _SkinDetailTiling;
		uniform sampler2D _SpecMap;
		uniform float4 _SpecMap_ST;
		uniform float4 _SecondarySpecLobeColor;
		uniform sampler2D _Cavity;
		uniform float4 _Cavity_ST;
		uniform float4 _SpecTint;
		uniform float _Rim;
		uniform float _RimPower;
		uniform float _Smoothness;
		uniform sampler2D _SmoothnessMask;
		uniform float4 _SmoothnessMask_ST;
		uniform sampler2D _BentNormal;
		uniform float4 _BentNormal_ST;
		uniform sampler2D _AO;
		uniform float4 _AO_ST;


		float4 CalculateContrast( float contrastValue, float4 colorTarget )
		{
			float t = 0.5 * ( 1.0 - contrastValue );
			return mul( float4x4( contrastValue,0,0,t, 0,contrastValue,0,t, 0,0,contrastValue,t, 0,0,0,1 ), colorTarget );
		}

		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			#ifdef UNITY_PASS_FORWARDBASE
			float ase_lightAtten = data.atten;
			if( _LightColor0.a == 0)
			ase_lightAtten = 0;
			#else
			float3 ase_lightAttenRGB = gi.light.color / ( ( _LightColor0.rgb ) + 0.000001 );
			float ase_lightAtten = max( max( ase_lightAttenRGB.r, ase_lightAttenRGB.g ), ase_lightAttenRGB.b );
			#endif
			#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
			half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
			float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
			float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
			ase_lightAtten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
			#endif
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aselc
			float4 ase_lightColor = 0;
			#else //aselc
			float4 ase_lightColor = _LightColor0;
			#endif //aselc
			float2 uv_NormalMap = i.uv_texcoord * _NormalMap_ST.xy + _NormalMap_ST.zw;
			float3 tex2DNode6 = UnpackNormal( tex2D( _NormalMap, uv_NormalMap ) );
			float Normal51_g8 = tex2DNode6.x;
			float3 temp_cast_2 = (Normal51_g8).xxx;
			UnityGI gi56_g8 = gi;
			float3 diffNorm56_g8 = (WorldNormalVector( i , temp_cast_2 ));
			gi56_g8 = UnityGI_Base( data, 1, diffNorm56_g8 );
			float3 indirectDiffuse56_g8 = gi56_g8.indirect.diffuse + diffNorm56_g8 * 0.0001;
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float3 normalizeResult7_g8 = normalize( ( ase_worldlightDir + ( Normal51_g8 * _NormalDistortion ) ) );
			float3 transLightDir9_g8 = normalizeResult7_g8;
			float dotResult12_g8 = dot( ase_worldViewDir , ( transLightDir9_g8 * -1.0 ) );
			float temp_output_15_0_g8 = pow( saturate( dotResult12_g8 ) , _TranslucentPower );
			float transDot18_g8 = ( temp_output_15_0_g8 * _Scale );
			float3 temp_cast_3 = (Normal51_g8).xxx;
			float dotResult26_g8 = dot( (WorldNormalVector( i , temp_cast_3 )) , -ase_worldlightDir );
			float dotResult28_g8 = dot( -ase_worldlightDir , ase_worldViewDir );
			float2 uv_ThicknessMap = i.uv_texcoord * _ThicknessMap_ST.xy + _ThicknessMap_ST.zw;
			float3 ase_objectScale = float3( length( unity_ObjectToWorld[ 0 ].xyz ), length( unity_ObjectToWorld[ 1 ].xyz ), length( unity_ObjectToWorld[ 2 ].xyz ) );
			float4 transLight48_g8 = ( ( float4( ( ( indirectDiffuse56_g8 + transDot18_g8 ) * saturate( ( ( dotResult26_g8 + dotResult28_g8 ) * 200.0 ) ) ) , 0.0 ) * _SubSurfaceColor * tex2D( _ThicknessMap, uv_ThicknessMap ) ) / float4( ( _Thickness * ase_objectScale ) , 0.0 ) );
			float4 transAlbedo50_g8 = ( float4( ase_lightColor.rgb , 0.0 ) * transLight48_g8 * ase_lightAtten );
			SurfaceOutputStandardSpecular s2 = (SurfaceOutputStandardSpecular ) 0;
			float2 uv_Albedo = i.uv_texcoord * _Albedo_ST.xy + _Albedo_ST.zw;
			float4 tex2DNode10 = tex2D( _Albedo, uv_Albedo );
			float3 newWorldNormal42 = (WorldNormalVector( i , UnpackNormal( tex2D( _NormalMap, uv_NormalMap ) ) ));
			float dotResult124 = dot( newWorldNormal42 , ase_worldlightDir );
			float dotResult51 = dot( float4( float3(0.22,8.46,0.071) , 0.0 ) , ase_lightColor );
			float deltaWorldNormal73 = length( ( abs( ddx( newWorldNormal42 ) ) + abs( ddy( newWorldNormal42 ) ) ) );
			float deltaWorldPosition78 = length( ( abs( ddx( ase_worldPos ) ) + abs( ddy( ase_worldPos ) ) ) );
			float curvature87 = ( ( deltaWorldNormal73 / deltaWorldPosition78 ) * 0.005 );
			float2 appendResult59 = (float2(pow( ( ( dotResult124 * 0.5 ) + 0.5 ) , _CurveBias ) , ( dotResult51 * curvature87 )));
			s2.Albedo = ( ( tex2DNode10 * _AlbedoTinting ) * tex2D( _BRDF, appendResult59 ) ).rgb;
			float2 temp_cast_8 = (_SkinDetailTiling).xx;
			float2 uv_TexCoord187 = i.uv_texcoord * temp_cast_8;
			float3 tex2DNode186 = UnpackScaleNormal( tex2D( _DetailNormal, uv_TexCoord187 ), _DetailIntensity );
			s2.Normal = WorldNormalVector( i , BlendNormals( tex2DNode6 , tex2DNode186 ) );
			s2.Emission = float3( 0,0,0 );
			float2 uv_SpecMap = i.uv_texcoord * _SpecMap_ST.xy + _SpecMap_ST.zw;
			float4 tex2DNode16 = tex2D( _SpecMap, uv_SpecMap );
			float2 uv_Cavity = i.uv_texcoord * _Cavity_ST.xy + _Cavity_ST.zw;
			float4 tex2DNode213 = tex2D( _Cavity, uv_Cavity );
			float4 color293 = IsGammaSpace() ? float4(0,0,0,0.8470588) : float4(0,0,0,0.8470588);
			float4 lerpResult183 = lerp( ( tex2DNode16 * _SecondarySpecLobeColor * tex2DNode213 ) , ( tex2DNode16 * _SpecTint ) , color293.a);
			float3 NormalMap217 = tex2DNode6;
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_tangentToWorldFast = float3x3(ase_worldTangent.x,ase_worldBitangent.x,ase_worldNormal.x,ase_worldTangent.y,ase_worldBitangent.y,ase_worldNormal.y,ase_worldTangent.z,ase_worldBitangent.z,ase_worldNormal.z);
			float fresnelNdotV212 = dot( mul(ase_tangentToWorldFast,NormalMap217), ase_worldViewDir );
			float fresnelNode212 = ( 0.0 + ( lerpResult183 * _Rim ).r * pow( 1.0 - fresnelNdotV212, _RimPower ) );
			s2.Specular = ( lerpResult183 + fresnelNode212 ).rgb;
			float4 temp_cast_11 = (( _Smoothness + 0.5 )).xxxx;
			float3 detailNormals204 = tex2DNode186;
			float3 o2206 = ( ( 1.0 - detailNormals204 ) / detailNormals204 );
			float3 nP202 = ( float3( 0,0,0 ) + ( _Smoothness / ( 1.0 + o2206 ) ) );
			float grayscale318 = Luminance(( ( 1.0 / _Smoothness ) + nP202 ));
			float4 temp_cast_12 = (grayscale318).xxxx;
			float4 detailVarianceGloss208 = CalculateContrast(2.0,temp_cast_12);
			float temp_output_210_0 = pow( _Smoothness , detailVarianceGloss208.r );
			float2 uv_SmoothnessMask = i.uv_texcoord * _SmoothnessMask_ST.xy + _SmoothnessMask_ST.zw;
			float4 color350 = IsGammaSpace() ? float4(0,0,0,0.8470588) : float4(0,0,0,0.8470588);
			float4 lerpResult191 = lerp( temp_cast_11 , ( temp_output_210_0 * ( tex2D( _SmoothnessMask, uv_SmoothnessMask ) * tex2DNode213 * temp_output_210_0 ) ) , color350.a);
			s2.Smoothness = lerpResult191.r;
			float2 uv_BentNormal = i.uv_texcoord * _BentNormal_ST.xy + _BentNormal_ST.zw;
			float dotResult310 = dot( normalize( (WorldNormalVector( i , UnpackNormal( tex2D( _BentNormal, uv_BentNormal ) ) )) ) , _WorldSpaceLightPos0.xyz );
			float BentNormals312 = dotResult310;
			float2 uv_AO = i.uv_texcoord * _AO_ST.xy + _AO_ST.zw;
			float dotResult228 = dot( normalize( (WorldNormalVector( i , NormalMap217 )) ) , i.viewDir );
			float NdotV234 = dotResult228;
			float s238 = saturate( ( ( NdotV234 * NdotV234 ) + -0.03 ) );
			float4 temp_cast_15 = (s238).xxxx;
			float4 lerpResult226 = lerp( pow( tex2D( _AO, uv_AO ) , 8.0 ) , temp_cast_15 , s238);
			float4 AO288 = max( ( BentNormals312 + lerpResult226 ) , lerpResult226 );
			s2.Occlusion = AO288.r;

			data.light = gi.light;

			UnityGI gi2 = gi;
			#ifdef UNITY_PASS_FORWARDBASE
			Unity_GlossyEnvironmentData g2 = UnityGlossyEnvironmentSetup( s2.Smoothness, data.worldViewDir, s2.Normal, float3(0,0,0));
			gi2 = UnityGlobalIllumination( data, s2.Occlusion, s2.Normal, g2 );
			#endif

			float3 surfResult2 = LightingStandardSpecular ( s2, viewDir, gi2 ).rgb;
			surfResult2 += s2.Emission;

			c.rgb = ( ( transAlbedo50_g8 + float4( surfResult2 , 0.0 ) ) * tex2DNode10.a ).rgb;
			c.a = 1;
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.viewDir = IN.tSpace0.xyz * worldViewDir.x + IN.tSpace1.xyz * worldViewDir.y + IN.tSpace2.xyz * worldViewDir.z;
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputCustomLightingCustom o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputCustomLightingCustom, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}

	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=16100
319;170;1791;972;5355.606;-501.2856;3.881626;True;True
Node;AmplifyShaderEditor.RangedFloatNode;188;-4669.527,539.1847;Float;False;Property;_SkinDetailTiling;Skin Detail Tiling;18;0;Create;True;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;187;-4451.471,502.8073;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;190;-4452.776,391.6307;Float;False;Property;_DetailIntensity;Detail Intensity;19;0;Create;True;0;0;False;0;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;186;-4091.871,417.7073;Float;True;Property;_DetailNormal;Detail Normal;12;0;Create;True;0;0;False;0;None;None;True;0;True;bump;Auto;True;Object;-1;MipLevel;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;204;-3527.335,361.0205;Float;False;detailNormals;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;205;-5863.713,2718.929;Float;False;204;detailNormals;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.OneMinusNode;192;-5592.298,2805.196;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;193;-5380.958,2699.222;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;6;-4062.037,668.3516;Float;True;Property;_NormalMap;Normal Map;13;0;Create;True;0;0;False;0;None;None;True;0;True;bump;Auto;True;Object;-1;MipLevel;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;206;-5234.39,2710.309;Float;True;o2;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;286;-7778.699,15.12895;Float;True;Property;_TextureSample0;Texture Sample 0;13;1;[Normal];Create;True;0;0;False;0;None;None;True;0;False;white;Auto;True;Instance;6;MipLevel;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldNormalVector;42;-7404.657,134.7114;Float;False;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;217;-3679.065,791.0761;Float;False;NormalMap;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;195;-5531.859,3257.542;Float;False;Constant;_Float3;Float 3;21;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;207;-5538.525,3124.499;Float;False;206;o2;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;194;-5224.061,3125.075;Float;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;231;-1751.935,2380.846;Float;False;217;NormalMap;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;8;-4745.629,2327.321;Float;False;Property;_Smoothness;Smoothness;16;0;Create;True;0;0;False;0;1;0.567;0.005;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;85;-7072.704,-509.3596;Float;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WireNode;292;-7099.256,-697.9592;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;291;-7196.113,-697.9593;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DdxOpNode;254;-6933.967,-1036.975;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;196;-5085.11,3000.939;Float;True;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DdyOpNode;259;-6788.691,-479.6127;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DdyOpNode;262;-6933.23,-948.7751;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;232;-1685.252,2593.058;Float;False;Tangent;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;230;-1514.628,2456.191;Float;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DdxOpNode;255;-6791.144,-558.9639;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.AbsOpNode;256;-6647.093,-559.2772;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.AbsOpNode;258;-6648.825,-477.0807;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.AbsOpNode;253;-6724.213,-1036.481;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.AbsOpNode;261;-6728.994,-944.9402;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;198;-4823.471,3042.645;Float;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DotProductOpNode;228;-1212.628,2510.191;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;234;-1063.765,2517.046;Float;False;NdotV;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;257;-6473.47,-543.7708;Float;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;263;-6511.348,-1033.589;Float;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;200;-4364.31,2791.816;Float;False;Constant;_Float4;Float 4;21;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;202;-4671.27,3054.711;Float;True;nP;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;233;-1416.765,2664.045;Float;False;234;NdotV;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;84;-6054.791,-690.6139;Float;True;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;203;-4301.925,2882.188;Float;False;202;nP;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LengthOpNode;69;-6037.448,-962.6431;Float;True;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;235;-1406.765,2748.045;Float;False;234;NdotV;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;199;-4150.289,2776.901;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;78;-5754.654,-717.6759;Float;False;deltaWorldPosition;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;236;-1119.765,2725.045;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;73;-5759.712,-910.8181;Float;False;deltaWorldNormal;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;201;-3999.623,2791.423;Float;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;237;-960.7642,2722.045;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;-0.03;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;86;-5343.33,-739.2471;Float;False;78;deltaWorldPosition;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;72;-5336.872,-983.9891;Float;False;73;deltaWorldNormal;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCGrayscale;318;-3817.93,2829.583;Float;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;307;-1575.656,2902.85;Float;True;Property;_BentNormal;Bent Normal;20;0;Create;True;0;0;False;0;None;None;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldSpaceLightPos;321;-1571.486,3103.352;Float;False;0;3;FLOAT4;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.WorldNormalVector;313;-1265.433,2912.969;Float;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SaturateNode;229;-830.6273,2732.191;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleContrastOpNode;319;-3590.93,2830.583;Float;True;2;1;COLOR;0,0,0,0;False;0;FLOAT;2;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;74;-4899.299,-887.9386;Float;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;90;-5013.922,-641.6748;Float;False;Constant;_CurveScale;CurveScale;23;0;Create;True;0;0;False;0;0.005;1;0;0.005;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;123;-7458.566,-135.9486;Float;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;310;-1037.588,3089.618;Float;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;208;-3326.742,2825.113;Float;True;detailVarianceGloss;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;19;-1761.015,2119.912;Float;True;Property;_AO;AO;9;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DotProductOpNode;124;-6775.515,-50.06149;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;238;-652.764,2738.045;Float;False;s;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;88;-4599.624,-776.1288;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;209;-4727.074,2117.881;Float;False;208;detailVarianceGloss;1;0;OBJECT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;16;-4780.54,1174.514;Float;True;Property;_SpecMap;Spec Map;8;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LightColorNode;52;-6718.341,409.3504;Float;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.RegisterLocalVarNode;87;-3958.197,-834.7986;Float;True;curvature;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;239;-1377.161,2213.885;Float;False;238;s;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;213;-4775.262,1580.996;Float;True;Property;_Cavity;Cavity;22;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PowerNode;225;-1368.237,2120.268;Float;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;8;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;312;-823.2308,3085.995;Float;False;BentNormals;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;135;-6600.542,-52.30245;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;17;-4738.638,974.6649;Float;False;Property;_SpecTint;Spec Tint;15;0;Create;True;0;0;False;0;1,1,1,0;0.2641506,0.2641506,0.2641506,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector3Node;95;-6733.226,250.6773;Float;False;Constant;_Vector0;Vector 0;12;0;Create;True;0;0;False;0;0.22,8.46,0.071;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ColorNode;176;-4776.353,1382.832;Float;False;Property;_SecondarySpecLobeColor;Secondary Spec Lobe Color;17;0;Create;True;0;0;False;0;1,1,1,0;0.2641506,0.2641506,0.2641506,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PowerNode;210;-4260.497,1982.369;Float;False;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;5;-4763.698,1830.225;Float;True;Property;_SmoothnessMask;Smoothness Mask;10;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;293;-4134.27,1086.229;Float;False;Constant;_Color0;Color 0;17;0;Create;True;0;0;False;0;0,0,0,0.8470588;0.2641506,0.2641506,0.2641506,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;93;-6719.969,536.7662;Float;True;87;curvature;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;143;-6692.651,158.8335;Float;False;Property;_CurveBias;Curve Bias;21;0;Create;True;0;0;False;0;0.005;0.44;0.005;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;226;-1090.421,2144.873;Float;False;3;0;COLOR;0,0,0,0;False;1;COLOR;1,1,1,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;15;-3867.943,972.0449;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DotProductOpNode;51;-6323.418,294.4844;Float;False;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;311;-1121.725,2058.747;Float;False;312;BentNormals;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;174;-3902.115,1282.944;Float;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;136;-6383.803,-32.42979;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;183;-3634.887,1027.216;Float;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;97;-6122.265,295.3816;Float;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;360;-3460.724,1394.433;Float;False;Property;_Rim;Rim;25;0;Create;True;0;0;False;0;3.22;2.71;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;7;-3939.016,1651.565;Float;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;324;-893.8533,2125.394;Float;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.PowerNode;146;-6182.544,116.7033;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;219;-3590.723,1539.947;Float;False;Property;_RimPower;Rim Power;24;0;Create;True;0;0;False;0;3.22;2.71;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;112;-5498.521,-268.187;Float;True;Property;_BRDF;BRDF;11;0;Create;True;0;0;False;0;None;None;False;white;Auto;Texture2D;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.GetLocalVarNode;216;-3481.13,1251.305;Float;False;217;NormalMap;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;59;-5611.6,192.8733;Float;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;10;-4090.425,-358.0537;Float;True;Property;_Albedo;Albedo;7;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;9;-3888.933,-119.3644;Float;False;Property;_AlbedoTinting;Albedo Tinting;14;0;Create;True;0;0;False;0;1,1,1,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;359;-3220.222,1395.733;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;350;-3382.595,1952.661;Float;False;Constant;_Color1;Color 1;17;0;Create;True;0;0;False;0;0,0,0,0.8470588;0.2641506,0.2641506,0.2641506,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;296;-3381.145,1583.195;Float;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;357;-4121.695,2399.657;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;364;-796.8879,2251.815;Float;False;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-3437.935,-125.3242;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.BlendNormalsNode;189;-3521.293,490.7301;Float;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;288;-637.5114,2114.963;Float;True;AO;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;191;-3112.324,1662.027;Float;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;-4.46;False;1;COLOR;0
Node;AmplifyShaderEditor.FresnelNode;212;-2870.267,1255.088;Float;True;Standard;TangentNormal;ViewDir;True;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;2.69;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;26;-5142.495,169.1095;Float;True;Property;_WarpBRDF;Warp BRDF;11;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WireNode;351;-1916.095,1344.225;Float;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;289;-1741.307,393.6196;Float;False;288;AO;1;0;OBJECT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;27;-2465.488,60.17225;Float;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;220;-2562.832,1147.213;Float;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;369;-2742.394,347.1779;Float;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CustomStandardSurface;2;-1344.176,284.5429;Float;False;Specular;Tangent;6;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,1;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;5;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;25;-1243.1,97.39999;Float;False;Tanslucency Function;0;;8;9cece9ce987cfef4ba1cf79e11aa26a3;0;1;54;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;12;-671.5027,386.6598;Float;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;370;-7523.669,2020.494;Float;False;PerturbNormalHQ;-1;;9;45dff16e78a0685469fed8b5b46e4d96;0;4;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;265;-7261.124,1280.293;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;276;-6488.291,1284.282;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;264;-6125.219,1380.964;Float;False;m;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;273;-7102.897,1278.765;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;267;-7676.327,1202.54;Float;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;274;-6819.29,1278.282;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;277;-3845.455,121.6973;Float;False;264;m;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;147;-456.7064,-18.98296;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.DotProductOpNode;266;-7411.327,1278.541;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightAttenuation;278;-6572.164,1422.195;Float;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;272;-6944.157,1279.637;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;269;-7925.735,1272.332;Float;False;217;NormalMap;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;355;-6722.803,750.9288;Float;True;Property;_Curve;Curve;23;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;270;-7687.22,1348.31;Float;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;271;-6324.098,1379.543;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;275;-6650.291,1281.282;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1.090303,-1.090303;Float;False;True;2;Float;ASEMaterialInspector;0;0;CustomLighting;Safemilk/Safemilks_Skin_Shader;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;True;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;1;=;0;False;-1;-1;0;False;-1;0;0;0;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;187;0;188;0
WireConnection;186;1;187;0
WireConnection;186;5;190;0
WireConnection;204;0;186;0
WireConnection;192;0;205;0
WireConnection;193;0;192;0
WireConnection;193;1;205;0
WireConnection;206;0;193;0
WireConnection;42;0;286;0
WireConnection;217;0;6;0
WireConnection;194;0;195;0
WireConnection;194;1;207;0
WireConnection;292;0;42;0
WireConnection;291;0;42;0
WireConnection;254;0;291;0
WireConnection;196;0;8;0
WireConnection;196;1;194;0
WireConnection;259;0;85;0
WireConnection;262;0;292;0
WireConnection;230;0;231;0
WireConnection;255;0;85;0
WireConnection;256;0;255;0
WireConnection;258;0;259;0
WireConnection;253;0;254;0
WireConnection;261;0;262;0
WireConnection;198;1;196;0
WireConnection;228;0;230;0
WireConnection;228;1;232;0
WireConnection;234;0;228;0
WireConnection;257;0;256;0
WireConnection;257;1;258;0
WireConnection;263;0;253;0
WireConnection;263;1;261;0
WireConnection;202;0;198;0
WireConnection;84;0;257;0
WireConnection;69;0;263;0
WireConnection;199;0;200;0
WireConnection;199;1;8;0
WireConnection;78;0;84;0
WireConnection;236;0;233;0
WireConnection;236;1;235;0
WireConnection;73;0;69;0
WireConnection;201;0;199;0
WireConnection;201;1;203;0
WireConnection;237;0;236;0
WireConnection;318;0;201;0
WireConnection;313;0;307;0
WireConnection;229;0;237;0
WireConnection;319;1;318;0
WireConnection;74;0;72;0
WireConnection;74;1;86;0
WireConnection;310;0;313;0
WireConnection;310;1;321;1
WireConnection;208;0;319;0
WireConnection;124;0;42;0
WireConnection;124;1;123;0
WireConnection;238;0;229;0
WireConnection;88;0;74;0
WireConnection;88;1;90;0
WireConnection;87;0;88;0
WireConnection;225;0;19;0
WireConnection;312;0;310;0
WireConnection;135;0;124;0
WireConnection;210;0;8;0
WireConnection;210;1;209;0
WireConnection;226;0;225;0
WireConnection;226;1;239;0
WireConnection;226;2;239;0
WireConnection;15;0;16;0
WireConnection;15;1;17;0
WireConnection;51;0;95;0
WireConnection;51;1;52;0
WireConnection;174;0;16;0
WireConnection;174;1;176;0
WireConnection;174;2;213;0
WireConnection;136;0;135;0
WireConnection;183;0;174;0
WireConnection;183;1;15;0
WireConnection;183;2;293;4
WireConnection;97;0;51;0
WireConnection;97;1;93;0
WireConnection;7;0;5;0
WireConnection;7;1;213;0
WireConnection;7;2;210;0
WireConnection;324;0;311;0
WireConnection;324;1;226;0
WireConnection;146;0;136;0
WireConnection;146;1;143;0
WireConnection;59;0;146;0
WireConnection;59;1;97;0
WireConnection;359;0;183;0
WireConnection;359;1;360;0
WireConnection;296;0;210;0
WireConnection;296;1;7;0
WireConnection;357;0;8;0
WireConnection;364;0;324;0
WireConnection;364;1;226;0
WireConnection;11;0;10;0
WireConnection;11;1;9;0
WireConnection;189;0;6;0
WireConnection;189;1;186;0
WireConnection;288;0;364;0
WireConnection;191;0;357;0
WireConnection;191;1;296;0
WireConnection;191;2;350;4
WireConnection;212;0;216;0
WireConnection;212;2;359;0
WireConnection;212;3;219;0
WireConnection;26;0;112;0
WireConnection;26;1;59;0
WireConnection;351;0;191;0
WireConnection;27;0;11;0
WireConnection;27;1;26;0
WireConnection;220;0;183;0
WireConnection;220;1;212;0
WireConnection;369;0;189;0
WireConnection;2;0;27;0
WireConnection;2;1;369;0
WireConnection;2;3;220;0
WireConnection;2;4;351;0
WireConnection;2;5;289;0
WireConnection;25;54;6;0
WireConnection;12;0;25;0
WireConnection;12;1;2;0
WireConnection;265;0;266;0
WireConnection;276;0;275;0
WireConnection;264;0;271;0
WireConnection;273;0;265;0
WireConnection;267;0;269;0
WireConnection;274;0;272;0
WireConnection;147;0;12;0
WireConnection;147;1;10;4
WireConnection;266;0;267;0
WireConnection;266;1;270;0
WireConnection;272;0;273;0
WireConnection;271;0;276;0
WireConnection;271;1;278;0
WireConnection;275;0;274;0
WireConnection;0;13;147;0
ASEEND*/
//CHKSM=A31C9884631B0B19D5D8A21FA1F71A7486078CFA