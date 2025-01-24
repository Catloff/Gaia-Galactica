/**
* Ported from the original unity shader by Erik Roystan Ross
* https://roystan.net/articles/toon-water.html
* https://github.com/IronWarrior/ToonWaterShader
* Camera Depth taken from Bastiaan Olij's video on: https://www.youtube.com/watch?v=Jq3he9Lbj7M
*/

shader_type spatial;

const float SMOOTHSTEP_AA = 0.01;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

uniform float beer_factor = 0.8;
uniform float foam_distance = 0.01;
uniform float foam_max_distance = 0.4;
uniform float foam_min_distance = 0.04;
uniform vec4 foam_color: source_color = vec4(1.0);
uniform vec2 surface_noise_tiling = vec2(1.0, 4.0);
uniform vec3 surface_noise_scroll = vec3(0.03, 0.03, 0.0);
uniform float surface_noise_cutoff: hint_range(0, 1) = 0.777;
uniform float surface_distortion_amount: hint_range(0, 1) = 0.27;
uniform vec4 _DepthGradientShallow: source_color = vec4(0.325, 0.807, 0.971, 0.725);
uniform vec4 _DepthGradientDeep: source_color = vec4(0.086, 0.407, 1, 0.949);
uniform float _DepthMaxDistance: hint_range(0, 1) = 1.0;
uniform float _DepthFactor = 3;
uniform float water_speed: hint_range(0.1, 2.0) = 0.2;

varying vec2 noiseUV;
varying vec2 distortUV;
varying vec3 viewNormal;

// Verbesserte Hash-Funktion für zufällige Werte
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// 2D Perlin Noise
float perlin2D(vec2 P) {
    vec2 Pi = floor(P);
    vec2 Pf = fract(P);
    
    float n00 = hash(Pi);
    float n01 = hash(Pi + vec2(0.0, 1.0));
    float n10 = hash(Pi + vec2(1.0, 0.0));
    float n11 = hash(Pi + vec2(1.0, 1.0));
    
    vec2 u = Pf * Pf * (3.0 - 2.0 * Pf);
    return mix(mix(n00, n01, u.y), mix(n10, n11, u.y), u.x);
}

// FBM (Fractional Brownian Motion) für natürlichere Noise
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 3.0;
    
    for(int i = 0; i < 4; i++) {
        value += amplitude * perlin2D(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

// Distortion Noise
vec2 getDistortNoise(vec2 uv) {
    float time = TIME * water_speed;
    vec2 noise1 = vec2(
        fbm(uv * 1.5 + time * 0.05),
        fbm(uv * 1.5 + time * 0.05 + 3.14)
    );
    
    vec2 noise2 = vec2(
        fbm(uv * 2.0 + noise1 * 2.0 + time * 0.1),
        fbm(uv * 2.0 + noise1 * 2.0 + time * 0.1 + 3.14)
    );
    
    return noise2 * 2.0 - 1.0;
}

// Surface Noise
float getSurfaceNoise(vec2 uv) {
    return fbm(uv * 3.0 + TIME * water_speed * 0.1);
}

vec4 alphaBlend(vec4 top, vec4 bottom) {
    vec3 color = (top.rgb * top.a) + (bottom.rgb * (1.0 - top.a));
    float alpha = top.a + bottom.a * (1.0 - top.a);
    return vec4(color, alpha);
}

void vertex() {
    viewNormal = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
    noiseUV = UV * surface_noise_tiling;
    distortUV = UV;
}

void fragment() {
    float depthVal = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    float depth = PROJECTION_MATRIX[3][2] / (depthVal + PROJECTION_MATRIX[2][2]);
    depth = depth + VERTEX.z;
    depth = exp(-depth * beer_factor);
    depth = 1.0 - depth;
    
    vec4 view_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depthVal, 1.0);
    view_pos /= view_pos.w;
    vec3 existingNormal = normalize(cross(dFdx(view_pos.xyz), dFdy(view_pos.xyz)));
    
    float normalDot = clamp(dot(existingNormal.xyz, viewNormal), 0.0, 1.0);
    float foamDistance = mix(foam_max_distance, foam_min_distance, normalDot);
    float foamDepth = clamp(depth / foamDistance, 0.0, 1.0);
    float surfaceNoiseCutoff = foamDepth * surface_noise_cutoff;
    
    vec2 distortAmount = getDistortNoise(distortUV) * surface_distortion_amount;
    vec2 noise_uv = noiseUV + distortAmount + TIME * surface_noise_scroll.xy * water_speed;
    float surfaceNoiseSample = getSurfaceNoise(noise_uv);
    float surfaceNoiseAmount = smoothstep(surfaceNoiseCutoff - SMOOTHSTEP_AA, surfaceNoiseCutoff + SMOOTHSTEP_AA, surfaceNoiseSample);
    
    float waterDepth = clamp(depth / _DepthMaxDistance, 0.0, 1.0) * _DepthFactor;
    vec4 waterColor = mix(_DepthGradientShallow, _DepthGradientDeep, waterDepth);
    
    vec4 surfaceNoiseColor = foam_color;
    surfaceNoiseColor.a *= surfaceNoiseAmount;
    vec4 color = alphaBlend(surfaceNoiseColor, waterColor);
    
    ALBEDO = color.rgb;
    ALPHA = color.a;
}