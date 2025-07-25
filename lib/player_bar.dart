import "package:flutter/material.dart";
import "package:just_audio/just_audio.dart";
import "AutoScrollText.dart";
import "music_player.dart";

class PlayerBar extends StatelessWidget {
  final MusicPlayer player;

  const PlayerBar({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        // final processingState = state?.processingState;
        // if (musicTitle == null || processingState == ProcessingState.idle) {
        //   return const SizedBox.shrink();
        // }
        final isPlaying = state?.playing ?? false;
        return SafeArea(
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              //borderRadius: BorderRadius.circular(12),
              border: Border(
                top: BorderSide(
                  color: const Color.fromARGB(255, 225, 225, 225),
                ),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.asset("assets/NoMusicCover-ldpi.png", width: 50, fit: BoxFit.contain),
                ),
                SizedBox(width: 10),
                SizedBox(
                  width: 250,
                  child: AutoScrollText(
                    text: player.currentMusicTitle ?? "",
                    style: TextStyle(fontSize: 16),
                  )
                ),
                Spacer(),
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  onPressed: () {
                    if (isPlaying) {
                      player.pause();
                    } else {
                      player.play();
                    }
                  },
                ),
                //SizedBox(width: 5),
              ],
            ),
          ),
        );
      },
    );
  }
}
