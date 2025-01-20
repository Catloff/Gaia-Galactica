shader_type spatial;

// Farben für die verschiedenen Biome
uniform vec4 water : source_color = vec4(0.1, 0.3, 0.5, 1.0);
uniform vec4 shore : source_color = vec4(0.2, 0.4, 0.2, 1.0);
uniform vec4 grass : source_color = vec4(0.2, 0.5, 0.2, 1.0);
uniform vec4 mountain : source_color = vec4(0.4, 0.3, 0.2, 1.0);
uniform vec4 snow : source_color = vec4(0.9, 0.9, 0.9, 1.0);

// Höhengrenzen für die Biome
uniform float water_level : hint_range(0.0, 1.0) = 0.3;
uniform float shore_blend : hint_range(0.0, 0.1) = 0.03;
uniform float mountain_start : hint_range(0.0, 1.0) = 0.5;
uniform float snow_start : hint_range(0.0, 1.0) = 0.7;

// Noise Textur für zusätzliche Details
uniform sampler2D noise_texture;

varying vec3 world_normal;

void vertex() {
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
    float height = UV.x;
    vec4 final_color;
    
    // Harte Farbübergänge für Low-Poly-Look
    if (height < water_level) {
        final_color = water;
    }
    else if (height < water_level + shore_blend) {
        final_color = shore;
    }
    else if (height < mountain_start) {
        final_color = grass;
    }
    else if (height < snow_start) {
        final_color = mountain;
    }
    else {
        final_color = snow;
    }
    
    // Einfache Beleuchtung für Low-Poly-Look
    vec3 light_dir = normalize(vec3(2.0, 3.0, 1.0));
    float ndotl = max(dot(world_normal, light_dir), 0.0);
    float light = mix(0.3, 1.0, ndotl);  // 0.3 ist das minimale Umgebungslicht
    
    // Füge Noise-Details hinzu
    vec2 noise_uv = vec2(
        atan(VERTEX.x, VERTEX.z) / (3.14159 * 2.0) + 0.5,
        acos(VERTEX.y / length(VERTEX)) / 3.14159
    );
    float noise_val = texture(noise_texture, noise_uv * 4.0).r * 0.1;
    
    ALBEDO = final_color.rgb * light + noise_val;
    ROUGHNESS = 0.9;
    METALLIC = 0.0;
    SPECULAR = 0.1;
}