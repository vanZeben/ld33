part of ld33;
class Shader {
  GL.Program program;
  Shader(String vertexShaderSource, String fragmentShaderSource) {
    var vertexShader = compile(vertexShaderSource, GL.VERTEX_SHADER);
    var fragmentShader = compile(fragmentShaderSource, GL.FRAGMENT_SHADER);
    program = link(vertexShader, fragmentShader);
  }
  
  GL.Shader compile(String source, int type) {
    GL.Shader shader = gl.createShader(type); 
    gl.shaderSource(shader, source); 
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, GL.COMPILE_STATUS)) {print(source);throw gl.getShaderInfoLog(shader);}
    return shader; 
  }
  
  GL.Program link(GL.Shader vertex, GL.Shader fragment) {
    GL.Program program = gl.createProgram();
    gl.attachShader(program, vertex);
    gl.attachShader(program, fragment); 
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, GL.LINK_STATUS)) throw gl.getProgramInfoLog(program); 
    return program;
  }
  
  void use() {
    gl.useProgram(program);
  }
}

Shader testShader = new Shader(
    /* Vertex Shader */ """
  precision highp float;
  
  attribute vec2 a_pos;
  attribute vec4 a_col;
  attribute vec2 a_tex;

  uniform mat4 u_pMatrix;

  varying vec4 v_col;
  varying vec2 v_tex;

  void main() {
    v_col = a_col;
    v_tex = a_tex/256.0;
    gl_Position = u_pMatrix*vec4(floor(a_pos), 0.5, 1.0); 
  } 
""",/* Fragment Shader */ """
  precision highp float;
      
  varying vec4 v_col;
  varying vec2 v_tex;

  uniform sampler2D u_tex;

  void main() { 
    vec4 col = texture2D(u_tex, v_tex);
    if (col.a<0.5) discard;
    col = clamp(col*0.5+0.5*col*col*1.2,0.0,1.0);
    gl_FragColor = col*v_col;
  }
""");
Shader scanLine = new Shader(
    /* Vertex Shader */ """
  precision highp float;
  
  attribute vec2 a_pos;
  attribute vec4 a_col;
  attribute vec2 a_tex;

  uniform mat4 u_pMatrix;

  varying vec4 v_col;
  varying vec2 v_uv;

  void main() {
    v_col = a_col;
    v_uv = a_tex/256.0;
    gl_Position = u_pMatrix*vec4(floor(a_pos), 0.5, 1.0); 
  } 
""",/* Fragment Shader */ """
  precision highp float;
      
  varying vec4 v_col;
  varying vec2 v_uv;

  uniform sampler2D uDiffuseTexture;
  uniform float uTime;
  uniform vec2 uResolution;

  float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
  }
  void main() { 
    vec2 q = gl_FragCoord.xy / uResolution.xy;
vec2 uv = 0.5 + (q-0.5)*(0.98 + 0.001*sin(0.95*uTime));
    vec3 oricol = texture2D(uDiffuseTexture,vec2(q.x,1.0-q.y)).xyz;
    vec3 col;
    col.r = texture2D(uDiffuseTexture,vec2(uv.x+0.003,-uv.y)).x;
    col.g = texture2D(uDiffuseTexture,vec2(uv.x+0.000,-uv.y)).y;
    col.b = texture2D(uDiffuseTexture,vec2(uv.x-0.003,-uv.y)).z;

    col = clamp(col*0.5+0.5*col*col*1.2,0.0,1.0);
    col *= 0.6 + 0.4*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y);
    col *= vec3(0.9,1.0,0.7);
    col *= 0.8+0.2*sin(10.0*uTime+uv.y*900.0);
    col *= 1.0-0.07*rand(vec2(uTime, tan(uTime)));

    float comp = smoothstep( 0.2, 0.7, sin(uTime) );
    col = mix( col, oricol, clamp(-2.0+2.0*q.x+3.0*comp,0.0,1.0) );
    
    gl_FragColor = vec4(col,1.0);
  }
""");

