#if defined GBUFFERS_TERRAIN || defined GBUFFERS_BLOCK || defined GBUFFERS_HAND || defined GBUFFERS_ENTITIES

void GetMaterials(out float materialFormat, out vec3 normalMapItself, out float smoothness, out float metalness, out float f0, out float metalData, 
                  inout float emissive, out float ao, out vec3 normalMap, out vec3 roughMap,
                  vec2 newCoord, vec2 dcdx, vec2 dcdy){
    vec4 specularMap = texture2DLod(specular, newCoord, 0.0);
	vec3 normalMapItselfForUsing = texture2DGradARB(normals, newCoord, dcdx, dcdy).xyz;
	
	#ifndef FORCE_EMINPBR
	normalMapItself = normalMapItselfForUsing;
	#else
	normalMapItself = vec3(1.0);
	#endif
	

	if (normalMapItself == vec3(1.0)) {
		materialFormat = 1.0;
	
		smoothness = specularMap.r;
		
		metalness = specularMap.g;
		f0 = 0.78 * metalness + 0.02;
		metalData = metalness;

		emissive = mix(specularMap.b, 1.0, emissive);
		ao = 1.0;

		ao = specularMap.a < 1.0 ? specularMap.a : 1.0;
		ao = ao > 0.000001 ? (ao < 1.0 ? pow(ao, 8) : 1.0) : 1.0;
		
		#ifndef FORCE_EMINPBR
		
		#if defined REFLECTION_ROUGH
		float metalFactor = 1.0;
		if (specularMap.g == 1.0) metalFactor = 2.0;
		normalMap = vec3(0.5, 0.5, 1.0) * 2.0 - 1.0;
		roughMap = texture2D(depthtex0, newCoord*2048 / (metalFactor*metalFactor*metalFactor)).xyz;
		roughMap = roughMap + vec3(0.5, 0.5, 0.0);
		float factoredSmoothness = min(smoothness*pow(metalFactor, 0.5), 1.0);
		roughMap = pow(roughMap, vec3(0.25)*pow((1-factoredSmoothness), 2));
		roughMap = roughMap - vec3(0.5, 0.5, 0.0);
		roughMap = roughMap * 2.0 - 1.0;
		#else
		normalMap = vec3(0.5, 0.5, 1.0) * 2.0 - 1.0;
		roughMap = normalMap;
		#endif
		
		#else
		
		#if defined REFLECTION_ROUGH
		normalMap = normalMapItselfForUsing;
		roughMap = texture2D(depthtex0, newCoord*2048).xyz;
		roughMap = roughMap + vec3(0.5, 0.5, 0.0);
		roughMap = pow(roughMap, vec3(0.125)*pow((1-smoothness), 2));
		roughMap = roughMap - vec3(0.5, 0.5, 0.0);
		roughMap = roughMap * (normalMap + vec3(0.5, 0.5, 0.0));
		normalMap = normalMap * 2.0 - 1.0;
		roughMap = roughMap * 2.0 - 1.0;
		#else
		normalMap = normalMapItselfForUsing * 2.0 - 1.0;
		roughMap = normalMap;
		#endif
		
		#endif
	} else {
		materialFormat = 0.0;
		
		#if MATERIAL_FORMAT == -1
		smoothness = specularMap.r;
		
		metalness = specularMap.g;
		f0 = 0.78 * metalness + 0.02;
		metalData = metalness;

		emissive = specularMap.b;
		ao = 1.0;

		#if defined REFLECTION_ROUGH
		normalMap = normalMapItselfForUsing;
		roughMap = texture2D(depthtex0, newCoord*2048).xyz;
		roughMap = roughMap + vec3(0.5, 0.5, 0.0);
		roughMap = pow(roughMap, vec3(0.125)*pow((1-smoothness), 2));
		roughMap = roughMap - vec3(0.5, 0.5, 0.0);
		roughMap = roughMap * (normalMap + vec3(0.5, 0.5, 0.0));
		normalMap = normalMap * 2.0 - 1.0;
		roughMap = roughMap * 2.0 - 1.0;
		#else
		normalMap = normalMapItselfForUsing * 2.0 - 1.0;
		roughMap = normalMap;
		#endif
		#endif

		#if MATERIAL_FORMAT > -1
		smoothness = specularMap.r;

		f0 = specularMap.g;
		metalness = f0 >= 0.9 ? 1.0 : 0.0;
		metalData = f0;
		
		ao = texture2DGradARB(normals, newCoord, dcdx, dcdy).z;
		ao = pow(ao, 2);
		float aoLightFactor = min(lmCoord.x + lmCoord.y, 1.0);
		ao = pow(ao, pow(1-aoLightFactor, 2));

		emissive = specularMap.a < 1.0 ? specularMap.a : 0.0, 1.0;
		
		#if defined REFLECTION_ROUGH
		normalMap = normalMapItselfForUsing;
		roughMap = texture2D(depthtex0, newCoord*2048).xyz;
		roughMap = roughMap + vec3(0.5, 0.5, 0.0);
		roughMap = pow(roughMap, vec3(0.125)*pow((1-smoothness), 2));
		roughMap = roughMap - vec3(0.5, 0.5, 0.0);
		roughMap = roughMap * (normalMap + vec3(0.5, 0.5, 0.0));
		normalMap = normalMap * 2.0 - 1.0;
		float normalCheck = normalMap.x + normalMap.y;
		if (normalCheck > -1.999){
			if (length(normalMap.xy) > 1.0) normalMap.xy = normalize(normalMap.xy);
			normalMap.z = sqrt(1.0 - dot(normalMap.xy, normalMap.xy));
			normalMap = normalize(clamp(normalMap, vec3(-1.0), vec3(1.0)));
		}else{
			normalMap = vec3(0.0, 0.0, 1.0);
			ao = 1.0;
		}
		roughMap = roughMap * 2.0 - 1.0;
		#else
		normalMap = normalMapItselfForUsing * 2.0 - 1.0;
		float normalCheck = normalMap.x + normalMap.y;
		if (normalCheck > -1.999){
			if (length(normalMap.xy) > 1.0) normalMap.xy = normalize(normalMap.xy);
			normalMap.z = sqrt(1.0 - dot(normalMap.xy, normalMap.xy));
			normalMap = normalize(clamp(normalMap, vec3(-1.0), vec3(1.0)));
		}else{
			normalMap = vec3(0.0, 0.0, 1.0);
			ao = 1.0;
		}
		roughMap = normalMap;
		#endif
		#endif
	}	
	#if defined ADVANCED_MATERIALS && defined COMPATIBILITY_MODE
	emissive *= 0.25;
	#endif
	
	emissive *= EMISSIVE_MULTIPLIER;

	#if defined TEMPORARY_FIX
	#if MC_VERSION >= 11500
	#if defined GBUFFERS_BLOCK || defined GBUFFERS_HAND || defined GBUFFERS_ENTITIES
	#undef PARALLAX
	#undef SELF_SHADOW
	normalMap = vec3(0.5, 0.5, 1.0) * 2.0 - 1.0;
	roughMap = normalMap;
	#endif
	#endif
	#endif
}

