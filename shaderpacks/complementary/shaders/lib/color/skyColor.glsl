#ifndef ONESEVEN
vec3 skyCol = pow(skyColor, vec3(2.2)) * SKY_I * SKY_I;
vec3 fogCol = pow(fogColor, vec3(2.2)) * SKY_I * SKY_I;
#else
vec3 skyCol = vec3(0.812, 0.741, 0.674)*0.5;
vec3 fogCol = vec3(0.812, 0.741, 0.674)*0.5;
#endif