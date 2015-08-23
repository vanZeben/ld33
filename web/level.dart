part of ld33;

class Levels {
  static List<Level> _allLevels = new List<Level>();
  static Future loadAndInit() {
    List<Future> allFutures = new List<Future>();
    _allLevels.forEach((e) { allFutures.add(e.loadData()); });
    return Future.wait(allFutures);
  }
  
  static Level get(String path) {
    for (Level level in _allLevels) {
      if (level.path == path) {
        return level;
      }
    }
    return null;
  }
}

class Level {
  Int16List tileData;
  String path;
  Sprites spriteSheet;
  int w;
  int h;
  Vector4 tint;
  Level(this.path, this.spriteSheet, this.tint) {
    Levels._allLevels.add(this);
  }

  Future<String> loadString(String url) {
    Completer<String> completer = new Completer<String>();
    var req = new HttpRequest();
    req.open("get", url);
    req.onLoadEnd.first.then((e) {
      if (req.status~/100 == 2) {
        completer.complete(req.response as String);
      } else {
        completer.completeError("Can't load url ${url}. Response type ${req.status}");
      }
    });
    req.send("");
    return completer.future;
  }
  
  Future<Int16List> loadData() {
    Completer completer = new Completer();
    loadString(path).then((e) {
      var lineData = e.split("\n");
      h = lineData.length;
      w = lineData.first.split("|").length;
      tileData = new Int16List(w * h);
      int index = 0;
      lineData.forEach((nl) {
        nl.split("|").forEach((ee) {
          if (!ee.isEmpty) {
            ee = ee.substring(ee.indexOf("{")+1, ee.indexOf("}"));
            int xTile = int.parse(ee.split(",")[0]);
            int yTile = int.parse(ee.split(",")[1]);
            bool flipX = int.parse(ee.split(",")[2]) == 10 || (xTile == 1 && yTile == 1 && random.nextInt(10) > 4);
            int tileId = xTile + (yTile * 16);
            tileData.setAll(index, [tileId]);
            if (tileId >= 0) {
              spriteSheet.addSprite(new Sprite((index % w).floorToDouble() * 16.0, (index / w).floorToDouble() * 16.0, 16.0, 16.0, (tileId % 16).floorToDouble(), (tileId / 16).floorToDouble(), tint.x, tint.y, tint.z, tint.w, flipX));
            }
            index++;
          }
        });
      });
      completer.complete();
    });
    return completer.future;
  }
  
  int getTileAt(int x, int y) {
    if (x < 0 || y < 0 || x >= w || y >= h) { return 16; }
    int tileId = tileData.elementAt((y.abs() * w) + x.abs());
    if (tileId <= 16 && tileId > 32) {
      tileId = 0;
    }
    return tileId;
  }
  
  void render(Matrix4 mvMatrix, double time) {
    spriteSheet.render(mvMatrix, time);
  }
}

