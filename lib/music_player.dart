import "dart:async";

import "package:flutter/material.dart";
import "package:just_audio/just_audio.dart";
import "package:audio_service/audio_service.dart";
import "data_manager.dart";

class MusicPlayer {
  AudioPlayer player = AudioPlayer();
  late AudioHandler audioHandler;
  List<Music> musicList = [];

  int? currentIndex;
  String? currentMusicTitle;
  Duration? currentDuration;
  Duration? currentPosition;
  PlayerState? currentState;

  bool canPlay = true;

  final StreamController<int> currentIndexController =
      StreamController<int>.broadcast();
  final StreamController<PlayerState> stateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<Duration> durationController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> positionController =
      StreamController<Duration>.broadcast();
  final StreamController<PlaybackEvent> playbackEventController =
      StreamController<PlaybackEvent>.broadcast();

  Stream<int> get currentIndexStream => currentIndexController.stream;

  Stream<PlayerState> get playerStateStream => stateController.stream;
  Stream<Duration> get durationStream => durationController.stream;
  Stream<Duration> get positionStream => positionController.stream;
  Stream<PlaybackEvent> get playbackEventStream =>
      playbackEventController.stream;

  StreamSubscription? stateSubscription;
  StreamSubscription? durationScription;
  StreamSubscription? positionScription;
  StreamSubscription? playbackEventScription;

  void dispose() {
    player.dispose();
    currentIndexController.close();
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
        androidNotificationOngoing: true, // 常驻通知
        androidStopForegroundOnPause: true, // 必须与ongoing配对
        androidShowNotificationBadge: true, // 显示角标
        notificationColor: Colors.blue,
      ),
    );
  }

  Future<void> playMusic(int index) async {
    canPlay = false;
    await playerInit();
    print("播放音乐: ${musicList[index].title}");

    currentIndex = index;
    currentMusicTitle = musicList[index].title;
    currentIndexController.add(index);

    try {
      await player.setAudioSource(
        AudioSource.uri(Uri.file(musicList[index].path)),
      );
    } catch (e) {}

    currentDuration = player.duration;

    stateSubscription = player.playerStateStream.listen((data) {
      currentState = data;
      if (data.processingState == ProcessingState.completed) {
        playNext();
      }
      stateController.add(data);
    });
    durationScription = player.durationStream.cast<Duration>().listen((data) {
      currentDuration = data;
      durationController.add(data);
    });
    positionScription = player.positionStream.cast<Duration>().listen((data) {
      currentPosition = data;
      positionController.add(data);
    });
    playbackEventScription = player.playbackEventStream.listen((data) {
      playbackEventController.add(data);
    });

    canPlay = true;

    try {
      await player.play();
    } catch (e) {}
  }

  Future<void> playNext() async {
    if (currentIndex == null || canPlay == false) {
      return;
    }
    if (currentIndex == musicList.length - 1) {
      await playMusic(0);
    } else {
      await playMusic(currentIndex! + 1);
    }
  }

  Future<void> playPrevious() async {
    if (currentIndex == null || canPlay == false) {
      return;
    }
    if (currentIndex == 0) {
      await playMusic(musicList.length - 1);
    } else {
      await playMusic(currentIndex! - 1);
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
  Duration? currentDuration;

  bool isSeeking = false;

  MyAudioHandler(this.musicPlayer) {
    musicPlayer.playbackEventStream.listen((data) {
      if (isSeeking) {
        return;
      }
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            musicPlayer.currentState!.playing
                ? MediaControl.pause
                : MediaControl.play,
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
    musicPlayer.currentIndexStream.listen((data) {
      currentId = musicPlayer.musicList[data].path;
      currentTitle = musicPlayer.musicList[data].title;
      setMediaItem();
    });
    musicPlayer.durationStream.listen((data) {
      currentDuration = data;
      setMediaItem();
    });
    musicPlayer.positionStream.listen((data) {
      playbackState.add(playbackState.value.copyWith(updatePosition: data));
    });
  }

  void setMediaItem() {
    mediaItem.add(
      MediaItem(
        id: currentId ?? "",
        title: currentTitle ?? "",
        artist: "Unknown",
        duration: currentDuration ?? Duration.zero,
      ),
    );
  }

  Future<void> playMusic(MediaItem mediaItem) async {}
  @override
  Future<void> play() => musicPlayer.play();
  @override
  Future<void> pause() => musicPlayer.pause();
  @override
  Future<void> skipToNext() => musicPlayer.playNext();
  @override
  Future<void> skipToPrevious() => musicPlayer.playPrevious();
  @override
  Future<void> seek(Duration position) async {
    isSeeking = true;
    playbackState.add(
      playbackState.value.copyWith(
        updatePosition: position
      ),
    );
    await musicPlayer.seek(position);
    isSeeking = false;
  }
}
