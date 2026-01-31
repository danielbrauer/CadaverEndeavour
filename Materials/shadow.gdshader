shader_type canvas_item;

uniform vec2 shadow_offset = vec2(4.0, 4.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);

void fragment() {
    vec4 modulate = COLOR; // capture incoming modulation
    
    vec4 shadow = texture(TEXTURE, UV - shadow_offset * TEXTURE_PIXEL_SIZE);
    shadow.rgb = shadow_color.rgb;
    shadow.a *= shadow_color.a;
    
    vec4 original = texture(TEXTURE, UV);
    COLOR = mix(shadow, original, original.a) * modulate;
}