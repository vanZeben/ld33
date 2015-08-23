library ld33;

import 'dart:html';
import 'dart:web_gl' as GL;

import 'dart:math' hide Rectangle;
import 'dart:async';
import 'dart:typed_data'; 
import 'dart:web_audio';
import 'package:vector_math/vector_math.dart';
import 'package:game_loop/game_loop_html.dart';
import 'package:stagexl/stagexl.dart';
import 'dart:js';

part 'shader.dart';
part 'texture.dart';
part 'sprites.dart';
part 'entity.dart';
part 'level.dart';
part 'object.dart';
part 'audio.dart';
part 'leaderboarder.dart';

GL.RenderingContext gl;

const int GAME_WIDTH = 420;
const int GAME_HEIGHT = 240;
const double GAME_SCALE = 1.5;
Random random = new Random();

Audio audio;
class Game {
  static Game instance;
  static bool texLoaded = false;
  static bool lvlLoaded = false;
  static bool running = false;
  static bool paused = false;
  CanvasElement canvas;
  GameLoopHtml gameLoop;
  Level activeLevel;
  List<bool> keys = new List<bool>(256);
  
  Game() {
    instance = this;
    canvas = querySelector("#game");
    gameLoop = new GameLoopHtml(canvas);
    gl = canvas.getContext('webgl');
    if (gl == null) gl = canvas.getContext('experimental-webgl'); 
    if (gl == null) querySelector('#webgl_missing').setAttribute('style', 'display: all');
    else start();
  }

  void resize() {
    int w = window.innerWidth;
    int h = window.innerHeight;
    double xScale = w/GAME_WIDTH;
    double yScale = h/GAME_HEIGHT;
    
    if (xScale < yScale) {
      int newHeight = (GAME_HEIGHT*xScale).floor();
      canvas.setAttribute("style", "position: absolute; width: ${w}px; height: ${GAME_HEIGHT * xScale}px; left:0px;top:${(h-newHeight)/2}px"); 
    } else {
      int newWidth = (GAME_WIDTH*yScale).floor();
      canvas.setAttribute("style", "position: absolute; width: ${GAME_WIDTH * yScale}px; height: ${h}px; left:${(w-newWidth)/2}px;top:0px"); 
    }
  }
  
  void start() {
    resize();
    window.onResize.listen((event) => resize());
    audio = new Audio();
    for (int i =0 ; i < keys.length;i++) { keys[i] = false; }
    window.onKeyDown.listen((e) {
      if (!paused && e.keyCode<256) keys[e.keyCode] = true;
      e.preventDefault();
    });
    
    window.onKeyUp.listen((e) {
      if (!paused && e.keyCode<256) keys[e.keyCode] = false;
      e.preventDefault();
    });

    window.onBlur.listen((e) {
      for (int i =0 ; i < keys.length;i++) { keys[i] = false; }
      paused = true;
    });
    
    window.onFocus.listen((e) {
      paused = false;
      gameLoop.start();
    });
    
    Leaderboard.getData().catchError((e) {
      print("Error {$e}");
    }).then((e) {
      var lineData = e.split("\n");
      String username = lineData.first.split("|")[0];
      String score = lineData.first.split("|")[1];
      querySelector("#highscore").innerHtml = "${username} has the highest score of ${score}";
    }); 
    
    
    level = new MenuLevel(false);
    level.start();
    gameLoop.addTimer(render, 0.001, periodic: true);
    gameLoop.start();
  }
  double lightningTime = 0.0;
  bool rainSound = false;
  double damageTime = 0.0;
  int shakeTick = 0;
  double xOffs = 0.0;
  GameLevel level;
  void render(GameLoopTimer timer) {
    double time = timer.gameLoop.gameTime * 1000;
    if (!rainSound) {
      AudioController.playLoop("rain", true, 1000);
      rainSound = true;
    }
    if (!running) {
      if (texLoaded && lvlLoaded) {
        running = true;
      }
      if (time >= 10 * 1000) {
        print("Game could not be initialized, took too long to load resources");
        gameLoop.stop();
        return;
      }
      print("Game has not yet been initialized, please buckle your pants");
      return;
    } 
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clearColor(0.1, 0.1, 0.1, 1.0);
    gl.enable(GL.BLEND);
    gl.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
    gl.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
    
    if (shakeTick > 0) {
      xOffs += random.nextInt(shakeTick) - (shakeTick/2);
      if (xOffs.abs() > 7.0) {
        if (xOffs > 0) {
          xOffs = 7.0;
        } else {
          xOffs = -7.0;
        }
      }
      shakeTick--;
    } else {
      xOffs = 0.0;
    }
    
    level.render(time, gameLoop.dt);
    if (paused) { 
      gameLoop.stop();
      AudioController.stopAll();
      rainSound = false;
    }
    
    zeus(time);
  }
  double zeusStartCount = 0.0;
  bool zeusAudioSent = false;
  int numZeus = 0;
  int zeusIndex = 0;
  void zeus(double time) {
    if ((time - lightningTime > 10 * 1000.0 || zeusIndex < numZeus) && random.nextInt(1000) > 950 && random.nextBool() && zeusStartCount == 0.0) {
      lightningTime = time;
      zeusStartCount = time;
      numZeus = random.nextInt(3);
      zeusIndex = 0;
    } else if (zeusStartCount > 0.0) {
      gl.clearColor(1.0, 1.0, 1.0, 0.3);
      gl.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
      int endTime = 100 + random.nextInt(200);
      if (time - zeusStartCount >= endTime - 50 && !zeusAudioSent) {
        zeusIndex += 1;
        AudioController.play("thunder", 5000);
        zeusAudioSent = true;
      }
      if (time - zeusStartCount >= endTime) {
        zeusStartCount = 0.0;
        zeusAudioSent = false;
      }
    }
  }
  bool isAttacking() {
    return keys[KeyCode.SPACE];
  }
  
