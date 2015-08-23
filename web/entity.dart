part of ld33;

abstract class Entity {
  int index;

  int numTilesPerRow;
  final double moveSpeed = 1.0;
  Vector2 pos;
  Vector2 vel = new Vector2(0.0, 0.0);
  Vector2 accel = new Vector2(0.98, 9.8);

  Vector4 bounds;
  int jumpHeight = 3;
  int jumpTime = 1;

  int w, h;
  int stepCount = 0;
  bool isMoving = false;
  bool isMovingLeft = false;
  bool isOnGround = false;
  int spriteIndex = 0;
  Sprite sprite;
  bool destroy = false;
  int maxHealth = 10;
  int health = 10;
  double damageCooldown = 0.0;
  bool canBeDamaged = true;
  static Vector4 collisionX = new Vector4(0.0, 0.0, 0.0, 0.0);
  Entity(this.index, this.pos, this.w, this.h, this.sprite, this.bounds) {
    numTilesPerRow = 256 ~/ w;
  }

  bool jump();
  bool moveLeft();
  bool moveRight();
  void damage(int amount) {
    if (health <= 0) {
      die();
    }
    if (!canBeDamaged) {
      return;
    } else {
      canBeDamaged = false;
    }
    health -= amount;
    if (health <= 0) {
      die();
    }
  }

  void die() {
    sprite.a = 0.0;
  }

  Int32List hasCollidedX(Vector2 newPos) {
    for (int x = 0; x < 2; x++) {
      int xx = (newPos.x +
          (x == 0
              ? bounds.x + (!isMovingLeft ? 1 : -1)
              : bounds.z + (!isMovingLeft ? 1 : -1))).floor();
      for (int y = bounds.y.toInt(); y < bounds.w - 1; y++) {
        int yy = (newPos.y + y.toDouble()).floor();
        int tileId = Game.instance.activeLevel.getTileAt(xx ~/ 16, yy ~/ 16);
        if (tileId != 0) {
          return new Int32List.fromList([xx, yy]);
        }
      }
    }
    return new Int32List.fromList([-1, -1]);
  }

  Int32List hasCollidedY(Vector2 newPos) {
    for (int y = 0; y < 2; y++) {
      int yy = (newPos.y + (y == 0 ? bounds.y + 1 : bounds.w - 1)).floor();
      for (int x = bounds.x.toInt() + 2; x < bounds.z; x++) {
        int xx = (newPos.x + x.toDouble()).floor();
        int tileId = Game.instance.activeLevel.getTileAt(xx ~/ 16, yy ~/ 16);
        if (tileId != 0) {
          return new Int32List.fromList([xx, yy]);
        }
      }
    }
    return new Int32List.fromList([-1, -1]);
  }

  void collidedBoth(Int32List collideX, Int32List collideY);
  void collidedX(Int32List location);
  void collidedY(Int32List location);
  void updateSprite(double time);

  void forceJump() {
    vel.y = 0.0 - jumpHeight;
    isOnGround = false;
  }

  void updateAI(double delta, double time) {
    if (isOnGround && jump()) {
      forceJump();
    }
    updateSprite(time);
    if (moveLeft() && !moveRight()) {
      isMovingLeft = true;
      isMoving = true;
      vel.add(new Vector2(-1.0, 0.0));
      stepCount++;
    } else if (moveRight() && !moveLeft()) {
      isMovingLeft = false;
      isMoving = true;
      vel.add(new Vector2(1.0, 0.0));
      stepCount++;
    } else {
      isMoving = false;
      vel.x = 0.0;
    }
    if (vel.y < 9.8) {
      vel.add(new Vector2(0.0, accel.y * delta));
    }
    if (!canBeDamaged && damageCooldown == 0.0) {
      damageCooldown = time;
    }
    if (time - damageCooldown > 1000) {
      damageCooldown = 0.0;
      canBeDamaged = true;
    }
    if (time - damageCooldown > 100) {
      sprite.g = 1.0;
      sprite.b = 1.0;
    }
  }
  void render(double delta, double time) {
    if (destroy) {
      sprite.a = 0.0;
      sprite = null;
      return;
    }
    updateAI(delta, time);
    Vector2 newPos = pos.clone().add(vel);
    Int32List collideY = hasCollidedY(pos.clone().add(new Vector2(0.0, vel.y)));
    Int32List collideX = hasCollidedX(pos.clone().add(new Vector2(vel.x, 0.0)));
    if (collideY.elementAt(0) > -1) {
      vel.y = 0.0;
      if (collideX.elementAt(0) > -1) {
        vel.x = 0.0;
        collidedBoth(collideX, collideY);
      } else {
        collidedY(collideY);
      }
      if (!isOnGround) isOnGround = true;
    } else if (collideX.elementAt(0) > -1) {
      vel.x = 0.0;
      collidedX(collideX);
    }

    if (newPos.x < -1.0 || newPos.x >= (Game.instance.activeLevel.w * 16.0)) {
      vel.x = 0.0;
    }

    if (isMoving) {
      if (vel.x >= 1.0) {
        vel.x = accel.x;
      } else if (vel.x <= -1.0) {
        vel.x = 0.0 - accel.x;
      }
    }

    setPos(pos.clone().add(vel));
    vel.x = 0.0;
  }

