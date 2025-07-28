import "package:flutter/material.dart";

class MusicFileEditor extends StatelessWidget {
  const MusicFileEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("音乐文件编辑器")),
      body: Center(
        child: Text(
          "开发中",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
