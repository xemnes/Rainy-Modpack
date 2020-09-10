#ifdef OVERWORLD

vec3 SunGlare(vec3 color, vec3 viewPos, vec3 lightCol){
	float cosS = dot(normalize(viewPos), lightVec);
	float visfactor = 0.05 * (1.0 - 0.9 * timeBrightness) * (3.0 * rainStrength + 1.0);
	float invvisfactor = 1.0 - visfactor;

	float visibility = clamp(cosS * 0.5 + 0.5, 0.0, 1.0);
    visibility = visfactor / (1.0 - invvisfactor * visibility) - visfactor;
	visibility = clamp(visibility * 1.015 / invvisfactor - 0.015, 0.0, 1.0);
	visibility = mix(1.0, visibility, 0.25 * eBS + 0.75) * (1.0 - rainStrength * eBS * 0.875);

	#ifdef SUN_GLARE
	color += 0.225 * lightCol * visibility * shadowFade * (1 - rainStrength) * timeBrightness;
	#else
	if (isEyeInWater == 1) color += 0.225 * lightCol * visibility * shadowFade * (1 - rainStrength);
	#endif
	
	return color;
}

vec3 GetSkyFogColor(vec3 viewPos){
    vec3 sky = skyCol;
    vec3 nViewPos = normalize(viewPos);

    float NdotU = max(dot(nViewPos, upVec), 0.0);
    float invNdotU = clamp(dot(nViewPos, -upVec) * 1.015 - 0.015, 0.0, 1.0);
    float NdotS = clamp(dot(nViewPos, sunVec) * 0.5 + 0.5, 0.0, 1.0);

    float horizonExponent = 3.0 * ((1.0 - NdotS) * sunVisibility * (1.0 - rainStrength) *
                            (1.0 - 0.5 * timeBrightness)) + HORIZON_DISTANCE;
    float horizon = pow(1.0 - NdotU, horizonExponent);
    horizon *= (0.5 * sunVisibility + 0.3) * (1 - rainStrength * 0.75);
    
    float lightmix = NdotS * NdotS * (1.0 - NdotU) * pow(1.0 - timeBrightness, 3.0) +
                     horizon * 0.075 * timeBrightness;
    lightmix *= sunVisibility * (1.0 - rainStrength);

    float mult = (0.1 * (1.0 + rainStrength) + horizon);

    sky = mix(sky * pow(max(1.0 - lightmix, 0.0), 2.0 * sunVisibility), lightCol * sqrt(lightCol),
              lightmix) * sunVisibility + (lightNight * lightNight * 0.4) + (1 - sunVisibility) *lightNight*lightNight*lightNight*2;
    
    vec3 weatherSky = weatherCol * weatherCol;
    weatherSky *= GetLuminance(ambientCol / (weatherSky)) * 1.4;
    sky = mix(sky, weatherSky, rainStrength) * mult;
    
	#ifdef SUN_GLARE
    sky = SunGlare(sky, viewPos.xyz, lightCol);
	#endif
	
    return pow(sky, vec3(1.125));
}

#endif

vec3 Fog1(vec3 color, vec3 viewPos, vec3 skyFogColor){
    #ifdef OVERWORLD
	#ifndef ONESEVEN
    float fog = length(viewPos) / far * 1.5 * (10/FOG1_DISTANCE);
    fog = 1.0 - exp(-0.1 * pow(fog, 10));
    vec3 artificialFogColor = skyFogColor;
	if (eyeAltitude < 2.0) artificialFogColor.rgb *= clamp((eyeAltitude-1.0), 0.0, 1.0);
	color.rgb = mix(color.rgb, artificialFogColor, fog);
    #endif
	#endif

    #ifdef NETHER
    float fog = length(viewPos) / far * 1.5;
    fog = 1.0 - exp(-6.0 * pow(fog, 5));
	vec3 artificialFogColor = pow((netherCol * 2.5) / NETHER_I, vec3(2.2)) * 4;
	color.rgb = mix(color.rgb, artificialFogColor, fog);
    #endif

    #ifdef END
    float fog = length(viewPos) / far * 1.5 * (10/FOG1_DISTANCE);
    fog = 1.0 - exp(-0.1 * pow(fog, 10));
    vec3 artificialFogColor = endCol * 0.0525 * pow(2.5 / END_I, 1.3);
	color.rgb = mix(color.rgb, artificialFogColor, fog);
    #endif

    #ifdef TWO
    float fog = length(viewPos) / far * 1.8 * (10/FOG1_DISTANCE);
    fog = 1.0 - exp(-0.1 * pow(fog, 10));
    vec3 artificialFogColor = vec3(0.0003, 0.0004, 0.002);
	color.rgb = mix(color.rgb, artificialFogColor, fog);
    #endif
	
    #ifdef SEVEN
    float fog = length(viewPos) / far * 1.5 * (10/FOG1_DISTANCE);
    fog = 1.0 - exp(-0.1 * pow(fog, 10));
	float cosT = dot(normalize(viewPos.xyz), upVec);
    vec3 artificialFogColor = 2 * (vec3(0.005, 0.006, 0.018) * 2 * clamp(pow(cosT, 0.7), 0.0, 1.0) + vec3(0.015, 0.03, 0.02) * (1-clamp(pow(cosT, 0.7), 0.0, 1.0)));
	color.rgb = mix(color.rgb, artificialFogColor, fog);
    #endif
	
    #ifdef TEN
    float fog = length(viewPos) / far * 1.5 * (10/FOG1_DISTANCE);
    fog = 1.0 - exp(-0.1 * pow(fog, 10));
    vec3 artificialFogColor = vec3(0.0, 0.0, 0.0);
	color.rgb = mix(color.rgb, artificialFogColor, fog);
    #endif
	
    #ifdef ONESEVEN
    float fogoneseven = length(viewPos) / 16 * (1.35-sunVisibility*0.35);
    fogoneseven = 1.0 - exp(-0.1 * pow(fogoneseven, 3));
    vec3 fogColoroneseven = skyFogColor;
	color.rgb = mix(color.rgb, fogColoroneseven, fogoneseven);
    #endif
	
	return vec3(color.rgb);
}

