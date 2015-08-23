part of ld33;

// x, y
// u, v
// r, g, b, a

class Sprites {
  static const int BYTES_PER_FLOAT = 4;
  static const int FLOATS_PER_VERTEX = 8;
  static const int MAX_VERTICES = 65536;
  static const int MAX_SPRITES = MAX_VERTICES~/4;
  
  List<Sprite> sprites = new List<Sprite>();

  Shader shader;
  GL.Texture texture;
  GL.UniformLocation pMatrixLocation, muTimeLocation, muResLocation;
  GL.Buffer vertexBuffer, indexBuffer;
  Float32List vertexData;
  Sprites(this.shader, this.texture) {
      Int16List indexData = new Int16List(MAX_SPRITES * 6);
      for (int i =0; i < MAX_SPRITES;i++) {
        int offs = i * 4;
        indexData.setAll(i*6, [offs + 0, offs + 1, offs + 2, offs + 0, offs + 2, offs + 3]);
      }
      
      vertexBuffer = gl.createBuffer();
      vertexData = new Float32List(MAX_VERTICES * FLOATS_PER_VERTEX);
      gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
      gl.bufferDataTyped(GL.ARRAY_BUFFER, vertexData, GL.DYNAMIC_DRAW);
          
      indexBuffer = gl.createBuffer();
      gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
      gl.bufferDataTyped(GL.ELEMENT_ARRAY_BUFFER, indexData, GL.STATIC_DRAW); 

      shader.use();
      
      int posLocation = gl.getAttribLocation(shader.program, "a_pos");
      int colLocation = gl.getAttribLocation(shader.program, "a_col");
      int texLocation = gl.getAttribLocation(shader.program, "a_tex");

      gl.enableVertexAttribArray(posLocation);
      gl.enableVertexAttribArray(colLocation);
      gl.enableVertexAttribArray(texLocation);

      gl.vertexAttribPointer(posLocation, 2, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 0 * BYTES_PER_FLOAT);
      gl.vertexAttribPointer(texLocation, 2, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 2 * BYTES_PER_FLOAT);
      gl.vertexAttribPointer(colLocation, 4, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 4 * BYTES_PER_FLOAT);

      pMatrixLocation = gl.getUniformLocation(shader.program, "u_pMatrix");
      muTimeLocation = gl.getUniformLocation(shader.program, "uTime");
      muResLocation = gl.getUniformLocation(shader.program, "uResolution");
  }
  void addSprite(Sprite sprite) {
    sprite.index = sprites.length;
    sprites.add(sprite);
  }
  
  void render(Matrix4 pMatrix, double time) {
    gl.bindTexture(GL.TEXTURE_2D, texture);
    shader.use();
    
    int toReplace = sprites.length;
    if (toReplace> MAX_SPRITES) toReplace = MAX_SPRITES;
    for (int i = 0; i < toReplace;i++) {
      sprites[i].set(vertexData, i * FLOATS_PER_VERTEX*4);
    }
    gl.bufferSubDataTyped(GL.ARRAY_BUFFER, 0, vertexData.sublist(0, toReplace*FLOATS_PER_VERTEX*4) as Float32List);
    gl.uniformMatrix4fv(pMatrixLocation, false, pMatrix.storage); 
    gl.uniform1f(muTimeLocation, Game.instance.gameLoop.frame);
    gl.uniform2f(muResLocation, GAME_WIDTH ~/ GAME_SCALE * 2.0, GAME_HEIGHT ~/ GAME_SCALE * 2.0);
    gl.drawElements(GL.TRIANGLES, sprites.length*6, GL.UNSIGNED_SHORT, 0);
  }
}

class Sprite {
  double x, y;
  double w, h;
  double u, v;
  bool flip = false;
  double r, g, b, a;
  int index;
  Sprite(this.x, this.y, this.w, this.h, this.u, this.v, this.r, this.g, this.b, this.a, this.flip);
  
  void set(Float32List data, int offs) {
    if (!flip) {
      data.setAll(offs, [
        x+0, y+0, (u*w)+0+0.5, (v*h)+0+0.5, r, g, b, a,
        x+w, y+0, (u*w)+w-0.5, (v*h)+0+0.5, r, g, b, a,
        x+w, y+h, (u*w)+w-0.5, (v*h)+h-0.5, r, g, b, a,
        x+0, y+h, (u*w)+0+0.5, (v*h)+h-0.5, r, g, b, a,
      ]);
    } else {
      data.setAll(offs, [
        x+0, y+0, (u*w)+w-0.5, (v*h)+0+0.5, r, g, b, a,
        x+w, y+0, (u*w)+0+0.5, (v*h)+0+0.5, r, g, b, a,
        x+w, y+h, (u*w)+0+0.5, (v*h)+h-0.5, r, g, b, a,
        x+0, y+h, (u*w)+w-0.5, (v*h)+h-0.5, r, g, b, a,
      ]);
    }
  }
}