  bool isJumping() {
     return keys[KeyCode.UP] || keys[KeyCode.W];
  }
  bool isMovingLeft() {
     return keys[KeyCode.LEFT] || keys[KeyCode.A];
  }
  bool isMovingRight() {
     return keys[KeyCode.RIGHT] || keys[KeyCode.D];
  }
}

void main() {
  new Game();
}

class GUI {
  Sprite paused;
  Sprites gui;
  GUI(this.gui) {
    int w = (GAME_WIDTH - (6.0 * 16.0)) ~/ GAME_SCALE;
    int h = (GAME_HEIGHT - (2.0 * 16.0)) ~/ GAME_SCALE;
    paused = new Sprite((w) / 2.5, (h) / 3.0, 6.0 * 16.0, 2.0 * 16.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false);
    gui.addSprite(paused);
  }
  
  void render(double time, Matrix4 guiMatrix) {
    if (Game.paused && paused.a != 1.0) {
      paused.a = 1.0;
    }
    if (!Game.paused && paused.a != 0.0) {
      paused.a = 0.0;
    }
    gui.render(guiMatrix, time);
  }
}


abstract class GameLevel {

  Sprites entities, moonSprites, sprites, bg, buildings, starSprites, buildingsOverlay, trees;
  Player player;
  Sprite moon;
  Matrix4 camMatrix, levelMatrix, bgMatrix, moonMatrix, skyMatrix, starsMatrix;
  GUI gui;
  List<BlankObject> objects = new List<BlankObject>();
  List<Entity> entityObjects = new List<Entity>();
  String defaultLevel;
  GameLevel(this.defaultLevel) {
  }
  Texture entitySheet;
  void start() {
    camMatrix = makeOrthographicMatrix(0.0, GAME_WIDTH, GAME_HEIGHT, 0.0, -10.0, 10.0).scale(GAME_SCALE, GAME_SCALE, 1.0);
       levelMatrix = camMatrix.clone();
       bgMatrix = camMatrix.clone();
       moonMatrix = camMatrix.clone();
       skyMatrix = camMatrix.clone();
       starsMatrix = camMatrix.clone();
       Texture spriteSheet = new Texture("tex/sprites.png");
       entitySheet = new Texture("tex/entities.png");
       Texture bgSheet = new Texture("tex/background.png");
       Texture buildingSheet = new Texture("tex/buildings.png");
       Texture guiSheet = new Texture("tex/gui.png");
       Texture castleRailSheet = new Texture("tex/castleRail.png");
       Texture castleWallSheet = new Texture("tex/castleWall.png");
       Texture.loadAll();
       
       Sprites levelSheet = new Sprites(testShader, spriteSheet.texture);
            // LOAD LEVELS
            new Level("levels/1.lvl", levelSheet, new Vector4(0.0, 0.2, 0.0, 1.0));
            new Level("levels/2.lvl", levelSheet, new Vector4(0.0, 0.2, 0.0, 1.0));
            Levels.loadAndInit().catchError((e) {
              print("Error {$e}");
            }).then((e) {
              // LOAD SPRITES
              Game.lvlLoaded = true;

              Game.instance.activeLevel = Levels.get(defaultLevel);  
              moonSprites.addSprite(new Sprite(Game.instance.activeLevel.w * 16.0 / 2.0, (Game.instance.activeLevel.h + 10.0) * 16.0 / 2.0, 32.0, 32.0, 1.5, 0.0, 0.6, 0.9, 0.6, 1.0, false));
            }); 
       
       
       gui = new GUI(new Sprites(testShader, guiSheet.texture));
        
       buildings = new Sprites(testShader, buildingSheet.texture);
       buildingsOverlay = new Sprites(testShader, buildingSheet.texture);

       moonSprites = new Sprites(testShader, spriteSheet.texture);
       sprites = new Sprites(testShader, spriteSheet.texture);
       starSprites = new Sprites(testShader, spriteSheet.texture);

       bg = new Sprites(testShader, bgSheet.texture);
       bg.addSprite(new Sprite(0.0, 0.0, 256.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));
       bg.addSprite(new Sprite(256.0, 0.0, 256.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));

       entities = new Sprites(testShader, entitySheet.texture);
   
       player = new Player(0, new Vector2(6.0 * 16.0, 160.0), 32, 32, new Sprite(6 * 16.0, 160.0, 32.0, 32.0, 0.0, 2.0, 1.0, 1.0, 1.0, 1.0, false), gui.gui);
       player.moveCamera();
       entityObjects.add(player);
       entities.addSprite(player.getSprite());
       entities.addSprite(player.feetSprite);
       
        

       for (int i =0; i < 500; i++) {
         double x = random.nextInt(GAME_WIDTH ~/ GAME_SCALE).toDouble();
         double y = random.nextInt(GAME_HEIGHT ~/ GAME_SCALE).toDouble();
         double w = random.nextInt(10).toDouble() / 10;
         double h = w*2.2;
         double v = (16.5/h);
         double col = 0.5 - (random.nextInt(2).toDouble() / 10.0).toDouble();
         Rain rain = new Rain(i, new Vector2(x, y), new Sprite(x, y, w, h, 0.0,v, col, col, 0.7, 0.4, false));
         sprites.addSprite(rain.getSprite());
         objects.add(rain);
       }
       
       for (int i =0; i < 100; i++) {
         double x = random.nextInt(GAME_WIDTH ~/ GAME_SCALE).toDouble();
         double y = random.nextInt(GAME_HEIGHT ~/ GAME_SCALE).toDouble();
         double w = 1.0;
         double h = w;
         double v = (16.5/h);
         Star star = new Star(i, new Vector2(x, y), new Sprite(x, y, w, h, 0.0, v, 1.0, 1.0, 1.0, (random.nextInt(10)/10).toDouble(), false));
         starSprites.addSprite(star.getSprite());
         objects.add(star);
       }    
       
  }
  