vec3 Fog2(vec3 color, vec3 viewPos, vec3 skyFogColor){
    #ifdef OVERWORLD
    float fog2 = length(viewPos) / far * 1.5 * (10/FOG2_DISTANCE);
	fog2 = 1.0 - (exp(-50.0 * pow(fog2*0.125, 3) * eBS));
	fog2 *= 5 - (1-rainStrength)*4.5;
	fog2 = clamp(fog2, 0.0, 1.0);
    vec3 fogColor2 = skyFogColor;
	if (eyeAltitude < 2.0) fogColor2.rgb *= clamp((eyeAltitude-1.0), 0.0, 1.0);
	color.rgb = mix(color.rgb, fogColor2, fog2);
    #endif

    #ifdef NETHER
    float fog2 = 0.0;
    vec3 fogColor2 = vec3(0.0);
	color.rgb = mix(color.rgb, fogColor2, fog2);
    #endif

    #ifdef END
    float fog2 = length(viewPos) / far * 1.5 * (10/FOG2_DISTANCE);
	fog2 = 1.0 - (exp(-50.0 * pow(fog2*0.125, 3)));
    vec3 fogColor2 = endCol * 0.25;
	color.rgb = mix(color.rgb, fogColor2, fog2);
    #endif

    #ifdef TWO
    float fog2two = 0.0;
    vec3 fogColor2two = vec3(0.0);
	color.rgb = mix(color.rgb, fogColor2two, fog2two);
    #endif
	
    #ifdef SEVEN
    float fog2 = length(viewPos) / far * 1.5 * (10/FOG2_DISTANCE);
	fog2 = 1.0 - (exp(-50.0 * pow(fog2*0.125, 3)));
    vec3 fogColor2 = 2 * vec3(0.005, 0.006, 0.018);
	color.rgb = mix(color.rgb, fogColor2, fog2);
    #endif
	
    #ifdef TEN
    float fog2 = length(viewPos) / far * 3 * (10/FOG2_DISTANCE);
	fog2 = 1.0 - (exp(-50.0 * pow(fog2*0.125, 3)));
    vec3 fogColor2 = vec3(0.0, 0.0, 0.0);
	color.rgb = mix(color.rgb, fogColor2, fog2);
    #endif
	
    #ifdef ONESEVEN
    float fog2oneseven = 0.0;
    vec3 fogColor2oneseven = vec3(0.0);
	color.rgb = mix(color.rgb, fogColor2oneseven, fog2oneseven);
    #endif
	
	return vec3(color.rgb);
}

vec3 BlindFog(vec3 color, vec3 viewPos){
	float fog = length(viewPos) *0.04* (5.0 / blindFactor);
	fog = (1.0 - exp(-6.0 * fog * fog * fog)) * blindFactor;
	color.rgb = mix(color.rgb, vec3(0.0), fog);
	
	return vec3(color.rgb);
}

vec3 LavaFog(inout vec3 color, vec3 viewPos){
	float fog = length(viewPos) * 0.3;
	fog = (1.0 - exp(-4.0 * fog * fog * fog));
	color.rgb = mix(color.rgb, vec3(1.0, 0.25, 0.01), fog);
	
	return vec3(color.rgb);
}

vec3 startFog(vec3 color, vec3 viewPos){
	vec3 skyFogColor = vec3(0.0);
	#if (defined FOG1 || defined FOG2) && (defined OVERWORLD || defined ONESEVEN)
	skyFogColor = GetSkyFogColor(viewPos.xyz);
	#endif
	#ifdef FOG2
	if (isEyeInWater == 0) color.rgb = Fog2(color.rgb, viewPos, skyFogColor);
	#endif
	#ifdef FOG1
	if (isEyeInWater == 0) color.rgb = Fog1(color.rgb, viewPos, skyFogColor);
	#endif
	if (isEyeInWater == 2) color.rgb = LavaFog(color, viewPos);
	if (blindFactor > 0.0) color.rgb = BlindFog(color, viewPos);
	
	return vec3(color.rgb);
}