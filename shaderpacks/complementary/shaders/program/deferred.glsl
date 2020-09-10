/* 
BSL Shaders v7.1.05 by Capt Tatsu, Complementary Shaders by EminGT
*/ 

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Varyings//
varying vec2 texCoord;

varying vec3 sunVec, upVec;

//Uniforms//
uniform int frameCounter;
uniform int isEyeInWater;

uniform float blindFactor, nightVision;
uniform float far, near;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight, aspectRatio;
uniform float worldTime;
uniform float shadowFade;
uniform float eyeAltitude;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 skyColor;
uniform vec3 fogColor;

uniform mat4 gbufferProjection, gbufferPreviousProjection, gbufferProjectionInverse;
uniform mat4 gbufferModelView, gbufferPreviousModelView, gbufferModelViewInverse;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

#ifdef OVERWORLD
uniform float sunAngle;
#endif

#if (defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR) || (defined SEVEN && defined STARS)
uniform vec3 cameraPosition, previousCameraPosition;

uniform sampler2D colortex3;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D noisetex;
#endif

//Optifine Constants//
#if defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR
const bool colortex0MipmapEnabled = true;
const bool colortex5MipmapEnabled = true;
const bool colortex6MipmapEnabled = true;
#endif

//Common Variables//
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility  = clamp(dot( sunVec,upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp(dot(-sunVec,upVec) + 0.05, 0.0, 0.1) * 10.0;

vec3 lightVec = sunVec * (1.0 - 2.0 * float(timeAngle > 0.5325 && timeAngle < 0.9675));

#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

//Common Functions//
float GetLuminance(vec3 color){
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float GetLinearDepth(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}

float InterleavedGradientNoise(){
	float n = 52.9829189 * fract(0.06711056 * gl_FragCoord.x + 0.00583715 * gl_FragCoord.y);
	return fract(n + frameCounter / 8.0);
}

//Includes//
#include "/lib/color/dimensionColor.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/color/blocklightColor.glsl"
#include "/lib/color/waterColor.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/atmospherics/fog.glsl"

#ifdef AO
#include "/lib/lighting/ambientOcclusion.glsl"
#endif

#ifdef BLACK_OUTLINE
#include "/lib/atmospherics/waterFog.glsl"
#include "/lib/outline/blackOutline.glsl"
#endif

#ifdef PROMO_OUTLINE
#include "/lib/outline/promoOutline.glsl"
#endif

#if defined SEVEN && defined STARS
#include "/lib/atmospherics/clouds.glsl"
#endif

#if defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR
#include "/lib/util/encode.glsl"
#include "/lib/reflections/raytrace.glsl"
#include "/lib/reflections/blackFresnel.glsl"
#include "/lib/reflections/complexFresnel.glsl"
#include "/lib/surface/materialDeferred.glsl"
#include "/lib/reflections/roughReflections.glsl"
#endif

//Program//
void main(){
    vec4 color = texture2D(colortex0, texCoord);
	float z    = texture2D(depthtex0, texCoord).r;

	float dither = Bayer64(gl_FragCoord.xy);
	
	vec4 screenPos = vec4(texCoord, z, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	if (z < 1.0){
		#ifdef AO
		float ao = AmbientOcclusion(depthtex0, dither);
		float ambientOcclusion = pow(ao, AO_STRENGTH);
		#endif
	
		#if defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR
		float smoothness = 0.0, metalness = 0.0, f0 = 0.0, materialFormat = 0.0;
		vec3 normal = vec3(0.0), rawAlbedo = vec3(0.0);

		GetMaterials(materialFormat, smoothness, metalness, f0, normal, rawAlbedo, texCoord);
		smoothness *= smoothness;
		
		float fresnel = pow(clamp(1.0 + dot(normal, normalize(viewPos.xyz)), 0.0, 1.0), 5.0);
		vec3 fresnel3 = vec3(0.0);
		
		if (materialFormat > 0.9) {
			fresnel3 = mix(mix(vec3(0.02), rawAlbedo*5, metalness), vec3(1.0), fresnel);
			if (metalness <= 0.004 && metalness > 0.0) fresnel3 = BlackFresnel(fresnel, f0);
			fresnel3 *= 0.1*smoothness;
		} else {
			#if MATERIAL_FORMAT == -1
			fresnel3 = mix(mix(vec3(0.02), rawAlbedo*5, metalness), vec3(1.0), fresnel);
			fresnel3 *= 0.1*smoothness;
			#endif
			#if MATERIAL_FORMAT == 0
			fresnel3 = mix(mix(vec3(f0), rawAlbedo*5, metalness), vec3(1.0), fresnel);
			if (f0 >= 0.9 && f0 < 1.0) {
				fresnel3 = ComplexFresnel(fresnel, f0);
				color.rgb *= pow(fresnel3, vec3(0.5));
			}
			fresnel3 *= 0.2*smoothness*(metalness*0.5+0.5);
			#endif
		}

		if (length(fresnel3) > 0.0001){
			vec4 reflection = vec4(0.0);
			
			reflection = RoughReflection(viewPos.xyz, normal, dither, smoothness, colortex0);

			reflection.rgb = max(mix(vec3(0.0), reflection.rgb, reflection.a), vec3(0.0));
			
			#ifdef AO
			reflection.rgb *= pow(ao, 13);
			#endif
			
			color.rgb = color.rgb * (1.0 - fresnel3 * (1.0 - metalness)) +
						reflection.rgb * fresnel3;
		}
		#endif

		#ifdef AO
		color.rgb *= ambientOcclusion;
		#endif
		
		#ifdef PROMO_OUTLINE
		PromoOutline(color.rgb, depthtex0);
		#endif
        
		vec3 theFog = startFog(color.rgb, viewPos.xyz);
		color.rgb = theFog;

	}else{
		#ifdef NETHER
		color.rgb = pow((netherCol * 2.5) / NETHER_I, vec3(2.2)) * 4;
		#endif
		
		#ifdef TWENTY
		color.rgb *= 0.1;
		#endif
		
		#ifdef SEVEN
		
		float NdotU = max(dot(normalize(viewPos.xyz), upVec), 0.0);

		color.rgb = 2 * (vec3(0.005, 0.006, 0.018) * 2 * clamp(pow(NdotU, 0.7), 0.0, 1.0) + vec3(0.015, 0.03, 0.02) * (1-clamp(pow(NdotU, 0.7), 0.0, 1.0)));
		
		#if defined STARS
		vec3 stars = DrawStars(color.rgb, viewPos.xyz, NdotU);
		color.rgb += stars.rgb;
		#endif
		
		#endif
		
		#ifdef TEN
		color.rgb = vec3(0.0, 0.0, 0.0);
		#endif
		
		#ifdef TWO
		color.rgb = vec3(0.0003, 0.0004, 0.002);
		#endif
		
		#ifdef END
		color.rgb+= endCol * 0.025;
		#endif

		if (isEyeInWater == 2){
			color.rgb = vec3(1.0, 0.25, 0.01);
		}

		if (blindFactor > 0.0) color.rgb *= 1.0 - blindFactor;
	}
    
	#ifdef BLACK_OUTLINE
	float wFogMult = 1.0 + eBS;
	BlackOutline(color.rgb, depthtex0, wFogMult);
	#endif
	
	/*DRAWBUFFERS:05*/
    gl_FragData[0] = color;
	gl_FragData[1] = vec4(pow(color.rgb, vec3(0.125)) * 0.5, float(z < 1.0));
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying vec2 texCoord;

varying vec3 sunVec, upVec;

//Uniforms//
uniform float timeAngle;

uniform mat4 gbufferModelView;

//Program//
void main(){
	texCoord = gl_MultiTexCoord0.xy;
	
	gl_Position = ftransform();

	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
}

#endif