  void setPos(Vector2 pos) {
    this.pos = pos;
    sprite.x = pos.x;
    sprite.y = pos.y;
    sprite.flip = !isMovingLeft;
    sprite.u = (spriteIndex % numTilesPerRow).floorToDouble();
    sprite.v = (spriteIndex ~/ numTilesPerRow).floorToDouble();
  }
  
  Sprite getSprite() {
    return sprite;
  }
}

class Villager extends Entity {
  Vector4 camBounds =
      new Vector4(50.0, 50.0, GAME_WIDTH - 50.0, GAME_HEIGHT - 50.0);
  bool forwardMove = true;
  Int16List idleFrames = new Int16List.fromList([0, 1]);
  Int16List walkingFrames = new Int16List.fromList([0, 2, 3, 4, 5, 6, 7]);
  Int16List onFireFrames = new Int16List.fromList([8, 9]);
  double lastSpriteUpdateTime = 0.0;
  bool onFire = false;
  int feetSpriteIndex = 0;
  Sprite feetSprite;
  int dir = 0;
  Rectangle hitBox;
  Villager(int index, Vector2 pos, int w, int h, Sprite sprite) : super(index,
          pos, w, h, sprite,
          new Vector4((w / 2.0) - 3.0, 0.0, (w / 2.0) + 3.0, h / 2.0)) {
    feetSprite = new Sprite(sprite.x, sprite.y, sprite.w, sprite.h, sprite.u,
        sprite.v + 1, sprite.r, sprite.g, sprite.b, sprite.a, sprite.flip);
    feetSprite.a = 1.0;
    spriteIndex = 0;
    this.accel.x = 2.0;
    hitBox = new Rectangle(pos.x + 3, pos.y + 7, w - 4, h - 14 - 7);
  }

  bool jump() {
    return false;
  }
  bool moveLeft() {
    return dir == -1;
  }
  bool moveRight() {
    return dir == 1;
  }
  double getAnimLength() {
    if (onFire) {
      return onFireFrames.length / 2.0;
    }
    if (isMoving) {
      return walkingFrames.length / 2.0;
    }
    return idleFrames.length / 2.0;
  }

