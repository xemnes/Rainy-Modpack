/* 
BSL Shaders v7.1.05 by Capt Tatsu, Complementary Shaders by EminGT
*/ 

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Varyings//
#ifndef CLOUDS
varying vec2 texCoord;

varying vec3 normal;
varying vec3 sunVec, upVec;

varying vec4 color;
#endif

//Uniforms//
#ifndef CLOUDS
uniform int isEyeInWater;
uniform int worldTime;

uniform float rainStrength;
uniform float timeAngle, timeBrightness;

uniform ivec2 eyeBrightnessSmooth;

uniform sampler2D texture;
#endif

//Common Variables//
#ifndef CLOUDS
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp(dot(-sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
#endif

//Includes//
#ifndef CLOUDS
#include "/lib/color/lightColor.glsl"
#endif

//Program//
void main(){
    #ifndef CLOUDS
	vec4 albedo = texture2D(texture, texCoord.xy);
	albedo.rgb = pow(albedo.rgb,vec3(2.2));
	
	float quarterNdotU = clamp(0.25 * dot(normal, upVec) + 0.75,0.5,1.0);
	albedo.rgb *= lightCol * quarterNdotU * 0.15 * (sunVisibility + 2) * (1 - rainStrength*(sunVisibility*0.25 + 0.65));
	
	albedo.a *= 0.5 * color.a;
	#else
	vec4 albedo = vec4(0.0);
	#endif
	
    /* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;

	#ifdef ADVANCED_MATERIALS
	/* DRAWBUFFERS:0367 */
	gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
	gl_FragData[2] = vec4(0.0, 0.0, 0.0, 1.0);
	gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
	#endif
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
#ifndef CLOUDS
varying vec2 texCoord;

varying vec3 normal;
varying vec3 sunVec, upVec;

varying vec4 color;
#endif

//Uniforms//
#ifndef CLOUDS
#if AA == 2 || AA == 3
uniform int frameCounter;

uniform float viewWidth;
uniform float viewHeight;
#include "/lib/util/jitter.glsl"
#endif
#if AA == 4
uniform int frameCounter;

uniform float viewWidth;
uniform float viewHeight;
#include "/lib/util/jitter2.glsl"
#endif

uniform float timeAngle;

uniform mat4 gbufferModelView;
#endif

//Program//
void main(){
	#ifndef CLOUDS
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	color = gl_Color;

	normal = normalize(gl_NormalMatrix * gl_Normal);
	
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
	gl_Position = ftransform();

	#if AA > 1
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif
	
	#else
	
	vec4 color = vec4(0.0);
	gl_Position = color;
	
	#endif
	
}

#endif