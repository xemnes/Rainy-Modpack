#if MC_VERSION <= 11600
vec3 netherNether = vec3(NETHER_R, NETHER_G, NETHER_B) * 0.25 * NETHER_I / 255.0;
vec3 netherFungiForest = vec3(105.0, 99.0, 89.0) * 0.25 * NETHER_I / 255.0;
vec3 netherHeap = vec3(119.0, 31.0, 11.0) * 0.25 * 4.0 / 255.0;
vec3 netherUndergarden = vec3(78.0, 106.0, 30.0) * 0.25 * NETHER_I / 255.0;
vec3 netherInferno = vec3(42.0, 78.0, 95.0) * 0.25 * NETHER_I / 255.0;
vec3 netherCorruptedSands = vec3(95.0, 51.0, 108.0) * 0.25 * NETHER_I / 255.0;

uniform float isFungiForest, isHeap, isUndergarden, isInferno, isCorruptedSands;
float nBiomeWeight = isFungiForest + isHeap + isUndergarden + isInferno + isCorruptedSands;

vec3 netherColSqrt = mix(
    netherNether,
    (
        netherFungiForest  * isFungiForest  + netherHeap * isHeap +
        netherUndergarden  * isUndergarden  + netherInferno  * isInferno +
		netherCorruptedSands  * isCorruptedSands
    ) / max(nBiomeWeight, 0.0001),
    nBiomeWeight
);
vec3 netherCol = netherColSqrt * netherColSqrt;
#else
vec3 netherCol = fogColor * (1 - length(fogColor / 3.0)) * 0.25 * NETHER_I;
#endif