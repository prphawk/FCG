#version 330 core

// Atributos de vértice recebidos como entrada ("in") pelo Vertex Shader.
// Veja a função BuildTrianglesAndAddToVirtualScene() em "main.cpp".
layout (location = 0) in vec4 model_coefficients;
layout (location = 1) in vec4 normal_coefficients;
layout (location = 2) in vec2 texture_coefficients;

// Matrizes computadas no código C++ e enviadas para a GPU
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

// Atributos de vértice que serão gerados como saída ("out") pelo Vertex Shader.
// ** Estes serão interpolados pelo rasterizador! ** gerando, assim, valores
// para cada fragmento, os quais serão recebidos como entrada pelo Fragment
// Shader. Veja o arquivo "shader_fragment.glsl".
out vec4 position_world;
out vec4 position_model;
out vec4 normal;
out vec2 texcoords;
out vec3 gouraud_phong_color;
out vec3 gouraud_bling_phong_color;

vec3 phong_illumination(vec3 Kd, vec3 Ka, vec3 Ks, vec3 I, vec4 n, vec4 l, vec4 v);
vec3 bling_phong_illumination(vec3 Kd, vec3 Ka, vec3 Ks, vec3 I, vec4 n, vec4 l, vec4 v);

vec3 phong_illumination(vec3 Kd, vec3 Ka, vec3 Ks, vec3 I, vec4 n, vec4 l, vec4 v) {

    float q = 32.0;
    // Vetor que define o sentido da reflexão especular ideal.
    vec4 r = -l + 2 * n * dot(n,l);
    // Termo difuso utilizando a lei dos cossenos de Lambert
    vec3 lambert_diffuse_term = Kd * I * max(0, dot(n, l));
    // Termo ambiente
    vec3 ambient_term = Ka * vec3(0.2,0.2,0.2);
    // Termo especular utilizando o modelo de iluminação de Phong
    vec3 phong_specular_term  = Ks * I * pow(max(0, dot(r, v)), q);

    return lambert_diffuse_term + ambient_term + phong_specular_term;
}

vec3 bling_phong_illumination(vec3 Kd, vec3 Ka, vec3 Ks, vec3 I, vec4 n, vec4 l, vec4 v) {

    float q_linha = 80.0;

    vec4 h = (v + l)/length(v + l);
    // Vetor que define o sentido da reflexão especular ideal.
    vec4 r = -l + 2 * n * dot(n,l);
    // Termo difuso utilizando a lei dos cossenos de Lambert
    vec3 lambert_diffuse_term = Kd * I * max(0, dot(n, l));
    // Termo ambiente
    vec3 ambient_term = Ka * vec3(0.2,0.2,0.2);
    // Termo especular utilizando o modelo de iluminação de Phong
    vec3 bling_phong_specular_term  = Ks * I * pow(dot(n, h), q_linha);

    return lambert_diffuse_term + ambient_term + bling_phong_specular_term;
}

void main()
{

    gl_Position = projection * view * model * model_coefficients;

    position_world = model * model_coefficients;

    position_model = model_coefficients;

    normal = inverse(transpose(model)) * normal_coefficients;
    normal.w = 0.0;

    // Coordenadas de textura obtidas do arquivo OBJ (se existirem!)
    texcoords = texture_coefficients;

    vec4 origin = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 camera_position = inverse(view) * origin;

    vec4 n = normalize(normal);
    vec4 p = position_world;
    vec4 l = normalize(vec4(1.0,1.0,0.5,0.0));
    vec4 v = normalize(camera_position - p);
    vec3 Kd = vec3(0.08, 0.4, 0.8);
    vec3 Ks = vec3(0.8, 0.8, 0.8);
    vec3 Ka = Kd / 2;
    vec3 I = vec3(1.0,1.0,1.0);

    gouraud_phong_color = phong_illumination(Kd, Ka, Ks, I, n, l, v);
    gouraud_bling_phong_color = phong_illumination(Kd, Ka, Ks, I, n, l, v);

}

