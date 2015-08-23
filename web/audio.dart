part of ld33;

typedef void onLoadCallback(List<AudioBuffer> bufferList);


class BufferLoader {
  AudioContext audioContext;
  List<String> urlList;
  onLoadCallback callback;
  int _loadCount = 0;
  List<AudioBuffer> _bufferList;
  
  BufferLoader(this.audioContext, this.urlList, this.callback) {
    _bufferList = new List<AudioBuffer>(urlList.length);
  }
  
  void load() {
    for (int i =0; i < urlList.length;i++) {
      _loadBuffer(urlList[i], i);
    }
  }
  
  void _loadBuffer(String url, int index) {
    var request = new HttpRequest();
    request.open("GET", url, async: true);
    request.responseType = "arraybuffer";
    request.onLoad.listen((e) => _onLoad(request, url, index));
    request.send();
  }
  
  void _onLoad(HttpRequest request, String url, int index) {
    audioContext.decodeAudioData(request.response).then((AudioBuffer buffer) {
      if (buffer == null) {
        return;
      }
      _bufferList[index] = buffer;
      if (++_loadCount == urlList.length) callback(_bufferList);
    });
  }
}

class Audio {
  Map<String, AudioBuffer> buffers;
  AudioContext audioContext;
  
  static const buffersToLoad = const {
    "thunder"    : "sounds/thunder.wav", 
    "rain"       : "sounds/rain.wav",    
    "hurt"       : "sounds/hurt.wav",
    "enemy_hurt" : "sounds/enemy_hurt.wav",
    "level_up"   : "sounds/levelup.wav"
  };
  
  Audio() {
    buffers = new Map<String, AudioBuffer>();
    audioContext = new AudioContext();
    _load();
  }
  
  void _load() {
    List<String> names = buffersToLoad.keys.toList();
    List<String> paths = buffersToLoad.values.toList();
    var bufferLoader = new BufferLoader(audioContext, paths, (List<AudioBuffer> bufferList){
      for (int i =0; i < bufferList.length;i++) {
        AudioBuffer buffer = bufferList[i];
        String name = names[i];
        buffers[name] = buffer;
      }
    });
    bufferLoader.load();
  }
}

class AudioController {
  
  static Map<String, AudioBufferSourceNode> audioActive = new Map<String, AudioBufferSourceNode>();
  
  static void playLoop(String name, bool loop, int volume) {
    AudioBufferSourceNode source = audio.audioContext.createBufferSource();
    if (name != null && source != null && audio != null && audio.buffers != null) {
      source.buffer = audio.buffers[name];
      if (source.buffer != null) {
        BiquadFilterNode filter = audio.audioContext.createBiquadFilter();
        filter.type = "lowpass";
        filter.frequency.value = volume;
        
        source.connectNode(filter, 0, 0);
        filter.connectNode(audio.audioContext.destination, 0, 0);
        
        source.start(0);
        if (loop) {
          source.loop = true;
          audioActive[name] = source;
        }
      }
    }
  }
  
  static void play(String name, int volume) {
    playLoop(name, false, volume);
  }
  
  static void stopAll() {
    for (String name in audioActive.keys) {
      audioActive[name].stop(0);
    }
  }
}