  // Switch the scenes around
  Vector2 activeCoord = new Vector2(0.0, 0.0);
  Vector2 moveToCoord = new Vector2(0.0, 0.0);
 
  void sceneHandler() {
    if (moveToCoord.x < 0.0) {
      moveToCoord.x = 0.0;
    } else if (moveToCoord.x >= (Game.instance.activeLevel.w * 16.0) - (GAME_WIDTH / GAME_SCALE)) {
      moveToCoord.x = (Game.instance.activeLevel.w * 16.0) - (GAME_WIDTH / GAME_SCALE);
    }
    
    if (moveToCoord.y < 0.0) {
      moveToCoord.y = 0.0;
    } else if (moveToCoord.y >= (Game.instance.activeLevel.h * 16.0) - (GAME_HEIGHT/GAME_SCALE)) {
      moveToCoord.y = (Game.instance.activeLevel.h * 16.0) - (GAME_HEIGHT/GAME_SCALE);
    }
    
    levelMatrix = camMatrix.clone().translate(0.0- moveToCoord.x, 0.0 - moveToCoord.y, 0.0);
    activeCoord.x = moveToCoord.x;
    activeCoord.y = moveToCoord.y;
  }
  
  void render(double time, double delta) {
    sceneHandler();
    bg.render(bgMatrix, time);
    starSprites.render(starsMatrix, time);
    moonSprites.render(levelMatrix.clone().translate(sin(time * 0.00025) * 200, cos(time * 0.00025) * 200, 0.0), time);
    buildings.render(levelMatrix, time);
    Game.instance.activeLevel.render(levelMatrix, time);
    buildingsOverlay.render(levelMatrix, time);
    entities.render(levelMatrix, time);
    for (Entity e in entityObjects) {
      e.render(delta, time);
    }
    sprites.render(skyMatrix, time);
    for(BlankObject o in objects) {
      o.render(time);
    }

    gui.render(time, skyMatrix);
  }
}

