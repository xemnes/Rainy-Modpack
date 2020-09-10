vec4 rawWaterColorSqrt = vec4(WATER_R, WATER_G, WATER_B, 255.0) * 0.45 / 255.0;
vec4 rawWaterColor = rawWaterColorSqrt * rawWaterColorSqrt;
vec4 waterColorSqrt = vec4(WATER_R, WATER_G, WATER_B, 255.0) * WATER_I / 255.0;
vec4 waterColor = waterColorSqrt * waterColorSqrt;

const float waterFog = WATER_F;

#ifndef COMPATIBILITY_MODE
const float waterAlpha = WATER_A;
#else
const float waterAlpha = min(WATER_A*1.1, 1.0);
#endif