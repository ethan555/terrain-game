shader_type canvas_item;

uniform vec4 color1 : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 color2 : source_color = vec4(1.0);
uniform vec4 colorScan : source_color = vec4(1.0, 1.0, 1.0, 0.8);

uniform float scanWidth = 10.0;

uniform vec3[11] destinations;

vec4 getScanColor(vec2 position, vec4 baseColor) {
    vec4 resultColor = baseColor;
    for (int i = 0; i < 11; ++i) {
        vec3 destination = destinations[i];
        if (destination.z <= 0.0) continue;

        float dist = distance(destination.xy, position);
        if (dist > destination.z || dist < destination.z - scanWidth) continue;

        float diff = destination.z - dist;
        float ratio = max(0.0, sin(diff)) / diff; //clamp(dist / destination.z, 0.0, 1.0);
        // ratio = max(ratio, destination.w);
        resultColor = mix(baseColor, colorScan, ratio);
    }
    return resultColor;
}

varying vec2 position;

void vertex() {
    position = VERTEX.xy;
}

void fragment() {
    float heightRatio = COLOR.r; // r = b = g
    vec4 heightColor = mix(color1, color2, COLOR.r);

    // vec2 position = UV * TEXTURE_PIXEL_SIZE;

    // set pathfinding scan ring
    vec4 scanColor = getScanColor(position, heightColor);

    COLOR = scanColor; // mix(COLOR, heightColor, COLOR.r);
}