  int walkingFrameIndex = 0;
  int idleFrameIndex = 0;
  int attackingSteps = 0;
  double attackFrameUpdateTime = 0.0;
  void updateSprite(double time) {
    bool updated = false;

    if (onFire) {
      if (time - attackFrameUpdateTime >= 125) {
        attackingSteps += 1;
        if (attackingSteps >= onFireFrames.length) {
          attackingSteps = 0;
        }
        spriteIndex =
            (0 * numTilesPerRow) + onFireFrames.elementAt(attackingSteps);
        updated = true;
        attackFrameUpdateTime = time;
      }
      if (isMoving) {
        if (time - lastSpriteUpdateTime > 75) {
          walkingFrameIndex += 1;
          if (walkingFrameIndex >= walkingFrames.length) {
            walkingFrameIndex = 0;
          }
          feetSpriteIndex =
              (1 * numTilesPerRow) + walkingFrames.elementAt(walkingFrameIndex);
          updated = true;
        }
      }
    } else {
      if (!isMoving) {
        if (time - lastSpriteUpdateTime > 250) {
          idleFrameIndex += 1;
          if (idleFrameIndex >= idleFrames.length) {
            idleFrameIndex = 0;
          }
          spriteIndex =
              (0 * numTilesPerRow) + idleFrames.elementAt(idleFrameIndex);
          feetSpriteIndex =
              (1 * numTilesPerRow) + idleFrames.elementAt(idleFrameIndex);

          updated = true;
        }
      } else {
        if (time - lastSpriteUpdateTime > 75) {
          walkingFrameIndex += 1;
          if (walkingFrameIndex >= walkingFrames.length) {
            walkingFrameIndex = 0;
          }
          spriteIndex =
              (0 * numTilesPerRow) + walkingFrames.elementAt(walkingFrameIndex);
          feetSpriteIndex =
              (1 * numTilesPerRow) + walkingFrames.elementAt(walkingFrameIndex);
          updated = true;
        }
      }
    }

    if (updated) {
      lastSpriteUpdateTime = time;
    }
  }

  double lastAIUpdate = 0.0;
  double timeSetAblaze = 0.0;
  void updateAI(double delta, double time) {
    super.updateAI(delta, time);
//    if (time - timeSetAblaze > (20 + random.nextInt(10)) * 1000) {
//      onFire = false;
//    }
    if (onFire) {
      if (timeSetAblaze == 0.0) {
        timeSetAblaze = time;
        AudioController.play("enemy_hurt", 5000);
      }
      if (dir == 0) {
        dir = random.nextBool() ? 1 : -1;
        accel *= 1.24;
      } else if (time - lastAIUpdate > 500) {
        dir = random.nextBool() ? 1 : -1;
      }
      if (time - timeSetAblaze > 100) {
        for (Entity e in Game.instance.level.entityObjects) {
          if (e is Player) {
            if (e.hitBox.intersects(hitBox)) {
              e.damage(1);
            }
          }
        }
      }
    } else if (time - lastAIUpdate > 1000) {
      int rand = random.nextInt(1000);
      if (rand > 950) {
        if (dir == 0) {
          dir = random.nextBool() ? 1 : -1;
          lastAIUpdate = time;
        } else {
          dir = 0;
          lastAIUpdate = time;
          isMoving = false;
        }
      } else if (rand > 750) {
        dir = 0;
        lastAIUpdate = time;
        isMoving = false;
      }
    }
  }

  void render(double delta, double time) {
    Vector2 oldPos = pos.clone();

    super.render(delta, time);

    double diffX = pos.x - oldPos.x;
    double diffY = pos.y - oldPos.y;
    hitBox.left += diffX;
    hitBox.top += diffY;

    feetSprite.x = sprite.x;
    feetSprite.y = sprite.y;
    feetSprite.flip = !isMovingLeft;
    feetSprite.u = (feetSpriteIndex % numTilesPerRow).floorToDouble();
    feetSprite.v = (feetSpriteIndex ~/ numTilesPerRow).floorToDouble();
  }

  void collidedBoth(Int32List collideX, Int32List collideY) {}
  void collidedX(Int32List location) {
    forwardMove = !forwardMove;
  }
  void collidedY(Int32List location) {}
}

class Player extends Entity {
  Vector4 camBounds =
      new Vector4(50.0, 50.0, GAME_WIDTH - 50.0, GAME_HEIGHT - 50.0);
  bool forwardMove = true;
  Int16List idleFrames = new Int16List.fromList([0, 1, 2, 3]);
  Int16List walkingFrames = new Int16List.fromList([0, 1, 2, 3, 4, 5, 6]);
  Int16List attackingFrames = new Int16List.fromList([0, 2, 0, 1, 2]);
  double lastAttackUpdateTime = 0.0;
  double lastSpriteUpdateTime = 0.0;
  int feetSpriteIndex = 0;
  Sprites sprites;
  List<Sprite> healthBar = new List<Sprite>();
  Rectangle hitBox;
  Sprite levelBar;
  Sprite levelBarOverlay;
  int totalKills = 0;
  int killsRound = 0;
  
