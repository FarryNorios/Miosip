import "dart:async";

import "package:flutter/material.dart";
import "package:miosip/permission_manager.dart";
import "package:fluttertoast/fluttertoast.dart";

import "data_manager.dart";
import "settings_page.dart";
import "toolbox_page.dart";
import "player_bar.dart";
import "music_player.dart";
import "auto_scroll_text.dart";
import "online_manager.dart";

class HomePage extends StatefulWidget {
  final MusicPlayer musicPlayer;

  const HomePage({super.key, required this.musicPlayer});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with RouteAware, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // List<Music> musicList = [];

  // int sortMode = 1;

  late final MusicPlayer musicPlayer;

  int? currentMusicIndex;
  String? currentMusicTitle;
  //String? currentMusicPath;

  late StreamSubscription musicListSubscription;
  late StreamSubscription indexSubscription;

  @override
  void initState() {
    super.initState();
    musicPlayer = widget.musicPlayer;
    musicListSubscription = musicPlayer.musicListStream.listen((musicList) {
      setState(() {
        if (currentMusicIndex == null) {
          return;
        }
      });
    });
    indexSubscription = musicPlayer.indexStream.listen((index) {
      if (currentMusicIndex != index) {
        setState(() {
          currentMusicIndex = index;
          currentMusicTitle = musicPlayer.currentMusicTitle;
        });
      }
    });
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   //订阅路由变化
  //   routeObserver.subscribe(this, ModalRoute.of(context)!);
  // }

  @override
  void didPopNext() {
    // (() async {
    //   sortMode == await loadSortMode();
    //   musicList = sortMusicList(await scanMusicFiles(), sortMode);
    //   musicPlayer.setMusicList(musicList);
    //   setState(() {});
    //   await saveMusicList(musicList);
    // })();
  }

  @override
  void dispose() {
    // //取消订阅路由变化
    // routeObserver.unsubscribe(this);
    musicPlayer.dispose();
    musicListSubscription.cancel();
    indexSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(width: 10),
            Image.asset("assets/logo.png", fit: BoxFit.contain, height: 50),
            SizedBox(width: 5),
            Text("Miosip", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          ],
        ),

        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.keyboard_control, size: 30),
            menuPadding: EdgeInsets.zero,
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: "settings",
                    child: Row(
                      children: [Icon(Icons.settings_rounded), SizedBox(width: 10), Text("设置")],
                    ),
                  ),

                  PopupMenuItem(
                    value: "toolbox",
                    child: Row(
                      children: [
                        Icon(Icons.build_circle_rounded),
                        SizedBox(width: 10),
                        Text("工具箱"),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value: "sort",
                    child: Row(
                      children: [Icon(Icons.sort_rounded), SizedBox(width: 10), Text("排序")],
                    ),
                  ),

                  PopupMenuItem(
                    value: "refresh",
                    child: Row(
                      children: [
                        Icon(Icons.replay_circle_filled_rounded),
                        SizedBox(width: 10),
                        Text("刷新"),
                      ],
                    ),
                  ),
                ],

            onSelected: (value) {
              switch (value) {
                case "settings":
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
                  break;
                case "toolbox":
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ToolboxPage()));
                case "sort":
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 0, vertical: 15),
                              child: Text(
                                "排序方式",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                            ),
                            ListTile(
                              title: Text("按名称排序(先英后中)", textAlign: TextAlign.center),
                              onTap: () async {
                                musicPlayer.changeSortMode(1);
                                setState(() {});
                                Navigator.pop(context); // 关闭弹窗
                              },
                            ),
                            ListTile(
                              title: Text("按名称排序(先中后英)", textAlign: TextAlign.center),
                              onTap: () async {
                                musicPlayer.changeSortMode(2);
                                setState(() {});
                                Navigator.pop(context); // 关闭弹窗
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
                case "refresh":
                  (() async {
                    musicPlayer.refreshMusicList();
                    setState(() {});
                  })();
                  break;
              }
            },
          ),
          SizedBox(width: 10),
        ],

        //backgroundColor: const Color.fromARGB(255, 241, 249, 255),
      ),

      body: ListView.separated(
        itemCount: musicPlayer.musicList.length,

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
            contentPadding: EdgeInsets.only(left: 15, right: 10),
            tileColor:
                (currentMusicIndex == index)
                    ? const Color.fromARGB(255, 245, 245, 245)
                    : Colors.white,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.asset("assets/NoMusicCover-ldpi.png", width: 50, fit: BoxFit.contain),
            ),
            title: Text(
              musicPlayer.musicList[index].title,
              style: TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              musicPlayer.musicList[index].artist,
              style: TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
            horizontalTitleGap: 10,
            onTap: () {
              setState(() {
                currentMusicIndex = index;
                currentMusicTitle = musicPlayer.musicList[index].title;
              });
              (() async {
                await musicPlayer.playMusic(index);
              })();
            },
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, size: 20),
              menuPadding: EdgeInsets.zero,
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: "info",
                      child: Row(
                        children: [
                          Icon(Icons.info_rounded, size: 20),
                          SizedBox(width: 10),
                          Text("详情"),
                        ],
                      ),
                    ),
                  ],
              onSelected: (value) {
                switch (value) {
                  case "info":
                    showDialog(
                      context: context,
                      // barrierDismissible: false,  // 禁止点击对话框外部关闭
                      builder: (context) => MusicInfo(musicPlayer: musicPlayer, index: index),
                    );
                    break;
                }
              },
            ),
          );
        },
      ),
      bottomNavigationBar: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FullScreenPlayer(musicPlayer: musicPlayer)),
          );
        },
        child: PlayerBar(musicPlayer: musicPlayer),
      ),
    );
  }
}

