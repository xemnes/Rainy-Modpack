/* 
BSL Shaders v7.1.05 by Capt Tatsu, Complementary Shaders by EminGT
*/ 

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Extensions//

//Varyings//
varying float mat, quarterNdotUfactor, eminMat;
varying float mipMapDisabling;

varying vec2 texCoord, lmCoord;

varying vec3 normal;
varying vec3 sunVec, upVec;

varying vec4 color;

#ifdef ADVANCED_MATERIALS
varying float dist;

varying vec3 binormal, tangent;
varying vec3 viewVector;

varying vec4 vTexCoord, vTexCoordAM;
#endif

//Uniforms//
uniform int blockEntityId;
uniform int frameCounter;
uniform int isEyeInWater;
uniform int worldTime;

uniform float frameTimeCounter;
uniform float nightVision;
uniform float rainStrength;
uniform float screenBrightness; 
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform sampler2D texture;
uniform vec3 cameraPosition;

#ifdef WATER_CAUSTICS
#ifdef OVERWORLD
uniform sampler2D noisetex;
#endif
#endif

#ifdef ADVANCED_MATERIALS
uniform sampler2D specular;
uniform sampler2D normals;

#ifdef REFLECTION_ROUGH
uniform sampler2D depthtex0;
#endif

#ifdef REFLECTION_RAIN
uniform float wetness;

uniform mat4 gbufferModelView;
#endif
#endif

#ifdef NETHER
uniform vec3 fogColor;
#endif