#else

void GetMaterials(out float smoothness, out float metalness, out float f0, out float metalData, 
                  inout float emissive, out float ao, out vec3 normalMap,
                  vec2 newCoord, vec2 dcdx, vec2 dcdy){
    vec4 specularMap = texture2DGradARB(specular, newCoord, dcdx, dcdy);

    #if MATERIAL_FORMAT == -1
    smoothness = specularMap.r;
    
    metalness = specularMap.g;
    f0 = 0.78 * metalness + 0.02;
    metalData = metalness;

    emissive = mix(specularMap.b, 1.0, emissive);
    ao = 1.0;

	normalMap = texture2DGradARB(normals, newCoord, dcdx, dcdy).xyz * 2.0 - 1.0;
    #endif

    #if MATERIAL_FORMAT == 0
    smoothness = specularMap.r;

    f0 = specularMap.g;
    metalness = f0 >= 0.9 ? 1.0 : 0.0;
    metalData = f0;
    
    ao = texture2DGradARB(normals, newCoord, dcdx, dcdy).z;
	float aoLightFactor = min(lmCoord.x + lmCoord.y, 1.0);
	ao = pow(ao, pow(1-aoLightFactor, 2));

    emissive = mix(specularMap.a < 1.0 ? specularMap.a : 0.0, 1.0, emissive);

	normalMap = texture2DGradARB(normals, newCoord, dcdx, dcdy).xyz * 2.0 - 1.0;
    #endif
	
	#if defined ADVANCED_MATERIALS && defined COMPATIBILITY_MODE
	emissive *= 0.25;
	#endif
	
	emissive *= EMISSIVE_MULTIPLIER;
}

#endif