class CastleLevel extends GameLevel {
  Sprites castleWall, castleRail, mountains, castleDoor, castleDoorBG;
  Matrix4 treesMatrix, mountainMatrix, castleDoorMatrix;
  int wave = 0;
  int playerHealth = 0;
  int pointsNeededToAdvance = 0;
  CastleLevel(this.wave, this.playerHealth)  : super("levels/2.lvl") { 
    start();
    player.setHealth(playerHealth);
  }
  
  void reinit() {
    AudioController.play("level_up", 5000);
    int playerKills = player.totalKills;
    int playerHealth = player.health;
    entityObjects.clear();
    entities = new Sprites(testShader, entitySheet.texture);
    wave += 1;
    int enemies = 0;
    for (int i = 0; i < wave * (2 + random.nextInt(5));i++) {
       int x = random.nextInt((Game.instance.activeLevel.w * 16) + 150) - 150;
       Villager v = new Villager(i, new Vector2(x+0.0, 160.0), 16, 32, new Sprite(x+0.0,  160.0, 16.0, 32.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));
       entities.addSprite(v.getSprite());
       entities.addSprite(v.feetSprite);
       entityObjects.add(v);
       enemies ++;
    }
    pointsNeededToAdvance = (enemies * 0.6).floor();
    if (wave % 5 == 0) {
      playerHealth = player.maxHealth;
    }
    
    player = new Player(0, new Vector2(6.0 * 16.0, 160.0), 32, 32, new Sprite(6 * 16.0, 160.0, 32.0, 32.0, 0.0, 2.0, 1.0, 1.0, 1.0, 1.0, false), gui.gui);
    player.moveCamera();
    entityObjects.add(player);
    player.health = playerHealth;
    player.damage(0);
    player.totalKills = playerKills;
    entities.addSprite(player.getSprite());
    entities.addSprite(player.feetSprite);
  }
  
