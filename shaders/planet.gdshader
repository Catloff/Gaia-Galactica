shader_type spatial;

// Farben für die verschiedenen Biome
uniform vec4 water : source_color = vec4(0.1, 0.3, 0.5, 1.0);
uniform vec4 grass : source_color = vec4(0.2, 0.5, 0.2, 1.0);
uniform vec4 hill : source_color = vec4(0.3, 0.4, 0.2, 1.0);
uniform vec4 mountain : source_color = vec4(0.4, 0.3, 0.2, 1.0);

// Höhengrenzen für die Biome
uniform float water_level : hint_range(0.0, 1.0) = 0.25;
uniform float hill_level : hint_range(0.0, 1.0) = 0.5;
uniform float mountain_level : hint_range(0.0, 1.0) = 0.75;

// Noise Textur für zusätzliche Details
uniform sampler2D noise_texture;

varying vec3 world_normal;

void vertex() {
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
    float height = UV.x;
    vec4 final_color;
    
    // Diskrete Höhenstufen für klare Biome
    if (height < water_level) {
        final_color = water;
    }
    else if (height < hill_level) {
        final_color = grass;
    }
    else if (height < mountain_level) {
        final_color = hill;
    }
    else {
        final_color = mountain;
    }
    
    // Einfache Beleuchtung für Low-Poly-Look
    vec3 light_dir = normalize(vec3(2.0, 3.0, 1.0));
    float ndotl = max(dot(world_normal, light_dir), 0.0);
    float light = mix(0.4, 1.0, ndotl);  // Erhöhtes minimales Umgebungslicht für bessere Sichtbarkeit
    
    // Füge subtile Noise-Details hinzu
    vec2 noise_uv = vec2(
        atan(VERTEX.x, VERTEX.z) / (3.14159 * 2.0) + 0.5,
        acos(VERTEX.y / length(VERTEX)) / 3.14159
    );
    float noise_val = texture(noise_texture, noise_uv * 2.0).r * 0.05;  // Reduzierte Noise-Intensität
    
    ALBEDO = final_color.rgb * light + noise_val;
    ROUGHNESS = 0.9;
    METALLIC = 0.0;
    SPECULAR = 0.1;
}