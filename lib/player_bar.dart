import "package:flutter/material.dart";
import "package:just_audio/just_audio.dart";
import "auto_scroll_text.dart";
import "music_player.dart";

class PlayerBar extends StatefulWidget {
  final MusicPlayer musicPlayer;

  const PlayerBar({super.key, required this.musicPlayer});

  @override
  State<StatefulWidget> createState() => PlayerBarState();
}

class PlayerBarState extends State<PlayerBar> {
  late MusicPlayer musicPlayer;

  PlayerState? playerState;
  String? currentMusicTitle;
  String? currentMusicArtist;

  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    musicPlayer = widget.musicPlayer;

    currentMusicTitle = musicPlayer.currentMusicTitle;
    currentMusicArtist = musicPlayer.currentMusicArtist;

    musicPlayer.playerStateStream.listen((data) {
      setState(() {
        playerState = data;
        isPlaying = playerState?.playing ?? false;
      });
    });
    musicPlayer.indexStream.listen((data) {
      setState(() {
        currentMusicTitle = musicPlayer.musicList[data].title;
        currentMusicArtist = musicPlayer.musicList[data].artist;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          //borderRadius: BorderRadius.circular(12),
          border: Border(top: BorderSide(color: const Color.fromARGB(255, 225, 225, 225))),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.asset("assets/NoMusicCover-ldpi.png", width: 50, fit: BoxFit.contain),
            ),
            SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 250,
                  child: AutoScrollText(
                    text: currentMusicTitle ?? "",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: AutoScrollText(
                    text: currentMusicArtist ?? "",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),

            Spacer(),
            IconButton(
              icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
              onPressed: () {
                if (isPlaying) {
                  setState(() {
                    isPlaying = false;
                  });
                  musicPlayer.pause();
                } else {
                  // setState(() {
                  //   isPlaying = true;
                  // });
                  musicPlayer.play();
                }
              },
            ),
            //SizedBox(width: 5),
          ],
        ),
      ),
    );
  }
}
