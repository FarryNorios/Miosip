import "dart:async";
import "dart:math";
import "package:flutter/material.dart";
import "package:just_audio/just_audio.dart";
import "package:audio_service/audio_service.dart";
import "data_manager.dart";

class MusicPlayer {
  AudioPlayer player = AudioPlayer();
  late AudioHandler audioHandler;
  List<Music> musicList = [];
  int sortMode = 1;
  int playingMode = 1;
  List<int> playingOrder = [];
  int? playingIndex;

  int? currentMusicIndex;
  String? currentMusicTitle;
  String? currentMusicArtist;
  Duration? currentDuration;
  Duration? currentPosition;
  PlayerState? currentState;

  bool canPlay = true;
  bool isSeeking = false;

  final StreamController<List<Music>> musicListController =
      StreamController<List<Music>>.broadcast();

  final StreamController<int> indexController = StreamController<int>.broadcast();
  final StreamController<PlayerState> stateController = StreamController<PlayerState>.broadcast();
  final StreamController<Duration> durationController = StreamController<Duration>.broadcast();
  final StreamController<Duration> positionController = StreamController<Duration>.broadcast();
  final StreamController<PlaybackEvent> playbackEventController =
      StreamController<PlaybackEvent>.broadcast();

  Stream<List<Music>> get musicListStream => musicListController.stream;

  Stream<int> get indexStream => indexController.stream;
  Stream<PlayerState> get playerStateStream => stateController.stream;
  Stream<Duration> get durationStream => durationController.stream;
  Stream<Duration> get positionStream => positionController.stream;
  Stream<PlaybackEvent> get playbackEventStream => playbackEventController.stream;

  StreamSubscription? stateSubscription;
  StreamSubscription? durationScription;
  StreamSubscription? positionScription;
  StreamSubscription? playbackEventScription;

  MusicPlayer() {
    (() async {
      musicList = await loadMusicList();
      musicListController.add(musicList);
      sortMode = await loadSortMode();
      playingMode = await loadPlayingMode();
      musicList = sortMusicList(handleMusicFiles(await scanMusicFiles(), musicList), sortMode);
      playingOrder = List.generate(musicList.length - 1, (index) => index);
      if (playingMode == 2) {
        playingOrder.shuffle();
      }
      musicListController.add(musicList);
      await saveMusicList(musicList);
    })();
  }

  Future<void> changeSortMode(int mode) async {
    sortMode = mode;
    List<Music> newMusicList = sortMusicList(musicList, sortMode);
    if (currentMusicIndex != null) {
      currentMusicIndex = newMusicList.indexWhere(
        (music) => music.path == musicList[currentMusicIndex!].path,
      );
      indexController.add(currentMusicIndex!);
    }
    musicList = newMusicList;
    playingOrder = List.generate(musicList.length - 1, (index) => index);
    if (playingMode == 2) {
      playingOrder.shuffle();
    }
    musicListController.add(musicList);
    await saveSortMode(sortMode);
    await saveMusicList(musicList);
  }

  Future<void> changePlayingMode(int playingMode) async {
    this.playingMode = playingMode;
    var newPlayingOrder = List.generate(musicList.length - 1, (index) => index);
    if (playingMode == 2) {
      newPlayingOrder.shuffle();
    }
    if (currentMusicIndex != null) {
      playingIndex = newPlayingOrder.indexOf(currentMusicIndex!);
    }
    playingOrder = newPlayingOrder;
    await savePlayingMode(playingMode);
  }

  Future<void> refreshMusicList() async {
    sortMode = await loadSortMode();
    List<Music> newMusicList = sortMusicList(
      handleMusicFiles(await scanMusicFiles(), musicList),
      sortMode,
    );
    if (currentMusicIndex != null) {
      currentMusicIndex = newMusicList.indexWhere(
        (music) => music.path == musicList[currentMusicIndex!].path,
      );
      indexController.add(currentMusicIndex!);
    }
    musicList = newMusicList;
    playingOrder = List.generate(musicList.length - 1, (i) => i);
    playingOrder.shuffle();
    musicListController.add(musicList);
    await saveMusicList(musicList);
  }

  Future<void> changeMusicInfo(int index, String? title, String? artist) async {
    if (title != null && title != "") {
      musicList[index].title = title;
    }
    if (artist != null) {
      musicList[index].artist = artist;
    }
    musicListController.add(musicList);
    if (index == currentMusicIndex) {
      currentMusicTitle = musicList[index].title;
      currentMusicArtist = musicList[index].artist;
      indexController.add(index);
    }
    await saveMusicList(musicList);
  }

  void dispose() {
    player.dispose();

    musicListController.close();

    indexController.close();
    stateController.close();
    durationController.close();
    positionController.close();
    playbackEventController.close();

    stateSubscription?.cancel();
    durationScription?.cancel();
    positionScription?.cancel();
    playbackEventScription?.cancel();
  }

  Future<void> playerInit() async {
    await stateSubscription?.cancel();
    await durationScription?.cancel();
    await positionScription?.cancel();
    await playbackEventScription?.cancel();
    await player.stop();
    await player.dispose();
    player = AudioPlayer();
  }

