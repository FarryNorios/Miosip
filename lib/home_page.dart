import "dart:async";

import "package:flutter/material.dart";
import "package:miosip/main.dart";

import "data_manager.dart";
import "settings_page.dart";
import "player_bar.dart";
import "music_player.dart";
import "AutoScrollText.dart";

class HomePage extends StatefulWidget {
  final MusicPlayer musicPlayer;

  const HomePage({super.key, required this.musicPlayer});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with RouteAware {
  List<Music> musicList = [];

  int sortMode = 1;

  int? currentMusicIndex;
  String? currentMusicTitle;
  //String? currentMusicPath;

  late StreamSubscription indexSubscription;

  @override
  void initState() {
    super.initState();
    (() async {
      // await player.initAudioHandler();
      //先获取权限
      requestPermission();
      //读取已经保存的列表信息
      musicList = await loadMusicList();
      setState(() {});
      sortMode = await loadSortMode();
      //扫描音乐文件并排序，给出新列表
      musicList = sortMusicList(await scanMusicFiles(), sortMode);
      musicPlayer.setMusicList(musicList);
      setState(() {});
      await saveMusicList(musicList);
    })();
    indexSubscription = musicPlayer.currentIndexStream.listen((index) {
      if (currentMusicIndex != index) {
        setState(() {
          currentMusicIndex = index;
          currentMusicTitle = musicList[index].title;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //订阅路由变化
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    (() async {
      sortMode == await loadSortMode();
      musicList = sortMusicList(await scanMusicFiles(), sortMode);
      musicPlayer.setMusicList(musicList);
      setState(() {});
      await saveMusicList(musicList);
    })();
  }

  @override
  void dispose() {
    //取消订阅路由变化
    routeObserver.unsubscribe(this);
    musicPlayer.dispose();
    indexSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(width: 10),
            Image.asset("assets/logo.png", fit: BoxFit.contain, height: 50),
            SizedBox(width: 5),
            Text(
              "Miosip",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ],
        ),

        actions: [
          PopupMenuButton(
            icon: Icon(Icons.keyboard_control, size: 30),

            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem(
                    value: "settings",
                    child: Row(
                      children: [
                        Icon(Icons.settings_rounded),
                        SizedBox(width: 10),
                        Text("设置"),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value: "refresh",
                    child: Row(
                      children: [
                        //icon有点偏上了，没和字对齐
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(Icons.replay_circle_filled_rounded),
                        ),
                        SizedBox(width: 10),
                        Text("刷新"),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value: "sort",
                    child: Row(
                      children: [
                        Icon(Icons.sort_rounded),
                        SizedBox(width: 10),
                        Text("排序"),
                      ],
                    ),
                  ),
                ],

            onSelected: (String value) {
              switch (value) {
                case "settings":
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                  break;
                case "refresh":
                  (() async {
                    sortMode == await loadSortMode();
                    musicList = sortMusicList(await scanMusicFiles(), sortMode);
                    musicPlayer.setMusicList(musicList);
                    setState(() {});
                    await saveMusicList(musicList);
                  })();
                  break;
                case "sort":
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 15,
                              ),
                              child: Text(
                                "排序方式",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            ListTile(
                              title: Text(
                                "按名称排序(先英后中)",
                                textAlign: TextAlign.center,
                              ),
                              onTap: () async {
                                sortMode = 1;
                                musicList = sortMusicList(musicList, sortMode);
                                musicPlayer.setMusicList(musicList);
                                setState(() {});
                                Navigator.pop(context); // 关闭弹窗
                                await saveSortMode(1);
                              },
                            ),
                            ListTile(
                              title: Text(
                                "按名称排序(先中后英)",
                                textAlign: TextAlign.center,
                              ),
                              onTap: () async {
                                sortMode = 2;
                                musicList = sortMusicList(musicList, sortMode);
                                musicPlayer.setMusicList(musicList);
                                setState(() {});
                                Navigator.pop(context);
                                await saveSortMode(2);
                              },
                            ),
                            // ListTile(
                            //   title: Text(
                            //     "按名称排序(中英混合)",
                            //     textAlign: TextAlign.center,
                            //   ),
                            //   onTap: () {
                            //     Navigator.pop(context);
                            //   },
                            // ),
                            ListTile(
                              title: Text(
                                "取 消",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                  break;
              }
            },
          ),
        ],

        //backgroundColor: const Color.fromARGB(255, 241, 249, 255),
      ),

      body: ListView.separated(
        itemCount: musicList.length,

        // padding: const EdgeInsets.only(bottom: 25),

        //分界线
        separatorBuilder:
            (context, index) => Divider(
              height: 1,
              thickness: 1,
              indent: 5,
              endIndent: 5,
              color: const Color.fromARGB(255, 245, 245, 245),
            ),

        itemBuilder: (context, index) {
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 15),
            tileColor:
                (currentMusicIndex == index)
                    ? const Color.fromARGB(255, 245, 245, 245)
                    : Colors.white,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.asset(
                "assets/NoMusicCover-ldpi.png",
                width: 50,
                fit: BoxFit.contain,
              ),
            ),
            title: Text(musicList[index].title, style: TextStyle(fontSize: 16), 
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              "Unknown",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            horizontalTitleGap: 10,
            onTap: () {
              setState(() {
                currentMusicIndex = index;
                currentMusicTitle = musicList[index].title;
              });
              musicPlayer.playMusic(index);
            },
          );
        },
      ),
      bottomNavigationBar: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenPlayer(player: musicPlayer),
            ),
          );
        },
        child: PlayerBar(player: musicPlayer),
      ),
    );
  }
}

class FullScreenPlayer extends StatefulWidget {
  final MusicPlayer player;

