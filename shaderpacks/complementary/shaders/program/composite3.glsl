/* 
BSL Shaders v7.1.05 by Capt Tatsu, Complementary Shaders by EminGT
*/  

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Varyings//
varying vec2 texCoord;

//Uniforms//
uniform sampler2D colortex0;

#if defined DOF_IS_ON || (defined NETHER_BLUR && defined NETHER)

uniform float viewWidth, viewHeight, aspectRatio;

uniform sampler2D depthtex1;
uniform sampler2D depthtex0;

#if DOF == 2 || (defined NETHER_BLUR && defined NETHER)
uniform mat4 gbufferProjectionInverse;
#endif

#if DOF == 1 && !(defined NETHER_BLUR && defined NETHER)
uniform float centerDepthSmooth;
#endif

//Optifine Constants//
const bool colortex0MipmapEnabled = true;

//Common Variables//
vec2 dofOffsets[18] = vec2[18](
	vec2( 0.0    ,  0.25  ),
	vec2(-0.2165 ,  0.125 ),
	vec2(-0.2165 , -0.125 ),
	vec2( 0      , -0.25  ),
	vec2( 0.2165 , -0.125 ),
	vec2( 0.2165 ,  0.125 ),
	vec2( 0      ,  0.5   ),
	vec2(-0.25   ,  0.433 ),
	vec2(-0.433  ,  0.25  ),
	vec2(-0.5    ,  0     ),
	vec2(-0.433  , -0.25  ),
	vec2(-0.25   , -0.433 ),
	vec2( 0      , -0.5   ),
	vec2( 0.25   , -0.433 ),
	vec2( 0.433  , -0.2   ),
	vec2( 0.5    ,  0     ),
	vec2( 0.433  ,  0.25  ),
	vec2( 0.25   ,  0.433 )
);

//Common Functions//
#if DOF == 2 && !(defined NETHER_BLUR && defined NETHER)
vec3 DepthOfField(vec3 color, float z){
	vec3 dof = vec3(0.0);
	float hand = float(z < 0.56);

	float z0 = texture2D(depthtex0, texCoord.xy).r;
	vec4 screenPos = vec4(texCoord.x, texCoord.y, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;
	
	float coc = max(min(length(viewPos) * 0.001, 0.1) * DOF_STRENGTH / 256, 0.001);
	coc = coc / sqrt(coc * coc + 0.1);
	
	if (coc * 0.5 > 1.0 / max(viewWidth, viewHeight) && hand < 0.5){
		for(int i = 0; i < 18; i++) {
			vec2 offset = dofOffsets[i] * coc * 0.0085 * vec2(1.0, aspectRatio);
			float lod = log2(viewHeight * aspectRatio / 320.0) * coc * 0.75;
			dof += texture2DLod(colortex0, texCoord + offset, lod).rgb;
		}
		dof /= 18.0;
	}
	else dof = color;
	return dof;
}
#endif

#if DOF == 1 && !(defined NETHER_BLUR && defined NETHER)
vec3 DepthOfField(vec3 color, float z){
	vec3 dof = vec3(0.0);
	float hand = float(z < 0.56);
	
	float coc = max(abs(z - centerDepthSmooth) * 0.125 * DOF_STRENGTH - 0.0001, 0.001);
	coc = coc / sqrt(coc * coc + 0.1);
	
	if (coc * 0.5 > 1.0 / max(viewWidth, viewHeight) && hand < 0.5){
		for(int i = 0; i < 18; i++) {
			vec2 offset = dofOffsets[i] * coc * 0.0085 * vec2(1.0, aspectRatio);
			float lod = log2(viewHeight * aspectRatio / 320.0) * coc * 0.75;
			dof += texture2DLod(colortex0, texCoord + offset, lod).rgb;
		}
		dof /= 18.0;
	}
	else dof = color;
	return dof;
}
#endif

#if defined NETHER_BLUR && defined NETHER
vec3 DepthOfField(vec3 color, float z){
	vec3 dof = vec3(0.0);
	float hand = float(z < 0.56);

	float z0 = texture2D(depthtex0, texCoord.xy).r;
	vec4 screenPos = vec4(texCoord.x, texCoord.y, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;
	
	float coc = max(min(length(viewPos) * 0.001, 0.1) * NETHER_BLUR_STRENGTH / 256, 0.001);
	coc = coc / sqrt(coc * coc + 0.1);
	
	if (coc * 0.5 > 1.0 / max(viewWidth, viewHeight) && hand < 0.5){
		for(int i = 0; i < 18; i++) {
			vec2 offset = dofOffsets[i] * coc * 0.0085 * vec2(1.0, aspectRatio);
			float lod = log2(viewHeight * aspectRatio / 320.0) * coc * 0.75;
			dof += texture2DLod(colortex0, texCoord + offset, lod).rgb;
		}
		dof /= 18.0;
	}
	else dof = color;
	return dof;
}
#endif

//Includes//

#endif

//Program//
void main(){
	vec3 color = texture2D(colortex0,texCoord).rgb;
	
	#if defined DOF_IS_ON || (defined NETHER && defined NETHER_BLUR)
	float z = texture2D(depthtex1, texCoord.st).x;

	color = DepthOfField(color, z);
	#endif
	
    /*DRAWBUFFERS:0*/
	gl_FragData[0] = vec4(color,1.0);
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying vec2 texCoord;

//Program//
void main(){
	texCoord = gl_MultiTexCoord0.xy;
	
	gl_Position = ftransform();
}

#endif