  void start() {
    super.start();
       Texture castleWallSheet = new Texture("tex/castleWall.png");
       Texture castleRailSheet = new Texture("tex/castleRail.png");
       Texture treeSheet = new Texture("tex/trees.png");
       Texture mountainSheet = new Texture("tex/mountains.png");
       Texture castleSheet = new Texture("tex/castleDoor.png");
       
     
       castleWall = new Sprites(testShader, castleWallSheet.texture);

       castleWall.addSprite(new Sprite(0.0, 0.0, 256.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));
       castleWall.addSprite(new Sprite(256.0, 0.0, 256.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));
       castleWall.addSprite(new Sprite((2 * 256.0), 0.0, 256.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));
       castleWall.addSprite(new Sprite((3 * 256.0), 0.0, 256.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));
       castleWall.addSprite(new Sprite((4 * 256.0), 0.0, 256.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));
       
       
       castleRail = new Sprites(testShader, castleRailSheet.texture);
       castleRail.addSprite(new Sprite((8.0 * 16.0) + 4.0, 0.0, 256.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));
       castleRail.addSprite(new Sprite((8.0 * 16.0) + 4.0 + 256.0, 0.0, 256.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));
       castleRail.addSprite(new Sprite((8.0 * 16.0) + 4.0 + (2 * 256.0), 0.0, 256.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));
       castleRail.addSprite(new Sprite((8.0 * 16.0) + 4.0 + (3 * 256.0), 0.0, 256.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));

       treesMatrix = camMatrix.clone();
       mountainMatrix = camMatrix.clone(); 
       
       mountains = new Sprites(testShader, mountainSheet.texture);
       mountains.addSprite(new Sprite(-256.0, 0.0, 256.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));
       mountains.addSprite(new Sprite(0.0, 0.0, 256.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));
       mountains.addSprite(new Sprite(256.0, 0.0, 256.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));

       trees = new Sprites(testShader, treeSheet.texture);
       trees.addSprite(new Sprite(-256.0, 0.0, 256.0, 256.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false));
       trees.addSprite(new Sprite(0.0, 0.0, 256.0, 256.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false));
       trees.addSprite(new Sprite(256.0, 0.0, 256.0, 256.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false));
       

       castleDoorBG = new Sprites(testShader, castleSheet.texture);
       castleDoor = new Sprites(testShader, castleSheet.texture);
       castleDoorBG.addSprite(new Sprite(4.0 * 16.0, 0.0, 12.0 * 16.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, true));
       castleDoor.addSprite(new Sprite(0.0, 0.0, 4.0 * 16.0, 256.0, 3.0, 0.0, 1.0, 1.0, 1.0, 1.0, true));    
       
       castleDoorBG.addSprite(new Sprite((Game.instance.activeLevel.w * 16.0 * 2) + (4.0 * 16.0) + 8.0 , 0.0, 12.0 * 16.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));
       castleDoor.addSprite(new Sprite((Game.instance.activeLevel.w * 16.0 * 2) + 12.0 * 16.0 + (4.0 * 16.0) + 8.0, 0.0, 4.0 * 16.0, 256.0, 3.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));    

    reinit();
  }
  
  void render(double time, double delta) {
    if (player.pos.x <=  2.0 * 16.0) {
         Game.instance.level = new MenuLevel(true);
   } else if (player.pos.x >= ((Game.instance.activeLevel.w - 3 )* 16.0) && player.killsRound >= pointsNeededToAdvance) {
      reinit();
    }
    sceneHandler();
       bg.render(bgMatrix, time);
       starSprites.render(starsMatrix, time);
       moonSprites.render(levelMatrix.clone().translate(sin(time * 0.00025) * 200, cos(time * 0.00025) * 200, 0.0), time);
       mountains.render(mountainMatrix.clone().translate(0.0 - (player.pos.x - ((GAME_WIDTH ~/ GAME_SCALE)/2)).floorToDouble() / 50.0, 0.0, 0.0), time);
       trees.render(treesMatrix.clone().translate(0.0 - (player.pos.x - ((GAME_WIDTH ~/ GAME_SCALE)/2)).floorToDouble() / 10.0, 0.0, 0.0), time);
       castleWall.render(levelMatrix, time);
       buildings.render(levelMatrix, time);
       Game.instance.activeLevel.render(levelMatrix, time);
       castleDoorBG.render(levelMatrix, time);

       buildingsOverlay.render(levelMatrix, time);
       entities.render(levelMatrix, time);
       castleRail.render(levelMatrix, time);
       for (Entity e in entityObjects) {
         e.render(delta, time);
       }
       sprites.render(skyMatrix, time);
       for(BlankObject o in objects) {
         o.render(time);
       }
       castleDoor.render(levelMatrix, time);

       gui.render(time, skyMatrix);
  }
}

