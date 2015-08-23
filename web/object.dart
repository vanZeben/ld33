part of ld33;

abstract class BlankObject {
  Vector2 pos;
  Sprite sprite;
  
  BlankObject(this.pos, this.sprite);
  void render(double time);
  Sprite getSprite() {
    return sprite;
  }
}

class Rain extends BlankObject {
  int index;
  Vector2 speed;
  Rain(this.index, Vector2 pos, Sprite sprite) : super(pos, sprite);
  double moveSpeed = -1.0;
  void render(double time) {
    if (moveSpeed == -1) {
      moveSpeed = (sprite.h * random.nextInt(index + 2)) * 0.0034;
      if (moveSpeed < 2.5) { moveSpeed = 2.5; }
    }
    pos += new Vector2(0.0 - (moveSpeed).abs(), (moveSpeed).abs());
    if (pos.x < 0) pos.x = GAME_WIDTH ~/GAME_SCALE + sprite.w + random.nextInt(100);
    if (pos.y > GAME_HEIGHT ~/ GAME_SCALE) pos.y = 0.0 - sprite.h;
    sprite.x = pos.x;
    sprite.y = pos.y;
  }
}
class Star extends BlankObject {
  int index;
  Vector2 speed;
  double maxA = 1.0;
  Star(this.index, Vector2 pos, Sprite sprite) : super(pos, sprite) {
    visible = random.nextBool();
    maxA = sprite.a;
  }
  bool visible;
  double lastToggleTime = 0.0;
  void render(double time) {
    if (time - lastToggleTime >= 5000 + random.nextInt(1000) && random.nextInt(1000) > 980) {
      visible = !visible;
      lastToggleTime = time;
    }
    
    if (!visible && sprite.a > 0.0) {
      sprite.a -= 0.1;
    } else if (visible && sprite.a < maxA) {
      sprite.a += 0.1;
    }
//    sprite.r = random.nextDouble();
//    sprite.g = random.nextDouble();
//    sprite.b = random.nextDouble();
    sprite.x = pos.x;
    sprite.y = pos.y;
  }
}


class AnimatedObject extends BlankObject {
  int index;
  Int16List frames;
  int frameIndex = 0;
  int timeFrame = 0;
  double lastUpdate = 0.0;
  AnimatedObject(this.index, Vector2 pos, Sprite sprite, this.frames, this.timeFrame) : super(pos, sprite);
  
  void render(double time) {
    if (time - lastUpdate >= timeFrame) {
      frameIndex = (frameIndex + 1) % frames.length;
      lastUpdate = time;
    }
    
    sprite.u = (frames.elementAt(frameIndex) % (256.0 / sprite.w)).toDouble();
    sprite.v = (frames.elementAt(frameIndex) ~/ (256.0 / sprite.w)).toDouble();
    sprite.x = pos.x;
    sprite.y = pos.y;
  }
    
}