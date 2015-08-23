part of ld33;

class Leaderboard {
    static String private_key = "lNyebd7JHUSo7NU4khm7VAKTji4IdE3kaTuMvkVA3vhg";
    static String public_key = "55da29386e51b61518afb7b8";
    
    static void insert(String name, int time, int wave) {
      var req = new HttpRequest();
      String url = "http://dreamlo.com/lb/${private_key}/add/${name.replaceAll("*", "")}/${wave}/${time}";
      req.open("get", url);
      req.send("");
    }
    

    static Future<String> getData() {
      return loadString("http://dreamlo.com/lb/${public_key}/pipe");
    }
    static Future<String> loadString(String url) {
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
   
}