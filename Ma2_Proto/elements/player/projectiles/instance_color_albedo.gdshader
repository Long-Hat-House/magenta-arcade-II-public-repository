// NOTE: Shader automatically converted from Godot Engine 4.4.1.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_disabled, shadows_disabled, ambient_light_disabled, fog_disabled, vertex_lighting;


instance uniform vec4 color : source_color;
instance uniform vec4 emissive : source_color;
instance uniform float energy : hint_range(0.0, 100.0, 0.01) = 0.5;

void vertex() {
	// Shading Mode: Per Vertex
	ROUGHNESS = 1.0;
	UV = UV;
}

void fragment() {
	ALBEDO = color.rgb;
	METALLIC = 0.1;
	SPECULAR = 0.5;
	EMISSION = emissive.rgb * energy;
}
