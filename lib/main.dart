import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "home_page.dart";
import "music_player.dart";

final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(MyApp());
// }

late MusicPlayer musicPlayer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  musicPlayer = MusicPlayer();
  await musicPlayer.initAudioHandler();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Miosip",
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: const Color.fromARGB(255, 255, 255, 255),
          secondary: const Color.fromARGB(255, 255, 59, 48),
        ),

        appBarTheme: AppBarTheme(
          elevation: 1,
          titleSpacing: 5,
          shadowColor: const Color.fromARGB(120, 255, 255, 255),
          titleTextStyle: TextStyle(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),

        popupMenuTheme: PopupMenuThemeData(
          elevation: 1,
          shadowColor: const Color.fromARGB(120, 255, 255, 255),
        ),

        listTileTheme: ListTileThemeData(
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.basic),
        ),
      ),
      home: HomePage(musicPlayer: musicPlayer),
      navigatorObservers: [routeObserver],
    );
  }
}

// class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {}
