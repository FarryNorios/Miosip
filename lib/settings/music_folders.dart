import "package:flutter/material.dart";
import "package:file_picker/file_picker.dart";

import "../data_manager.dart";

class MusicFoldersWidget extends StatefulWidget {
  const MusicFoldersWidget({super.key});

  @override
  State<MusicFoldersWidget> createState() => MusicFoldersWidgetState();
}

class MusicFoldersWidgetState extends State<MusicFoldersWidget> {
  List<String> musicFoldersList = [
    "/storage/emulated/0/Music",
    "/storage/emulated/0/Downloads",
  ];

  @override
  void initState() {
    super.initState();
    (() async {
      musicFoldersList = await loadMusicFoldersList();
      setState(() {});
    })();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color.fromARGB(255, 225, 225, 225)),
        ),

        child: ListView.separated(
          //防止卡死
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),

          itemCount: musicFoldersList.length + 1,

          //分界线
          separatorBuilder:
              (context, index) => Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: const Color.fromARGB(255, 225, 225, 225),
              ),

          itemBuilder: (context, index) {
            if (index < musicFoldersList.length) {
              return ListTile(
                leading: Icon(Icons.folder_open),
                //显示文件夹路径，超过25个字符则显示最后25个字符
                title: Text(
                  musicFoldersList[index].length > 25
                      ? "...${musicFoldersList[index].substring(musicFoldersList[index].length - 25)}"
                      : musicFoldersList[index],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      musicFoldersList.removeAt(index);
                    });
                    saveMusicFoldersList(musicFoldersList);
                  },
                ),
              );
            } else {
              //加号按钮
              return Center(
                child: IconButton(
                  icon: Icon(Icons.add_rounded),
                  onPressed: () async {
                    String? result =
                        await FilePicker.platform.getDirectoryPath();
                    if (result != null) {
                      setState(() {
                        musicFoldersList.add(result);
                      });
                      saveMusicFoldersList(musicFoldersList);
                    }
                  },
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
