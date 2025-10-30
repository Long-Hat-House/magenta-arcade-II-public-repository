shader_type canvas_item;

uniform float vignette_intensity = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;
uniform vec4 vignette_rgb : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// Vignette strength function
float vignette(vec2 uv) {
    uv *= 1.0 - uv;
    float vig = uv.x * uv.y * 15.0;
    return pow(vig, vignette_intensity);
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV); // If you need a texture, otherwise remove
    float vig = vignette(UV);

    float factor = (1.0 - vig) * vignette_opacity;
    vec3 final_color = mix(vec3(0.0), vignette_rgb.rgb, factor);

    COLOR = vec4(final_color, vignette_rgb.a * factor);
}
