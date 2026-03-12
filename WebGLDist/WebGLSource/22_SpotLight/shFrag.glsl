#version 300 es

precision highp float;

out vec4 FragColor;

struct Material {
    sampler2D diffuse; // diffuse map
    vec3 specular;     // 표면의 specular color
    float shininess;   // specular 반짝임 정도
};

struct Light {
    vec3 position;

    vec3 ambient; // ambient 적용 strength
    vec3 diffuse; // diffuse 적용 strength
    vec3 specular; // specular 적용 strength

    vec3 direction; // spotLight의 target 방향 vector (spotDir)
    float cutOff; // inner cut-off angle
    float outerCutOff; // outer cut-off angle

    // attenuation
    float constant;
    float linear;
    float quadratic;
};

in vec3 fragPos;  
in vec3 normal;  
in vec2 texCoord;

uniform Material material;
uniform Light light;
uniform vec3 u_viewPos;

void main() {
    // ambient
    vec3 rgb = texture(material.diffuse, texCoord).rgb;
    vec3 ambient = light.ambient * rgb;
  	
    // diffuse 
    vec3 norm = normalize(normal);
    vec3 lightDir = normalize(light.position - fragPos); // lightDir = from fragPos to light
    float dotNormLight = dot(norm, lightDir);
    float diff = max(dotNormLight, 0.0);
    vec3 diffuse = light.diffuse * diff * rgb;  
    
      // specular
    vec3 viewDir = normalize(u_viewPos - fragPos);
    vec3 reflectDir = reflect(-lightDir, norm); // -lightDir = from light to fragPos
    float spec = 0.0;
    if (dotNormLight > 0.0) {
        spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    }
    vec3 specular = light.specular * spec * material.specular;  

    // spotlight (soft edges)
    // theta: cos(angle) between light direction (fragPos to light) and spotDir
    float theta = dot(lightDir, normalize(-light.direction));
    float cosCutoff = cos(light.cutOff);
    float cosOuterCutoff = cos(light.outerCutOff);
    if (theta > cosOuterCutoff) {  // theta angle이 outerCutOff angle보다 작을 때
        float epsilon = (cosCutoff - cosOuterCutoff);
        // clamp(분자/분모, 최소, 최대) = 분자/분모가 최소보다 작으면 최소, 최대보다 크면 최대
        float intensity = clamp((theta - cosOuterCutoff) / epsilon, 0.0, 1.0);
        diffuse *= intensity;
        specular *= intensity;
    }
    else { // theta angle이 outerCutOff angle을 벗어날 때
        diffuse = vec3(0.0);
        specular = vec3(0.0);
    }

    // attenuation
    float distance = length(light.position - fragPos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + 
                        light.quadratic * distance * distance);
    ambient *= attenuation;
    diffuse *= attenuation;
    specular *= attenuation;
        
    vec3 result = ambient + diffuse + specular;
    FragColor = vec4(result, 1.0);
} 