  Future<void> initAudioHandler() async {
    print("initAudioHandler");
    audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(this),
      config: AudioServiceConfig(
        androidNotificationChannelId: "com.fapif.miosip.channel.audio",
        androidNotificationChannelName: "音乐播放",
      ),
    );
  }

  Future<void> playMusic(int index) async {
    if (!canPlay) return;
    canPlay = false;
    await playerInit();
    print("播放音乐: ${musicList[index].title}");

    currentMusicIndex = index;
    currentMusicTitle = musicList[index].title;
    currentMusicArtist = musicList[index].artist;
    indexController.add(index);

    playingIndex = playingOrder.indexOf(index);

    try {
      await player.setAudioSource(AudioSource.uri(Uri.file(musicList[index].path)));
    } catch (e) {
      canPlay = true;
      return;
    }

    currentDuration = player.duration;

    stateSubscription = player.playerStateStream.listen((data) {
      addState(data);
      if (data.processingState == ProcessingState.completed) {
        playNext();
      }
    });
    durationScription = player.durationStream.cast<Duration>().listen((data) {
      currentDuration = data;
      durationController.add(data);
    });
    positionScription = player.positionStream.cast<Duration>().listen((data) {
      if (isSeeking) return;
      currentPosition = data;
      positionController.add(data);
    });
    playbackEventScription = player.playbackEventStream.listen((data) {
      if (isSeeking) return;
      playbackEventController.add(data);
    });

    canPlay = true;

    try {
      await player.play();
    } catch (e) {
      return;
    }
  }

  void addState(PlayerState data) {
    currentState = data;
    stateController.add(data);
  }

  Future<void> playNext() async {
    if (currentMusicIndex == null || playingIndex == null || canPlay == false) {
      return;
    }
    if (playingIndex == playingOrder.length - 1) {
      await playMusic(playingOrder[0]);
    } else {
      await playMusic(playingOrder[playingIndex! + 1]);
    }
  }

  Future<void> playPrevious() async {
    if (currentMusicIndex == null || playingIndex == null || canPlay == false) {
      return;
    }
    switch (playingMode) {
      case 1:
        if (currentMusicIndex == 0) {
          await playMusic(musicList.length - 1);
        } else {
          await playMusic(currentMusicIndex! - 1);
        }
        break;
      case 2:
        if (playingIndex == 0) {
          await playMusic(playingOrder[playingOrder.length - 1]);
        } else {
          await playMusic(playingOrder[playingIndex! - 1]);
        }
        break;
    }
  }

  Future<void> play() async {
    await player.play();
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> resume() async {
    await player.play();
  }

  Future<void> stop() async {
    await player.stop();
  }

  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  void setMusicList(List<Music> musicList) {
    this.musicList = musicList;
  }
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  late final MusicPlayer musicPlayer;
  String? currentId;
  String? currentTitle;
  String? currentArtist;
  Duration? currentDuration;

  MyAudioHandler(this.musicPlayer) {
    musicPlayer.playbackEventStream.listen((data) {
      if (musicPlayer.isSeeking) {
        return;
      }
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            musicPlayer.currentState!.playing ? MediaControl.pause : MediaControl.play,
            MediaControl.skipToNext,
          ],
          systemActions: const {MediaAction.seek},
          androidCompactActionIndices: const [0, 1, 3],
          processingState:
              const {
                ProcessingState.idle: AudioProcessingState.idle,
                ProcessingState.loading: AudioProcessingState.loading,
                ProcessingState.buffering: AudioProcessingState.buffering,
                ProcessingState.ready: AudioProcessingState.ready,
                ProcessingState.completed: AudioProcessingState.completed,
              }[musicPlayer.currentState!.processingState]!,
          playing: musicPlayer.currentState!.playing,
        ),
      );
    });
    musicPlayer.indexStream.listen((data) {
      currentId = musicPlayer.musicList[data].path;
      currentTitle = musicPlayer.musicList[data].title;
      currentArtist = musicPlayer.musicList[data].artist;
      setMediaItem();
    });
    musicPlayer.durationStream.listen((data) {
      currentDuration = data;
      setMediaItem();
    });
    musicPlayer.positionStream.listen((data) {
      if (musicPlayer.isSeeking) return;
      playbackState.add(playbackState.value.copyWith(updatePosition: data));
    });
  }

  void setMediaItem() {
    mediaItem.add(
      MediaItem(
        id: currentId ?? "",
        title: currentTitle ?? "",
        artist: currentArtist ?? "",
        duration: currentDuration ?? Duration.zero,
      ),
    );
  }

  Future<void> playMusic(MediaItem mediaItem) async {}
  @override
  Future<void> play() async {
    musicPlayer.addState(PlayerState(true, musicPlayer.currentState!.processingState));
    musicPlayer.playbackEventController.add(
      PlaybackEvent(processingState: musicPlayer.currentState!.processingState),
    );
    await musicPlayer.play();
  }

  @override
  Future<void> pause() async {
    musicPlayer.addState(PlayerState(false, musicPlayer.currentState!.processingState));
    musicPlayer.playbackEventController.add(
      PlaybackEvent(processingState: musicPlayer.currentState!.processingState),
    );
    await musicPlayer.pause();
  }

  @override
  Future<void> skipToNext() => musicPlayer.playNext();
  @override
  Future<void> skipToPrevious() => musicPlayer.playPrevious();
  @override
  Future<void> seek(Duration position) async {
    if (musicPlayer.isSeeking) return;
    musicPlayer.isSeeking = true;
    playbackState.add(playbackState.value.copyWith(updatePosition: position));
    await musicPlayer.seek(position);
    musicPlayer.isSeeking = false;
  }
}