  Sprite feetSprite;
  Player(int index, Vector2 pos, int w, int h, Sprite sprite, this.sprites)
      : super(index, pos, w, h, sprite,
          new Vector4((w / 2.0) - 3.0, 0.0, (w / 2.0) + 3.0, h / 2.0)) {
    feetSprite = new Sprite(sprite.x, sprite.y, sprite.w, sprite.h, sprite.u,
        sprite.v + 1, sprite.r, sprite.g, sprite.b, sprite.a, sprite.flip);
    feetSprite.a = 0.0;
    for (int i = health; i > 0; i--) {
      healthBar.add(new Sprite(
          (5.0 * i), 5.0, 16.0, 16.0, 0.0, 2.0, 1.0, 1.0, 1.0, 1.0, true));
    }
    for (Sprite s in healthBar) {
      sprites.addSprite(s);
    }

    levelBar = new Sprite(GAME_WIDTH ~/ GAME_SCALE/2.0 - (5.0 * 16.0)/2.0, 5.0, 5.0 * 16.0, 16.0, 1.0, 3.0, 1.0, 1.0, 1.0, 1.0, false);
    levelBarOverlay = new Sprite(GAME_WIDTH ~/ GAME_SCALE/2.0 - (5.0 * 16.0)/2.0, 5.0, 1.0, 16.0, 0.0, 3.0, 1.0, 1.0, 1.0, 1.0, false);
    
    sprites.addSprite(levelBar);
    sprites.addSprite(levelBarOverlay);
    spriteIndex = 16;
    this.accel.x = 2.0;
    hitBox = new Rectangle(pos.x + 4, pos.y + 7, w - 19 - 4, h - 14 - 7);
  }

  void setHealth(int health) {
    this.health = health;
    for (int i = 0; i < (maxHealth - health); i++) {
      healthBar.elementAt(i).u = 1.0;
    }
  }
  bool attack() {
    return Game.instance.isAttacking();
  }

  bool jump() {
    return Game.instance.isJumping();
  }
  bool moveLeft() {
    return Game.instance.isMovingLeft();
  }
  bool moveRight() {
    return Game.instance.isMovingRight();
  }

  void damage(int amount) {
    int oldHealth = this.health;
    super.damage(amount);
    if (health < oldHealth) {
      AudioController.play("hurt", 5000);
    }
    for (int i = 0; i < (maxHealth - health); i++) {
      healthBar.elementAt(i).u = 1.0;
    }
    sprite.r = 1.0;
    sprite.g = 0.0;
    sprite.b = 0.0;
    feetSprite.r = 1.0;
    feetSprite.b = 0.0;
    feetSprite.g = 0.0;
  }

  void die() {
    var res = context.callMethod("prompt", ["Congrats on hitting wave ${(Game.instance.level as CastleLevel).wave}, please enter your name to add a high score"]);
    if (res != null) {
      Leaderboard.insert(res, Game.instance.gameLoop.accumulatedTime.floor(), (Game.instance.level as CastleLevel).wave);
    }
    Game.instance.level = new MenuLevel(true);
    sprite.a = 0.0;
    feetSprite.a = 0.0;
  }

  double getAnimLength() {
    if (isAttacking) {
      return attackingFrames.length / 2.0;
    }
    if (isMoving) {
      return walkingFrames.length / 2.0;
    }
    return idleFrames.length / 2.0;
  }