class MenuLevel extends GameLevel{
  Sprites  mountains, castleDoorBG, castleDoor;
  Matrix4 treesMatrix, mountainMatrix, castleDoorMatrix;
  MenuLevel(bool _start) : super("levels/1.lvl") { 
    if (_start) { start(); }
  }
  
  void start() {
       Texture treeSheet = new Texture("tex/trees.png");
       Texture mountainSheet = new Texture("tex/mountains.png");
       Texture castleSheet = new Texture("tex/castleDoor.png");
       super.start();
       
       treesMatrix = camMatrix.clone();
       mountainMatrix = camMatrix.clone(); 
       
       mountains = new Sprites(testShader, mountainSheet.texture);
       mountains.addSprite(new Sprite(-256.0, 0.0, 256.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));
       mountains.addSprite(new Sprite(0.0, 0.0, 256.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));
       mountains.addSprite(new Sprite(256.0, 0.0, 256.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));

       trees = new Sprites(testShader, treeSheet.texture);
       trees.addSprite(new Sprite(-256.0, 0.0, 256.0, 256.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false));
       trees.addSprite(new Sprite(0.0, 0.0, 256.0, 256.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false));
       trees.addSprite(new Sprite(256.0, 0.0, 256.0, 256.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false));
       
       castleDoorBG = new Sprites(testShader, castleSheet.texture);
       castleDoor = new Sprites(testShader, castleSheet.texture);
       castleDoorBG.addSprite(new Sprite((15.0 * 16.0) + 0.0, 0.0, 12.0 * 16.0, 256.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));
       castleDoor.addSprite(new Sprite((15.0 * 16.0) + 12.0 * 16.0, 0.0, 4.0 * 16.0, 256.0, 3.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));    

       buildings.addSprite(new Sprite(4.0 * 16.0, 8.0 * 16.0, 6.0 * 16.0, 4 * 16.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, false));
       buildings.addSprite(new Sprite(12.0 * 16.0, 8.0 * 16.0 - 5.0, 8.0 * 16.0, 4 * 16.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, false));
       
       AnimatedObject campfire = new AnimatedObject(0, new Vector2(5.0 * 16.0 - 5.0, 10.0 * 16.0  - 2.0), new Sprite(4.0 * 16.0, (10.0 * 16.0) - 4.0, 32.0, 32.0, 0.0, 4.0, 1.0, 1.0, 1.0, 1.0, false), new Int16List.fromList([4 * 8 + 0, 4 * 8 + 1, 4 * 8 + 2, 4 * 8 + 3]), 100);
       objects.add(campfire);
       buildingsOverlay.addSprite(campfire.getSprite());
  }
  
  
  void render(double time, double delta) {
    if (player.pos.x >= ((Game.instance.activeLevel.w - 3 )* 16.0) ) {
      Game.instance.level = new CastleLevel(1, player.health);
    }
    
    sceneHandler();
    bg.render(bgMatrix, time);
    starSprites.render(starsMatrix, time);
    moonSprites.render(levelMatrix.clone().translate(sin(time * 0.00025) * 200, cos(time * 0.00025) * 200, 0.0), time);
    mountains.render(mountainMatrix.clone().translate(0.0 - (player.pos.x - ((GAME_WIDTH ~/ GAME_SCALE)/2)).floorToDouble() / 50.0, 0.0, 0.0), time);
    trees.render(treesMatrix.clone().translate(0.0 - (player.pos.x - ((GAME_WIDTH ~/ GAME_SCALE)/2)).floorToDouble() / 10.0, 0.0, 0.0), time);
    buildings.render(levelMatrix, time);
    Game.instance.activeLevel.render(levelMatrix, time);
    castleDoorBG.render(levelMatrix, time);
    buildingsOverlay.render(levelMatrix, time);
    entities.render(levelMatrix, time);
    for (Entity e in entityObjects) {
      e.render(delta, time);
    }
    sprites.render(skyMatrix, time);
    for(BlankObject o in objects) {
      o.render(time);
    }
    castleDoor.render(levelMatrix, time);

    gui.render(time, skyMatrix);
  }
}

