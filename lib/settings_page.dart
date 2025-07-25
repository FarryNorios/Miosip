import "package:flutter/material.dart";

import "settings/music_folders.dart";

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("设置")),
      body: ListView(
        children: [
          // //显示设置
          // ListTile(
          //   title: Text(
          //     "显示设置",
          //     style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          //   ),
          // ),
          // ListTile(
          //   leading: Icon(Icons.dark_mode),
          //   title: Text("深色模式"),
          //   trailing: Switch(value: false, onChanged: (v) {}),
          // ),
          // ListTile(
          //   leading: Icon(Icons.font_download),
          //   title: Text("字体大小"),
          //   trailing: Icon(Icons.arrow_forward_ios),
          // ),

          //分界线
          // Divider(
          //   thickness: 1,
          //   indent: 16,
          //   endIndent: 16,
          //   color: const Color.fromARGB(255, 225, 225, 225),
          // ),

          //本地文件
          ListTile(
            title: Text(
              "本地文件",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),

          ListTile(leading: Icon(Icons.audio_file), title: Text("音乐文件源")),
          MusicFoldersWidget()
        ],
      ),
    );
  }
}
