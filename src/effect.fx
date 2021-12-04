/////////////////////////////////////////////////////////
// LayerLight3D

precision mediump float;

//The current foreground texture co-ordinate
varying mediump vec2 vTex;
//The foreground texture sampler, to be sampled at vTex
uniform lowp sampler2D samplerFront;
//The current foreground rectangle being rendered
uniform mediump vec2 srcStart;
uniform mediump vec2 srcEnd;
//The current foreground source rectangle being rendered
uniform mediump vec2 srcOriginStart;
uniform mediump vec2 srcOriginEnd;
//The current foreground source rectangle being rendered, in layout 
uniform mediump vec2 layoutStart;
uniform mediump vec2 layoutEnd;
//The background texture sampler used for background - blending effects
uniform lowp sampler2D samplerBack;
//The current background rectangle being rendered to, in texture co-ordinates, for background-blending effects
uniform mediump vec2 destStart;
uniform mediump vec2 destEnd;
//The time in seconds since the runtime started. This can be used for animated effects
uniform mediump float seconds;
//The size of a texel in the foreground texture in texture co-ordinates
uniform mediump vec2 pixelSize;
//The current layer scale as a factor (i.e. 1 is unscaled)
uniform mediump float layerScale;
//The current layer angle in radians.
uniform mediump float layerAngle;
// Depth sample
uniform sampler2D samplerDepth;

uniform lowp float layerWidth;
uniform lowp float layerHeight;
uniform lowp float layerDepth;
uniform lowp float lightX;
uniform lowp float lightY;
uniform lowp float lightZ;
uniform lowp vec3 lightColor;
uniform lowp float lightPower;
uniform lowp float specularX;
uniform lowp float specularY;
uniform lowp float specularZ;
uniform lowp vec3 specularColor;
uniform lowp float specularPower;
uniform lowp vec3 ambientColor;

vec3 normal(in vec2 uv)
{
	vec2 s = pixelSize;

	const vec2 size = vec2(2.0,0.0);
	const vec3 off = vec3(-1.,0.,1.);

    float s11 = texture2D(samplerDepth, mix(destStart, destEnd, (uv-srcOriginStart)/(srcOriginEnd-srcOriginStart))).x;
    float s01 = texture2D(samplerDepth, mix(destStart, destEnd, (uv-srcOriginStart+off.xy*pixelSize)/(srcOriginEnd-srcOriginStart))).x;
    // float s21 = texture2D(samplerDepth, mix(destStart, destEnd, (uv-srcOriginStart+off.zy*pixelSize)/(srcOriginEnd-srcOriginStart))).x;
    float s10 = texture2D(samplerDepth, mix(destStart, destEnd, (uv-srcOriginStart+off.yx*pixelSize)/(srcOriginEnd-srcOriginStart))).x;
    // float s12 = texture2D(samplerDepth, mix(destStart, destEnd, (uv-srcOriginStart+off.yz*pixelSize)/(srcOriginEnd-srcOriginStart))).x;

	vec3 va = (vec3(size.xy*0.00001, s01 - s11));
    vec3 vb = (vec3(size.yx*0.00001, s10 - s11));

    vec3 normalV = normalize(cross(va, vb));
    
	return normalV;
}

// TODO
// Linearize depth sample based on near and far clipping plane

void main(void)
{
	vec2 lightPos = vec2(lightX/layerWidth, 1.0-lightY/layerHeight);
	vec4 frontSample = texture2D(samplerFront, vTex);
    float depthSample = texture2D(samplerDepth, mix(destStart, destEnd, (vTex-srcOriginStart)/(srcOriginEnd-srcOriginStart))).x;
  	vec2 nVtex = (vTex-srcOriginStart)/(srcOriginEnd-srcOriginStart);
  	vec3 n = normal(vTex);

	mediump float zFar = 10000.0;
    mediump float zNear = 1.0;
    mediump float zLinear = zNear * zFar / (zFar + depthSample * (zNear - zFar));

	// vec3 rgbNormal = n * 0.5 + 0.5;

	// Lighting
	vec3 lp = vec3(lightPos, lightZ/layerDepth); // Need to linearize z and match to depthSample linear range
	// vec3 lp = vec3(lightPos, 0.2);
	vec3 sp = vec3(nVtex, zLinear/zFar);
	float d = 1.0-distance(lp,sp);
	
	vec3 c = lightColor * frontSample.rgb * clamp(dot(n, normalize(lp - sp)) * pow(d, lightPower), 0.0, 1.0)  + frontSample.rgb*ambientColor;

	// Specular
    float e = specularPower;
    // vec3 ep = vec3(specularX/layerWidth, 1.0-specularY/layerHeight, 0.2);
    vec3 ep = vec3(specularX/layerWidth, 1.0-specularY/layerHeight, specularZ/layerDepth);  // Need to linearize z and match to depthSample linear range
	c += specularColor * pow(clamp(dot(normalize(reflect(lp - sp, n)), 
	 				   normalize(sp - ep)), 0., 1.), e) * d;
	
	gl_FragColor = vec4(c, 1.)*frontSample.a;
	// gl_FragColor = vec4(rgbNormal, 1.)*frontSample.a;
}