class MusicInfo extends StatefulWidget {
  final MusicPlayer musicPlayer;
  final int index;

  const MusicInfo({super.key, required this.musicPlayer, required this.index});

  @override
  State<StatefulWidget> createState() => MusicInfoState();
}

class MusicInfoState extends State<MusicInfo> {
  late final MusicPlayer musicPlayer;

  TextEditingController artistEditingController = TextEditingController();

  String? newTitle;
  String? newArtist;
  int searchedArtistListIndex = 0;
  List<String> searchedArtistList = [];
  String? searchedArtist;

  int searchingStatus = 0;

  @override
  void initState() {
    super.initState();
    musicPlayer = widget.musicPlayer;
    artistEditingController.text = musicPlayer.musicList[widget.index].artist;
  }

  @override
  void dispose() {
    artistEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("详情"),
      contentPadding: EdgeInsets.only(left: 20, right: 20, top: 20),
      actionsPadding: EdgeInsets.only(left: 12, right: 12, bottom: 10),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: musicPlayer.musicList[widget.index].path,
            style: TextStyle(color: Colors.grey),
            readOnly: true,
            cursorColor: Colors.grey,
            cursorWidth: 1,
            decoration: InputDecoration(
              labelText: "目标",
              isDense: true,
              labelStyle: TextStyle(color: Colors.grey),
              floatingLabelStyle: TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            ),
          ),
          SizedBox(height: 15),
          TextFormField(
            initialValue: musicPlayer.musicList[widget.index].title,
            onChanged: (value) => newTitle = value,
            cursorColor: Colors.grey,
            cursorWidth: 1,
            decoration: InputDecoration(
              labelText: "标题",
              isDense: true,
              labelStyle: TextStyle(color: Colors.grey),
              floatingLabelStyle: TextStyle(color: Colors.black),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
            ),
          ),
          SizedBox(height: 15),
          TextFormField(
            controller: artistEditingController,
            // initialValue: musicPlayer.musicList[widget.index].artist,
            onChanged: (value) => newArtist = value,
            cursorColor: Colors.grey,
            cursorWidth: 1,
            decoration: InputDecoration(
              labelText: "艺术家",
              isDense: true,
              labelStyle: TextStyle(color: Colors.grey),
              floatingLabelStyle: TextStyle(color: Colors.black),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
            ),
          ),
          searchedArtistList.isEmpty
              ? TextButton(
                child: Text(
                  searchingStatus == 1 ? "搜索中" : (searchingStatus == 0 ? "在线搜索" : "搜索失败"),
                  style: TextStyle(
                    color:
                        searchingStatus == 1
                            ? Colors.grey
                            : (searchingStatus == 0 ? Colors.blue : Colors.red),
                  ),
                ),
                onPressed: () {
                  if (searchingStatus != 0) {
                    return;
                  }
                  setState(() {
                    searchingStatus = 1;
                  });
                  (() async {
                    try {
                      searchedArtistList = await searchMusicArtistOnline(
                        newTitle ?? musicPlayer.musicList[widget.index].title,
                      );
                      print(searchedArtistList);
                      if (searchedArtistList.isNotEmpty) {
                        artistEditingController.text = searchedArtistList[searchedArtistListIndex];
                      } else {
                        searchingStatus = 2;
                      }
                      setState(() {});
                    } catch (e) {
                      return;
                    }
                  })();
                  // showDialog(
                  //   context: context,
                  //   builder:
                  //       (context) =>
                  //           SearchMusicInfo(initTitle: musicPlayer.musicList[widget.index].title),
                  // );
                },
              )
              : Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_left_rounded, size: 25),
                    onPressed: () {
                      setState(() {
                        if (searchedArtistListIndex == 0) {
                          return;
                        }
                        searchedArtistListIndex -= 1;
                        artistEditingController.text = searchedArtistList[searchedArtistListIndex];
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_right_rounded, size: 25),
                    onPressed: () {
                      setState(() {
                        if (searchedArtistListIndex == searchedArtistList.length - 1) {
                          return;
                        }
                        searchedArtistListIndex += 1;
                        artistEditingController.text = searchedArtistList[searchedArtistListIndex];
                      });
                    },
                  ),
                ],
              ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
                child: Text("取消", style: TextStyle(fontSize: 16)),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () {
                  (() async {
                    newArtist = artistEditingController.text;
                    // if (!await checkWritingPermission()) {
                    //   Navigator.pop(context);
                    //   return;
                    // }
                    // if (newArtist == "") {
                    //   newArtist = "Unknown";
                    // }
                    if (newTitle == "") {
                      Fluttertoast.showToast(msg: "标题不能为空");
                      Navigator.pop(context);
                      return;
                    }
                    if (newTitle == musicPlayer.musicList[widget.index].title) {
                      if (newArtist == null ||
                          newArtist == musicPlayer.musicList[widget.index].artist) {
                        Navigator.pop(context);
                        return;
                      }
                      print("newTitle: $newTitle, newArtist: $newArtist");
                      Navigator.pop(context);
                      musicPlayer.changeMusicInfo(widget.index, newTitle, newArtist);
                      return;
                    }
                    if (musicPlayer.musicList.any((music) => music.title == newTitle)) {
                      Fluttertoast.showToast(msg: "标题已存在");
                      return;
                    }
                    print("newTitle: $newTitle, newArtist: $newArtist");
                    Navigator.pop(context);
                    musicPlayer.changeMusicInfo(widget.index, newTitle, newArtist);
                    // saveTags(
                    //   musicList[index].path,
                    //   newTitle,
                    //   newArtist,
                    // );
                  })();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  // padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text("确定", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SearchMusicInfo extends StatefulWidget {
  final String initTitle;

  const SearchMusicInfo({super.key, required this.initTitle});

  @override
  State<StatefulWidget> createState() => SearchMusicInfoState();
}