  const FullScreenPlayer({super.key, required this.player});

  @override
  State<FullScreenPlayer> createState() => FullScreenPlayerState();
}

class FullScreenPlayerState extends State<FullScreenPlayer> {
  late MusicPlayer player;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  Duration tempPosition = Duration.zero;
  bool isDragging = false;
  bool? isPlaying;
  String? title;

  late StreamSubscription indexSubscription;
  late StreamSubscription stateSubscription;
  late StreamSubscription durationSubscription;
  late StreamSubscription positionSubscription;

  @override
  void initState() {
    super.initState();
    player = widget.player;

    duration = player.currentDuration ?? Duration.zero;
    position = player.currentPosition ?? Duration.zero;

    indexSubscription = player.currentIndexStream.listen((data) {
      setState(() {
        title = player.currentMusicTitle;
      });
    });
    stateSubscription = player.playerStateStream.listen((data) {
      setState(() {
        isPlaying = data.playing;
      });
    });
    durationSubscription = player.durationStream.listen((data) {
      if (duration != data) {
        setState(() {
          duration = data;
        });
      }
    });
    positionSubscription = player.positionStream.listen((data) {
      setState(() {
        position = data;
      });
    });
    if (duration == Duration.zero) {
      duration = player.currentDuration ?? Duration.zero;
    }
    isPlaying ??= player.currentState?.playing ?? false;
  }

  @override
  void dispose() {
    indexSubscription.cancel();
    stateSubscription.cancel();
    durationSubscription.cancel();
    positionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 10),
                child: IconButton(
                  icon: Icon(Icons.keyboard_arrow_down_rounded, size: 35),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ) 
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(height: 25),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      "assets/NoMusicCover.png",
                      fit: BoxFit.contain,
                      width: 300,
                    ),
                  ),
                  SizedBox(height: 50),
                  Column(
                    children: [
                      SizedBox(
                        width: 300,
                        height: 50,
                        child: AutoScrollText(
                          text: player.currentMusicTitle ?? "",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                          velocity: 30,
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        height: 50,
                        child: AutoScrollText(
                          text: "Unknown",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          velocity: 30,
                        ),
                      ),
                    ],
                  ),

                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 5,
                                thumbShape: RoundSliderThumbShape(
                                  enabledThumbRadius: 7,
                                ),
                                overlayShape: RoundSliderOverlayShape(
                                  overlayRadius: 15,
                                ),
                                thumbColor: const Color.fromARGB(
                                  255,
                                  85,
                                  85,
                                  85,
                                ),
                                activeTrackColor: const Color.fromARGB(
                                  255,
                                  85,
                                  85,
                                  85,
                                ),
                                inactiveTrackColor: Colors.grey[300],
                                overlayColor: const Color.fromARGB(
                                  50,
                                  85,
                                  85,
                                  85,
                                ),
                                showValueIndicator:
                                    ShowValueIndicator.always, // 显示当前值标签
                                valueIndicatorTextStyle: TextStyle(
                                  color: const Color.fromARGB(255, 85, 85, 85),
                                ),
                              ),
                              child: Slider(
                                min: 0,
                                max: duration.inSeconds.toDouble(),
                                label:
                                    "${(isDragging ? tempPosition : position).inMinutes}:${((isDragging ? tempPosition : position).inSeconds % 60).toString().padLeft(2, '0')}",
                                value: (isDragging ? tempPosition : position)
                                    .inSeconds
                                    .toDouble()
                                    .clamp(0, duration.inSeconds.toDouble()),
                                onChanged: (value) {
                                  setState(() {
                                    isDragging = true;
                                    tempPosition = Duration(
                                      seconds: value.toInt(),
                                    );
                                  });
                                },
                                onChangeEnd: (value) {
                                  setState(() {
                                    isDragging = false;
                                  });
                                  player.seek(Duration(seconds: value.toInt()));
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}",
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  "${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}",
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.skip_previous_rounded,
                              color: const Color.fromARGB(255, 0, 0, 0),
                            ),
                            iconSize: 45,
                            onPressed: () {
                              player.playPrevious();
                            },
                          ),
                          SizedBox(width: 10),
                          IconButton(
                            icon: Icon(
                              isPlaying ?? false
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: const Color.fromARGB(255, 0, 0, 0),
                            ),
                            iconSize: 50,
                            onPressed: () {
                              if (isPlaying != null) {
                                if (isPlaying!) {
                                  player.pause();
                                } else {
                                  player.play();
                                }
                              }
                            },
                          ),
                          SizedBox(width: 10),
                          IconButton(
                            icon: Icon(
                              Icons.skip_next_rounded,
                              color: const Color.fromARGB(255, 0, 0, 0),
                            ),
                            iconSize: 45,
                            onPressed: () {
                              player.playNext();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
