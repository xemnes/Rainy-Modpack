vec3 GetSkyColor(vec3 viewPos, vec3 lightCol){
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

    #ifdef SKY_VANILLA
    sky = mix(fogCol, sky, NdotU);
    #endif
	
	float ground = 1.0;
	#ifdef GBUFFERS_WATER
    float groundFactor = 0.5 * (11.0 * rainStrength + 1.0) *(-5.0 * sunVisibility + 6.0);
    ground -= exp(-groundFactor / (invNdotU * 12));
	#endif
    float mult = (0.1 * (1.0 + rainStrength) + horizon) * ground;

    sky = mix(sky * pow(max(1.0 - lightmix, 0.0), 2.0 * sunVisibility), lightCol * sqrt(lightCol),
              lightmix) * sunVisibility + (lightNight * lightNight * 0.4) + (1 - sunVisibility) *lightNight*lightNight*lightNight*2;
    
    vec3 weatherSky = weatherCol * weatherCol;
    weatherSky *= GetLuminance(ambientCol / (weatherSky)) * 1.4;
    sky = mix(sky, weatherSky, rainStrength) * mult;

    return pow(sky, vec3(1.125));
}