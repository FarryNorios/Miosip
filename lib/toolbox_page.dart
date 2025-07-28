import "package:flutter/material.dart";
import "tools/music_file_editor.dart";

class ToolboxPage extends StatelessWidget {
  const ToolboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("工具箱")),
      body: ListView(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20),
            leading: Icon(Icons.edit_rounded, size: 25),
            title: Text("音乐文件编辑器", style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MusicFileEditor()),
              );
            },
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 5,
            endIndent: 5,
            color: const Color.fromARGB(255, 245, 245, 245),
          ),
        ],
      ),
    );
  }
}