class SearchMusicInfoState extends State<SearchMusicInfo> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.only(left: 20, right: 20, top: 20),
      actionsPadding: EdgeInsets.only(left: 12, right: 12, bottom: 10),
      title: Text("在线搜索"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: widget.initTitle,
            onChanged: (value) => {},
            cursorColor: Colors.grey,
            cursorWidth: 1,
            decoration: InputDecoration(
              labelText: "",
              isDense: true,
              labelStyle: TextStyle(color: Colors.grey),
              floatingLabelStyle: TextStyle(color: Colors.black),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenPlayer extends StatefulWidget {
  final MusicPlayer musicPlayer;

  const FullScreenPlayer({super.key, required this.musicPlayer});

  @override
  State<FullScreenPlayer> createState() => FullScreenPlayerState();
}

class FullScreenPlayerState extends State<FullScreenPlayer> {
  late MusicPlayer musicPlayer;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  Duration tempPosition = Duration.zero;
  bool isDragging = false;
  bool? isPlaying;

  String? currentMusicTitle;
  String? currentMusicArtist;

  late StreamSubscription indexSubscription;
  late StreamSubscription stateSubscription;
  late StreamSubscription durationSubscription;
  late StreamSubscription positionSubscription;

  @override
  void initState() {
    super.initState();
    musicPlayer = widget.musicPlayer;

    currentMusicTitle = musicPlayer.currentMusicTitle;
    currentMusicArtist = musicPlayer.currentMusicArtist;

    duration = musicPlayer.currentDuration ?? Duration.zero;
    position = musicPlayer.currentPosition ?? Duration.zero;

    indexSubscription = musicPlayer.indexStream.listen((data) {
      setState(() {
        currentMusicTitle = musicPlayer.musicList[data].title;
        currentMusicArtist = musicPlayer.musicList[data].artist;
      });
    });
    stateSubscription = musicPlayer.playerStateStream.listen((data) {
      setState(() {
        isPlaying = data.playing;
      });
    });
    durationSubscription = musicPlayer.durationStream.listen((data) {
      if (duration != data) {
        setState(() {
          duration = data;
        });
      }
    });
    positionSubscription = musicPlayer.positionStream.listen((data) {
      setState(() {
        position = data;
      });
    });
    if (duration == Duration.zero) {
      duration = musicPlayer.currentDuration ?? Duration.zero;
    }
    isPlaying ??= musicPlayer.currentState?.playing ?? false;
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
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(height: 25),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset("assets/NoMusicCover.png", fit: BoxFit.contain, width: 300),
                  ),
                  SizedBox(height: 50),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: 300,
                        child: AutoScrollText(
                          text: currentMusicTitle ?? "",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                          velocity: 30,
                        ),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        width: 300,
                        child: AutoScrollText(
                          text: currentMusicArtist ?? "",
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
                                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
                                overlayShape: RoundSliderOverlayShape(overlayRadius: 15),
                                thumbColor: const Color.fromARGB(255, 85, 85, 85),
                                activeTrackColor: const Color.fromARGB(255, 85, 85, 85),
                                inactiveTrackColor: Colors.grey[300],
                                overlayColor: const Color.fromARGB(50, 85, 85, 85),
                                showValueIndicator: ShowValueIndicator.always, // 显示当前值标签
                                valueIndicatorTextStyle: TextStyle(
                                  color: const Color.fromARGB(255, 85, 85, 85),
                                ),
                              ),
                              child: Slider(
                                min: 0,
                                max: duration.inSeconds.toDouble(),
                                label:
                                    "${(isDragging ? tempPosition : position).inMinutes}:${((isDragging ? tempPosition : position).inSeconds % 60).toString().padLeft(2, '0')}",
                                value: (isDragging ? tempPosition : position).inSeconds
                                    .toDouble()
                                    .clamp(0, duration.inSeconds.toDouble()),
                                onChanged: (value) {
                                  setState(() {
                                    isDragging = true;
                                    tempPosition = Duration(seconds: value.toInt());
                                  });
                                },
                                onChangeEnd: (value) {
                                  setState(() {
                                    isDragging = false;
                                  });
                                  musicPlayer.seek(Duration(seconds: value.toInt()));
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
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(width: 5),
                          IconButton(
                            icon: Icon(
                              musicPlayer.playingMode == 2
                                  ? Icons.shuffle_rounded
                                  : Icons.repeat_rounded,
                              color: Colors.black,
                            ),
                            iconSize: 30,
                            onPressed: () {
                              if (musicPlayer.playingMode == 1) {
                                musicPlayer.changePlayingMode(2);
                                setState(() {});
                              } else {
                                musicPlayer.changePlayingMode(1);
                                setState(() {});
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.skip_previous_rounded,
                              color: const Color.fromARGB(255, 0, 0, 0),
                            ),
                            iconSize: 45,
                            onPressed: () {
                              musicPlayer.playPrevious();
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              isPlaying ?? false ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: const Color.fromARGB(255, 0, 0, 0),
                            ),
                            iconSize: 50,
                            onPressed: () {
                              if (isPlaying != null) {
                                if (isPlaying!) {
                                  musicPlayer.pause();
                                } else {
                                  musicPlayer.play();
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.skip_next_rounded,
                              color: const Color.fromARGB(255, 0, 0, 0),
                            ),
                            iconSize: 45,
                            onPressed: () {
                              musicPlayer.playNext();
                            },
                          ),
                          // IconButton(onPressed: () {}, icon: Icon(Icons.more_vert), iconSize: 30),
                          SizedBox(width: 65),
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
