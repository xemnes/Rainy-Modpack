float CloudNoise(vec2 coord, vec2 wind){
	float noise = texture2D(noisetex, coord*0.5      + wind * 0.45).x * 1.0;
		  noise+= texture2D(noisetex, coord*0.25     + wind * 0.35).x * 2.0;
		  noise+= texture2D(noisetex, coord*0.125    + wind * 0.25).x * 4.0;
		  noise+= texture2D(noisetex, coord*0.0625   + wind * 0.15).x * 8.0;
		  noise+= texture2D(noisetex, coord*0.03125  + wind * 0.05).x * 16.0;
		  noise+= texture2D(noisetex, coord*0.015625 + wind * 0.05).x * 24.0;
	return noise*0.33;
}

float CloudCoverage(float noise, float coverage, float NdotU){
	float noiseMix = mix(noise, 21.0, 0.33 * rainStrength);
	float noiseFade = clamp(sqrt(NdotU * 10.0), 0.0, 1.0);
	float noiseCoverage = ((coverage) + CLOUD_AMOUNT * (1 + NdotU*0.5) - 2);
	float multiplier = 1.0 - 0.5 * rainStrength;

	return max(noiseMix * noiseFade - noiseCoverage, 0.0) * multiplier;
}

float GetNoise(vec2 pos){
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.54953);
}

vec4 DrawCloud(vec3 viewPos, float dither, vec3 lightCol, vec3 ambientCol, float NdotU){
	float cosS = dot(normalize(viewPos), sunVec);
	
	#if AA > 1
	dither = fract(16.0 * frameTimeCounter + dither);
	#endif
	
	float stretchFactor = 01.8 + 1 * (1 - NdotU);
	
	float cloud = 0.0;
	float cloudGradient = 0.0;
	float gradientMix = dither * 0.1667;
	float colorMultiplier = CLOUD_BRIGHTNESS * (0.5 - 0.25 * (1.0 - sunVisibility) * (1.0 - rainStrength));
	float noiseMultiplier = CLOUD_THICKNESS * 0.25;
	float scattering = pow(cosS * 0.5 * (2.0 * sunVisibility - 1.0) + 0.5, 6.0);

	vec2 wind = vec2(frametime * CLOUD_SPEED * 0.001,
				     sin(frametime * CLOUD_SPEED * 0.05) * 0.002) * CLOUD_HEIGHT / 15.0;
	#ifdef SEVEN
	wind *= 8;
	#endif

	vec3 cloudcolor = vec3(0.0);

	if (NdotU > 0.1){
		vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz);
		for(int i = 0; i < 6; i++) {
			if (cloud > 0.99) break;
			vec3 planeCoord = wpos * ((CLOUD_HEIGHT + (i + dither) * stretchFactor) / wpos.y) * 0.004;
			vec2 coord = cameraPosition.xz * 0.00025 + planeCoord.xz;
			float coverage = float(i - 3.0 + dither) * 0.667;

			float noise = CloudNoise(coord, wind);
				  noise = CloudCoverage(noise, coverage, NdotU) * noiseMultiplier;
				  noise = noise / pow(pow(noise, 2.5) + 1.0, 0.4);

			cloudGradient = mix(cloudGradient,
			                    mix(gradientMix * gradientMix, 1.0 - noise, 0.25),
								noise * (1.0 - cloud * cloud * cloud));
			cloud = mix(cloud, 1.0, noise);
			gradientMix += 0.2;
		}
		cloudcolor = mix(ambientCol * (0.5 * sunVisibility + 0.5),
		                 lightCol * (1.0 + scattering),
						 cloudGradient * cloud);
		cloud *= 1.0 - 0.4 * rainStrength;
		cloudcolor.r *= (1.0 + sunVisibility*0.2);
		cloudcolor += lightNight*lightNight*lightNight*lightNight*2;
		cloud *= sqrt(sqrt(clamp(NdotU * 10.0 - 1.0, 0.0, 1.0))) * (1.0 - 0.6 * rainStrength);
	}

	return vec4(cloudcolor * colorMultiplier, pow(cloud, 2) * CLOUD_OPACITY);
}

