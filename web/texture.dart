part of ld33;

class Texture {
  static List<Texture> _all = new List<Texture>();
  static void loadAll() {
    _all.forEach((texture) => texture.load());
  }
  static void areAllLoaded() {
    bool loaded = true;
    for(Texture tex in _all) {
      if (!tex.loaded) {
        loaded = false;
        break;
      }
    }
    if (loaded) {
      Game.texLoaded = true;
    }
  }
  
  String url;
  GL.Texture texture;
  Texture(this.url) {
    for (Texture tex in _all) {
      if (tex.loaded && tex.url == url) {
        texture = tex.texture;
      }
    }
    _all.add(this);
  }
  bool loaded = false;
  load() {
    ImageElement img = new ImageElement();
    texture = gl.createTexture();
    img.onLoad.listen((e) { 
      gl.bindTexture(GL.TEXTURE_2D, texture);
      gl.texImage2DImage(GL.TEXTURE_2D, 0, GL.RGBA, GL.RGBA, GL.UNSIGNED_BYTE, img);
      gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
      gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
      loaded = true;
      areAllLoaded();
    });
    img.src = url;
  }
}