  int walkingFrameIndex = 0;
  int idleFrameIndex = 0;
  int attackingSteps = 0;
  double attackFrameUpdateTime = 0.0;
  double lastAttackTime = 0.0;
  bool isAttacking = false;
  void updateSprite(double time) {
    bool updated = false;
    if (isAttacking) {
      if (time - attackFrameUpdateTime >= 125) {
        attackingSteps += 1;
        if (attackingSteps >= attackingFrames.length) {
          attackingSteps = 0;
        }
        spriteIndex =
            (5 * numTilesPerRow) + attackingFrames.elementAt(attackingSteps);
        updated = true;
        attackFrameUpdateTime = time;
      }
      if (isMoving) {
        if (time - lastSpriteUpdateTime > 75) {
          walkingFrameIndex += 1;
          if (walkingFrameIndex >= walkingFrames.length) {
            walkingFrameIndex = 0;
          }
          feetSpriteIndex =
              (4 * numTilesPerRow) + walkingFrames.elementAt(walkingFrameIndex);
          updated = true;
        }
      } else {
        feetSpriteIndex =
            (6 * numTilesPerRow) + attackingFrames.elementAt(attackingSteps);
      }
    } else {
      if (!isMoving) {
        if (time - lastSpriteUpdateTime > 250) {
          idleFrameIndex += 1;
          if (idleFrameIndex >= idleFrames.length) {
            idleFrameIndex = 0;
          }
          spriteIndex =
              (2 * numTilesPerRow) + idleFrames.elementAt(idleFrameIndex);
          updated = true;
        }
      } else {
        if (time - lastSpriteUpdateTime > 75) {
          walkingFrameIndex += 1;
          if (walkingFrameIndex >= walkingFrames.length) {
            walkingFrameIndex = 0;
          }
          spriteIndex =
              (3 * numTilesPerRow) + walkingFrames.elementAt(walkingFrameIndex);
          feetSpriteIndex =
              (4 * numTilesPerRow) + walkingFrames.elementAt(walkingFrameIndex);
          updated = true;
        }
      }
    }

    if (updated) {
      lastSpriteUpdateTime = time;
    }
  }
  bool lockAttack = false;
  void updateAI(double delta, double time) {
    super.updateAI(delta, time);
    if (attack() && !isAttacking && !lockAttack) {
      isAttacking = true;
      lastAttackTime = time;
    } else if (isAttacking && time - lastAttackTime >= 1000) {
      isAttacking = false;
      lockAttack = true;
    } else if (!attack() && time - lastAttackTime >= 1500) {
      lastAttackTime = 0.0;
      lockAttack = false;
    }

    if (isAttacking) {
      for (Entity e in Game.instance.level.entityObjects) {
        if (e is Villager) {
          if (e.hitBox.intersects(hitBox)) {
            if (!e.onFire) {
              e.onFire = true;
              killsRound++;
              totalKills++;
              continue;
            }
          }
        }
      }
    }
    if (Game.instance.level is CastleLevel) {
      if (killsRound <= (Game.instance.level as CastleLevel).pointsNeededToAdvance) {
        levelBarOverlay.w = levelBar.w * (killsRound / (Game.instance.level as CastleLevel).pointsNeededToAdvance);
        levelBarOverlay.x = levelBar.x;
      }
    }

    if (time - damageCooldown > 100) {
      feetSprite.g = 1.0;
      feetSprite.b = 1.0;
    }
  }

  void moveCamera() {
    Vector2 coord = new Vector2(
        (pos.x - ((GAME_WIDTH ~/ GAME_SCALE) / 2)).floorToDouble(),
        (pos.y - ((GAME_HEIGHT ~/ GAME_SCALE) / 2)).floorToDouble());
    Game.instance.level.moveToCoord = coord;
  }
  
  void render(double delta, double time) {
    Vector2 oldPos = pos.clone();
    super.render(delta, time);
    if (isMoving || !isOnGround) {
      moveCamera();
    }

    double diffX = pos.x - oldPos.x;
    double diffY = pos.y - oldPos.y;
    hitBox.left += diffX;
    hitBox.top += diffY;
    if (!feetSprite.flip && !isMovingLeft) {
      hitBox.left += 15;
    } else if (feetSprite.flip && isMovingLeft) {
      hitBox.left -= 15;
    }
    feetSprite.x = sprite.x;
    feetSprite.y = sprite.y;
    feetSprite.flip = !isMovingLeft;
    feetSprite.u = (feetSpriteIndex % numTilesPerRow).floorToDouble();
    feetSprite.v = (feetSpriteIndex ~/ numTilesPerRow).floorToDouble();
    if (isMoving || isAttacking) {
      if (feetSprite.a == 0.0) {
        feetSprite.a = 1.0;
      }
    } else {
      if (feetSprite.a >= 1.0) {
        lastSpriteUpdateTime = 0.0;
        feetSprite.a = 0.0;
      }
    }
  }

  void collidedBoth(Int32List collideX, Int32List collideY) {}
  void collidedX(Int32List location) {}
  void collidedY(Int32List location) {}
}