vec3 DrawStars(inout vec3 color, vec3 viewPos, float NdotU){
	vec3 wpos = vec3(gbufferModelViewInverse * vec4(viewPos, 1.0));
	vec3 planeCoord = 0.75 * wpos / (wpos.y + length(wpos.xz));
	vec2 wind = 0.75 * vec2(frametime, 0.0);
	#ifdef SEVEN
	wind = vec2(0.0);
	#endif
	vec2 coord = planeCoord.xz * 0.4 + wind * 0.00125;
	coord = floor(coord*1024.0)/1024.0;
	
	float multiplier = 5.0 * (1.0 - rainStrength) * max((1-timeBrightness*50), 0.0) * pow(NdotU, 1.5);
	
	#ifdef SEVEN
	multiplier = sqrt(sqrt(NdotU)) * 5.0 * (1.0 - rainStrength);	
	#endif
	
	float star = 1.0;
	if (NdotU > 0.0){
		star *= GetNoise(coord.xy);
		star *= GetNoise(coord.xy+0.01);
        star *= GetNoise(coord.xy+0.12);
	}
	star = max(star - 0.825, 0.0) * multiplier;
	
	#ifdef COMPATIBILITY_MODE
	vec3 stars = star * pow(lightNight*100, vec3(0.8));
	#else
	vec3 stars = star * pow(lightNight*200, vec3(0.8));
	#endif
	return vec3(stars);
}

float CloudCoverageEnd(float noise, float cosT, float coverage){
	float noiseMix = mix(noise, 21.0, 0.33 * rainStrength);
	float noiseFade = clamp(sqrt(cosT * 10.0), 0.0, 1.0);
	float noiseCoverage = ((coverage) + CLOUD_AMOUNT - 2);
	float multiplier = 1.0 - 0.5 * rainStrength;

	return max(noiseMix * noiseFade - noiseCoverage, 0.0) * multiplier;
}

float CloudNoiseEnd(vec2 coord, vec2 wind){
	float noise = texture2D(noisetex, coord*1        + wind * 0.55).x;
		  noise+= texture2D(noisetex, coord*0.5      + wind * 0.45).x * -2.0;
		  noise+= texture2D(noisetex, coord*0.25     + wind * 0.35).x * -2.0;
		  noise+= texture2D(noisetex, coord*0.125    + wind * 0.25).x * -5.0;
		  noise+= texture2D(noisetex, coord*0.0625   + wind * 0.15).x * 20.0;
		  noise+= texture2D(noisetex, coord*0.03125  + wind * 0.05).x * 20.0;
		  noise+= texture2D(noisetex, coord*0.015625 + wind * 0.05).x * -20.0;
	return noise;
}

vec4 DrawEndCloud(vec3 viewPos, float dither, vec3 lightCol){
	float cosT = dot(normalize(viewPos), upVec);
	float cosS = dot(normalize(viewPos), sunVec);

	#if AA > 1
	dither = fract(16.0 * frameTimeCounter + dither);
	#endif
	
	float cloud = 0.0;
	float cloudGradient = 0.0;
	float gradientMix = dither * 0.5;
	float colorMultiplier = CLOUD_BRIGHTNESS * (0.5 - 0.25 * (1.0 - sunVisibility) * (1.0 - rainStrength));
	float noiseMultiplier = 0.25;
	float scattering = pow(cosS * 0.5 + 0.5, 6.0);

	vec2 wind = vec2(frametime * CLOUD_SPEED * 0.005,
				     sin(frametime * CLOUD_SPEED * 0.05) * 0.002) * CLOUD_HEIGHT / 15.0;

	vec3 cloudcolor = vec3(0.0);

	if (cosT > 0.1){
		vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz);
		for(int i = 0; i < 6; i++) {
			if (cloud > 0.99) break;
			vec3 planeCoord = wpos * ((CLOUD_HEIGHT + (i + dither)) / wpos.y) * 0.004 * pow(cosT, -0.5);
			vec2 coord = cameraPosition.xz * 0.00025 + planeCoord.xz;
			float coverage = float(i - 3.0 + dither) * 0.667;

			float noise = CloudNoiseEnd(coord, wind);
				  noise = CloudCoverageEnd(noise, cosT, coverage*1.5) * noiseMultiplier;
				  noise = noise / pow(pow(noise, 2.5) + 1.0, 0.4);

			cloudGradient = mix(cloudGradient,
			                    mix(gradientMix * gradientMix, 1.0 - noise, 0.25),
								noise * (1.0 - cloud * cloud));
			cloud = mix(cloud, 1.0, noise);
			gradientMix += 0.6;
		}
		cloudcolor = lightCol * vec3(6.4, 6.8, 5.0) * (1.0 + scattering) * pow(cloudGradient, 0.75);
		cloudcolor = pow(cloudcolor, vec3(2)) * 2 * vec3(1.4, 1.8, 1.0);
		cloud *= min(pow(cosT*2, 2.0), 0.42);
	}

	return vec4(cloudcolor * colorMultiplier * (0.6+(sunVisibility)*0.4), pow(cloud, 2) * 0.1 * CLOUD_OPACITY * (2-(sunVisibility)));
}