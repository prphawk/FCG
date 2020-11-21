#version 330 core

// Atributos de fragmentos recebidos como entrada ("in") pelo Fragment Shader.
// Neste exemplo, este atributo foi gerado pelo rasterizador como a
// interpolação da posição global e a normal de cada vértice, definidas em
// "shader_vertex.glsl" e "main.cpp".
in vec4 position_world;
in vec4 normal;

// Posição do vértice atual no sistema de coordenadas local do modelo.
in vec4 position_model;

// Coordenadas de textura obtidas do arquivo OBJ (se existirem!)
in vec2 texcoords;

in vec3 gouraud_phong_color;
in vec3 gouraud_bling_phong_color;

// Matrizes computadas no código C++ e enviadas para a GPU
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

// Identificador que define qual objeto está sendo desenhado no momento
#define SPHERE 0
#define BUNNY  1
#define PLANE  2
#define DINO   3
#define PENGUIN  4
#define ALLIGATOR 5
#define DEER 6
#define CLOUD 7
#define CAT 8
#define CUBE 9
#define COIN 10
#define PEDESTAL 11

uniform int object_id;

// Parâmetros da axis-aligned bounding box (AABB) do modelo
uniform vec4 bbox_min;
uniform vec4 bbox_max;

// Variáveis para acesso das imagens de textura
uniform sampler2D TextureImage0; //floor
uniform sampler2D TextureImage1; //dino
uniform sampler2D TextureImage2; //penguin
uniform sampler2D TextureImage3; //coin


// O valor de saída ("out") de um Fragment Shader é a cor final do fragmento.
out vec3 color;

// Constantes
#define M_PI   3.14159265358979323846
#define M_PI_2 1.57079632679489661923

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

vec3 lambert_difuse_illumination(vec3 Kd, vec3 Ka, vec4 n, vec4 l) {

    vec3 I = vec3(1.0,1.0,1.0);

    vec3 lambert_diffuse_term = Kd * I * max(0, dot(n, l));

    vec3 ambient_term = Ka * vec3(0.2,0.2,0.2);

    return lambert_diffuse_term + ambient_term;
}

void main()
{
    // Obtemos a posição da câmera utilizando a inversa da matriz que define o
    // sistema de coordenadas da câmera.
    vec4 origin = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 camera_position = inverse(view) * origin;

    vec4 p = position_world;
    vec4 n = normalize(normal);
    // Vetor que define o sentido da fonte de luz em relação ao ponto atual.
    vec4 l = normalize(vec4(1.0,1.0,0.5,0.0));
    // Vetor que define o sentido da câmera em relação ao ponto atual.
    vec4 v = normalize(camera_position - p);

    vec3 I = vec3(1.0,1.0,1.0);

    // Parâmetros que definem as propriedades espectrais da superfície
    vec3 Kd = vec3(0.5, 0.5, 0.8); // Refletância difusa (da superfície)
    vec3 Ks = vec3(0.8, 0.8, 0.8); // Refletância especular (da superfície)
    vec3 Ka = Kd / 2; // Refletância ambiente (da superfície)

    // Coordenadas de textura U e V
    float U = 0.0;
    float V = 0.0;
    vec3 Kd0;

    switch(object_id)
    {
        case SPHERE :
            vec4 bbox_center = (bbox_min + bbox_max) / 2.0;
            vec4 p_vetor_aux = position_model - bbox_center;
            vec4 p_linha = bbox_center + (p_vetor_aux/length(p_vetor_aux));
            vec4 p_vetor = p_linha - bbox_center;
            float theta = atan(p_vetor.x, p_vetor.z);
            float phi = asin(p_vetor.y);
            U = (theta + M_PI)/(2*M_PI);
            V = (phi + M_PI_2)/M_PI;
            Kd0 = texture(TextureImage0, vec2(U,V)).rgb;
            color = Kd0 * bling_phong_illumination(Kd, Ka, Ks, I, n, l, v);
            break;
        case BUNNY :
            float minx = bbox_min.x;
            float maxx = bbox_max.x;
            float miny = bbox_min.y;
            float maxy = bbox_max.y;
            float minz = bbox_min.z;
            float maxz = bbox_max.z;
            U = (position_model.x - minx)/(maxx - minx);
            V = (position_model.y - miny)/(maxy - miny);
            Kd0 = texture(TextureImage1, vec2(U,V)).rgb;
            color = Kd0 * bling_phong_illumination(Kd, Ka, Ks, I, n, l, v);
            break;
        case DINO:
            U = texcoords.x;
            V = texcoords.y;
            Kd0 = texture(TextureImage1, vec2(U,V)).rgb;
            color = Kd0 * bling_phong_illumination(Kd, Ka, Ks, I, n, l, v);
            break;
        case PLANE:
            U = texcoords.x*100;
            V = texcoords.y;
            Kd0 = texture(TextureImage0, vec2(U,V)).rgb;
            color = Kd0 * bling_phong_illumination(Kd, Ka, Ks, I, n, l, v);
            break;
        case PENGUIN:
            U = texcoords.x;
            V = texcoords.y;
            Kd0 = texture(TextureImage2, vec2(U,V)).rgb;
            color = Kd0 * bling_phong_illumination(Kd, Ka, Ks, I, n, l, v);
            break;
        case DEER:
            color = gouraud_bling_phong_color;
            break;
        case COIN:
            U = texcoords.x;
            V = texcoords.y;
            Kd0 = texture(TextureImage3, vec2(U,V)).rgb;
            Ks = vec3(1.0, 1.0, 1.0);
            color = Kd0 * bling_phong_illumination(Kd, Ka, Ks, I, n, l, v);
            break;
        case CUBE:
            U = texcoords.x;
            V = texcoords.y;
            Kd0 = texture(TextureImage1, vec2(U,V)).rgb;
            Ks = vec3(1.0, 1.0, 1.0);
            color = Kd0 * bling_phong_illumination(Kd, Ka, Ks, I, n, l, v);
            break;
    }

    color = pow(color, vec3(1.0,1.0,1.0)/2.2);
}