//Common Variables//
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility  = clamp(dot( sunVec,upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp(dot(-sunVec,upVec) + 0.05, 0.0, 0.1) * 10.0;

#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

#ifdef ADVANCED_MATERIALS
vec2 dcdx = dFdx(texCoord.xy);
vec2 dcdy = dFdy(texCoord.xy);
#endif

vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

//Common Functions//
float GetLuminance(vec3 color){
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float InterleavedGradientNoise(){
	float n = 52.9829189 * fract(0.06711056 * gl_FragCoord.x + 0.00583715 * gl_FragCoord.y);
	return fract(n + frameCounter / 8.0);
}

//Includes//
#include "/lib/color/blocklightColor.glsl"
#include "/lib/color/dimensionColor.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/lighting/forwardLighting.glsl"

#ifdef WATER_CAUSTICS
#ifdef OVERWORLD
#include "/lib/color/waterColor.glsl"
#include "/lib/lighting/caustics.glsl"
#endif
#endif

#if AA == 2 || AA == 3
#include "/lib/util/jitter.glsl"
#endif
#if AA == 4
#include "/lib/util/jitter2.glsl"
#endif

#ifdef ADVANCED_MATERIALS
#include "/lib/util/encode.glsl"
#include "/lib/surface/directionalLightmap.glsl"
#include "/lib/surface/ggx.glsl"
#include "/lib/surface/materialGbuffers.glsl"
#include "/lib/surface/parallax.glsl"

#ifdef REFLECTION_RAIN
#include "/lib/reflections/rainPuddles.glsl"
#endif
#endif

//Program//
void main(){
	vec4 albedo = vec4(0.0);
	if (mipMapDisabling < 0.5) albedo = texture2D(texture, texCoord) * vec4(color.rgb, 1.0);
	if (mipMapDisabling > 0.5) albedo = texture2DLod(texture, texCoord, 0.0) * vec4(color.rgb, 1.0);
	
	vec3 normalMapItself = vec3(0.0);
	vec3 materialFormatFlag = vec3(1.0);
	
	#ifdef GREY
	albedo.rgb = vec3((albedo.r + albedo.g + albedo.b) / 2);
	#endif
	
	vec3 newNormal = normal;
	vec3 newRough = normal;
	
	float skymapMod = 0.0;

	#ifdef ADVANCED_MATERIALS
	vec2 newCoord = vTexCoord.st * vTexCoordAM.pq + vTexCoordAM.st;
	float parallaxFade = clamp((dist - PARALLAX_DISTANCE) / 32.0, 0.0, 1.0);
	float skipParallax = float(blockEntityId == 63);

	#ifdef PARALLAX
	newCoord = GetParallaxCoord(parallaxFade);
	albedo = texture2DGradARB(texture, newCoord, dcdx, dcdy) * vec4(color.rgb, 1.0);
	#endif

	float smoothness = 0.0, metalData = 0.0;
	vec3 rawAlbedo = vec3(0.0);
	#endif
	
	#ifndef COMPATIBILITY_MODE
	float albedocheck = albedo.a;
	#else
	float albedocheck = 1.0;
	#endif

	if (albedocheck > 0.00001){
		vec2 lightmap = clamp(lmCoord, vec2(0.0), vec2(1.0));
		
		float foliage  = float(mat > 0.98 && mat < 1.02);
		float emissive = float(mat > 1.98 && mat < 2.02) * 0.25;
		float lava     = float(mat > 2.98 && mat < 3.02);
		
		#if SHADOW_SUBSURFACE == 0
		foliage = 0.0;
		#endif

		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
		#if AA > 1
		vec3 viewPos = ToNDC(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
		#else
		vec3 viewPos = ToNDC(screenPos);
		#endif
		vec3 worldPos = ToWorld(viewPos);

		#ifdef ADVANCED_MATERIALS
		float metalness = 0.0, f0 = 0.0, ao = 1.0; 
		vec3 roughMap = vec3(0.0);
		vec3 normalMap = vec3(0.0);
		float materialFormat = 0.0;
		GetMaterials(materialFormat, normalMapItself, smoothness, metalness, f0, metalData, emissive, ao, normalMap, roughMap,
					 newCoord, dcdx, dcdy);
		if (materialFormat < 0.5) {
			float beacon      = float(eminMat > 0.98 && eminMat < 1.02);
			float other       = float(eminMat > 1.98 && eminMat < 2.02);
			float seaLantern = float(eminMat > 2.98 && eminMat < 3.02);
			float magma       = float(eminMat > 3.98 && eminMat < 4.02);
			
			if (beacon      > 0.1) lightmap.x = min(lightmap.x, 0.90), albedo.rgb *= 0.7;
			if (other       > 0.1) lightmap.x = min(lightmap.x, 0.90);
			if (seaLantern > 0.1) lightmap.x = min(lightmap.x, 0.92), albedo.b *= 0.9708737864, albedo.a *= 1.21212121212;
			if (magma       > 0.1) lightmap.x = 0.90;
			
			materialFormatFlag = vec3(0.0);
		}
		
		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							  tangent.y, binormal.y, normal.y,
							  tangent.z, binormal.z, normal.z);

		if (normalMap.x > -0.999 && normalMap.y > -0.999)
			newNormal = clamp(normalize(normalMap * tbnMatrix), vec3(-1.0), vec3(1.0));
		if (roughMap.x > -0.999 && roughMap.y > -0.999)
			newRough = clamp(normalize(roughMap * tbnMatrix), vec3(-1.0), vec3(1.0));
		#endif

    	albedo.rgb = pow(albedo.rgb, vec3(2.2));

		#ifdef WHITE_WORLD
		albedo.rgb = vec3(0.5);
		#endif

		float NdotL = clamp(dot(newNormal, lightVec) * 1.01 - 0.01, 0.0, 1.0);

		float quarterNdotU = clamp(0.25 * dot(newNormal*quarterNdotUfactor, upVec) + 0.75, 0.5, 1.0);
			  quarterNdotU*= quarterNdotU * (foliage > 0.5 ? 1.0+lmCoord.y*0.8 : 1.0);

		float parallaxShadow = 1.0;
		#ifdef ADVANCED_MATERIALS
		rawAlbedo = albedo.rgb * 0.999 + 0.001;
		albedo.rgb *= ao;

		albedo.rgb *= (1.0 - metalness*0.65);

		float doParallax = 0.0;
		#ifdef SELF_SHADOW
		#ifdef OVERWORLD
		doParallax = float(lightmap.y > 0.0 && NdotL > 0.0);
		#endif
		#ifdef END
		doParallax = float(NdotL > 0.0);
		#endif
		
		if (doParallax > 0.5){
			parallaxShadow = GetParallaxShadow(parallaxFade, newCoord, lightVec, tbnMatrix);
		}
		#endif

		#ifdef DIRECTIONAL_LIGHTMAP
		mat3 lightmapTBN = GetLightmapTBN(viewPos);
		lightmap.x = DirectionalLightmap(lightmap.x, lmCoord.x, newNormal, lightmapTBN);
		lightmap.y = DirectionalLightmap(lightmap.y, lmCoord.y, newNormal, lightmapTBN);
		#endif
		#endif
		
		vec3 shadow = vec3(0.0);
		GetLighting(albedo.rgb, shadow, viewPos, worldPos, lightmap, color.a, NdotL, quarterNdotU,
					parallaxShadow, emissive + lava, foliage, mat);

		#ifdef ADVANCED_MATERIALS
		float puddles = 0.0;
		#if defined REFLECTION_RAIN && defined OVERWORLD
		float NdotU = clamp(dot(newNormal, upVec),0.0,1.0);

		#if REFLECTION_RAIN_TYPE == 0
		puddles = GetPuddles(worldPos) * NdotU * wetness;
		#else
		puddles = NdotU * wetness;
		#endif
		
		#ifdef WEATHER_PERBIOME
		float weatherweight = isCold + isDesert + isMesa + isSavanna;
		puddles *= 1.0 - weatherweight;
		#endif
		
		puddles *= clamp(lightmap.y * 32.0 - 31.0, 0.0, 1.0);
		
		smoothness = mix(smoothness, 1.0, puddles);
		f0 = max(f0, puddles * 0.02);

		albedo.rgb *= 1.0 - (puddles * 0.15);

		if (puddles > 0.001 && rainStrength > 0.001){
			mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							  tangent.y, binormal.y, normal.y,
							  tangent.z, binormal.z, normal.z);

			vec3 puddleNormal = GetPuddleNormal(worldPos, viewPos, tbnMatrix);
			newNormal = normalize(mix(newNormal, puddleNormal, puddles * rainStrength));
		}
		#endif

		#if defined OVERWORLD || defined END
		#ifdef OVERWORLD
		vec3 lightME = mix(lightMorning, lightEvening, mefade);
		vec3 lightDayTint = lightDay * lightME * LIGHT_DI;
		vec3 lightDaySpec = mix(lightME, sqrt(lightDayTint), timeBrightness);
		vec3 specularColor = mix(sqrt(lightNight*0.3),
									lightDaySpec,
									sunVisibility);
		specularColor *= specularColor;
		#endif
		#ifdef END
		vec3 specularColor = endCol;
		#endif
		
		#if defined SUNLIGHT_LEAK_FIX && !defined END
		albedo.rgb += lightmap.y * GetSpecularHighlight(smoothness, metalness, f0, specularColor, rawAlbedo,
							 			   shadow, newNormal, viewPos, materialFormat);
		#else
		albedo.rgb += GetSpecularHighlight(smoothness, metalness, f0, specularColor, rawAlbedo,
							 			   shadow, newNormal, viewPos, materialFormat);
		#endif
		#endif
		
		#if defined REFLECTION_SPECULAR && defined REFLECTION_ROUGH
		if (normalMap.x > -0.999 && normalMap.y > -0.999){
			normalMap = mix(vec3(0.0, 0.0, 1.0), normalMap, smoothness);
			newNormal = mix(normalMap * tbnMatrix, newRough, 1.0 - pow(1.0 - puddles, 4.0));
			newNormal = clamp(normalize(newRough), vec3(-1.0), vec3(1.0));
		}
		#endif
		#endif
		
		#if defined WATER_CAUSTICS && defined OVERWORLD
		if (isEyeInWater == 1){
		skymapMod = lightmap.y * lightmap.y * (3.0 - 2.0 * lightmap.y);
		albedo.rgb = GetCaustics(albedo.rgb, worldPos.xyz, cameraPosition.xyz, shadow, skymapMod, lightmap.x);
		}
		#endif
		
		#ifdef SHOW_LIGHT_LEVELS
		float showLightLevelFactor = fract(frameTimeCounter);
		if (showLightLevelFactor > 0.5) showLightLevelFactor = 1 - showLightLevelFactor;
		if (lmCoord.x < 0.533334 && quarterNdotU > 0.99) albedo.rgb += vec3(0.5, 0.0, 0.0) * showLightLevelFactor;
		#endif
	} else discard;

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = albedo;

	#if defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR
	/* DRAWBUFFERS:03567 */
	gl_FragData[1] = vec4(smoothness, metalData, skymapMod, 1.0);
    gl_FragData[2] = vec4(materialFormatFlag, 1.0);
	gl_FragData[3] = vec4(EncodeNormal(newNormal), float(gl_FragCoord.z < 1.0), 1.0);
	gl_FragData[4] = vec4(rawAlbedo, 1.0);
	#endif
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying float mat, quarterNdotUfactor, eminMat;
varying float mipMapDisabling;

varying vec2 texCoord, lmCoord;

varying vec3 normal;
varying vec3 sunVec, upVec;

varying vec4 color;

#ifdef ADVANCED_MATERIALS
varying float materialFormat;

varying float dist;

varying vec3 binormal, tangent;
varying vec3 viewVector;

varying vec4 vTexCoord, vTexCoordAM;
#endif

//Uniforms//
uniform int worldTime;

uniform float frameTimeCounter;
uniform float timeAngle;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelView, gbufferModelViewInverse;

#if AA > 1
uniform int frameCounter;

uniform float viewWidth, viewHeight;
#endif

//Attributes//
attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

#ifdef ADVANCED_MATERIALS
attribute vec4 at_tangent;
#endif

//Common Variables//
#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

//Includes//
#include "/lib/vertex/waving.glsl"

#if AA == 2 || AA == 3
#include "/lib/util/jitter.glsl"
#endif
#if AA == 4
#include "/lib/util/jitter2.glsl"
#endif

#ifdef WORLD_CURVATURE
#include "/lib/vertex/worldCurvature.glsl"
#endif

//Program//
void main(){
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, 0.0, 1.0);

	normal = normalize(gl_NormalMatrix * gl_Normal);

	#ifdef ADVANCED_MATERIALS
	binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
	
	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
						  tangent.y, binormal.y, normal.y,
						  tangent.z, binormal.z, normal.z);
								  
	viewVector = tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;
	
	dist = length(gl_ModelViewMatrix * gl_Vertex);

	vec2 midCoord = (gl_TextureMatrix[0] *  mc_midTexCoord).st;
	vec2 texMinMidCoord = texCoord - midCoord;

	vTexCoordAM.pq  = abs(texMinMidCoord) * 2;
	vTexCoordAM.st  = min(texCoord, midCoord - texMinMidCoord);
	
	vTexCoord.xy    = sign(texMinMidCoord) * 0.5 + 0.5;
	#endif
    
	color = gl_Color;
	
	float compatibilityFactor = 0.0;
	
	#ifndef COMPATIBILITY_MODE
	color.a = pow(color.a, 0.75);
	#else
	compatibilityFactor = 1.0;
	#endif
	
	mat = 0.0; quarterNdotUfactor = 1.0; mipMapDisabling = 0.0; eminMat = 0.0;

	if (mc_Entity.x ==  31 || mc_Entity.x ==   6 || mc_Entity.x ==  59 || mc_Entity.x == 175 ||
	    mc_Entity.x == 176 || mc_Entity.x ==  83 || mc_Entity.x == 104 || mc_Entity.x == 105)
		mat = 1.0, lmCoord.x = clamp(lmCoord.x, 0.0, 0.87);
	if (mc_Entity.x == 18 || mc_Entity.x == 106 || mc_Entity.x == 111)
	#if SHADOW_SUBSURFACE == 2
		mat = 1.0, color.a -= 0.15*lmCoord.y;
	#else
		color.a += 0.15*lmCoord.y;
	#endif
	if (mc_Entity.x ==  10)
		mat = 3.0, color.a *= 0.75 - compatibilityFactor*0.3;
	if (mc_Entity.x ==  210)
		mat = 3.0, color.a *= 0.25;
		
	#ifndef COMPATIBILITY_MODE
    #if defined ADVANCED_MATERIALS
	if (mc_Entity.x ==  55 ||
	    mc_Entity.x ==  91 || mc_Entity.x ==  917 || mc_Entity.x == 911 || mc_Entity.x == 901 || mc_Entity.x ==  92 || mc_Entity.x == 191)
		mat = 2.0;
	if (mc_Entity.x ==  91 || mc_Entity.x == 901 || mc_Entity.x == 911 || mc_Entity.x ==  10 || mc_Entity.x == 191)
		lmCoord.x = 1.0;
	if (mc_Entity.x == 92)
		lmCoord.x = 1.0, color.b = 1.03, color.a = 0.825, eminMat = 3.0;
	if (mc_Entity.x ==  917)
		lmCoord.x = 0.0, eminMat = 4.0;
	if (mc_Entity.x == 911)
	    lmCoord.x = 0.97;
	if (mc_Entity.x == 866)
		color.a *= (1 - pow(lmCoord.x, 6)*0.5);
	if (mc_Entity.x == 871)
	    lmCoord.x = 0.8;
	if (mc_Entity.x == 872)
	    lmCoord.x = 0.82;
	if (mc_Entity.x == 873)
	    lmCoord.x = 0.84;
	if (mc_Entity.x == 874)
	    lmCoord.x = 0.87;
	if (mc_Entity.x == 901)
	    lmCoord.x = 0.925, color.a *= 1.5;
	if (mc_Entity.x == 902)
	    lmCoord.x = min(lmCoord.x, 0.9);
	if (mc_Entity.x ==  93)
	    lmCoord.x = 0.87;
	if (mc_Entity.x == 138)
		lmCoord *= 0.55, color.a = 5.0, eminMat = 1.0;
	if (mc_Entity.x == 912 || mc_Entity.x == 911 || mc_Entity.x == 95 || mc_Entity.x == 76 || mc_Entity.x == 75 || mc_Entity.x == 901 || mc_Entity.x == 902 || mc_Entity.x == 191 || mc_Entity.x == 91)
		eminMat = 2.0;
	if (mc_Entity.x == 139)
		lmCoord.x *= 0.8, color.a *= 10.0;
	if (mc_Entity.x ==  94)
	    lmCoord.x *= 0.9;
	if (mc_Entity.x ==  95 || mc_Entity.x ==  99 || mc_Entity.x == 919)
	    lmCoord.x = clamp(lmCoord.x, 0.0, 0.87);
	if (mc_Entity.x ==  96)
	    lmCoord.x = clamp(lmCoord.x, 0.0, 0.95);
	if (mc_Entity.x ==  97)
	    lmCoord.x *= 0.8, color.a *= 2.0;
	if (mc_Entity.x ==  98)
	    lmCoord.x *= 0.9, color.a *= 2.0;
	if (mc_Entity.x ==  62)
		lmCoord.x -= 0.0667;
	if (mc_Entity.x ==  91 || mc_Entity.x == 901 || mc_Entity.x ==  92 || mc_Entity.x ==  97 || mc_Entity.x == 191 || mc_Entity.x ==  917)
		quarterNdotUfactor = 0.0, color.a *= pow(SHADING_STRENGTH, 0.22);
	#ifdef BROKEN_MIPMAP_FIX
	if (mc_Entity.x == 917 || mc_Entity.x == 880 || mc_Entity.x == 76 || mc_Entity.x == 77 || mc_Entity.x == 919 || mc_Entity.x ==  98 || mc_Entity.x ==  96 || mc_Entity.x ==  95 || mc_Entity.x ==  93 || mc_Entity.x ==  901 || mc_Entity.x ==  902 || mc_Entity.x ==  91 || mc_Entity.x ==  92)
		mipMapDisabling = 1.0;
	#endif
	#endif
	
	if (mc_Entity.x == 300)
		color.a = 1;
		
	#endif
	
	#ifdef COMPATIBILITY_MODE
	vec2 lightmap = clamp(lmCoord, vec2(0.0), vec2(1.0));
	if (lightmap.x > 0.5) lightmap.x = smoothstep(0.0, 1.0, lightmap.x);
    float newLightmap  = pow(lightmap.x, 10.0);
		quarterNdotUfactor = 1 - newLightmap, color.a *= pow((SHADING_STRENGTH+2)*0.5, newLightmap);
	#endif
	
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);

	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	
	float istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;
	position.xyz += WavingBlocks(position.xyz, istopv);

    #ifdef WORLD_CURVATURE
	position.y -= WorldCurvature(position.xz);
    #endif

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	
	#if AA > 1
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif
}

#endif