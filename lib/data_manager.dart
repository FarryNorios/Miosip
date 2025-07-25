import "dart:io";
import "dart:math";
import "dart:convert";
import "package:path/path.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:permission_handler/permission_handler.dart";
import "package:lpinyin/lpinyin.dart";

class Music {
  final String title;
  final String path;

  Music({required this.title, required this.path});

  Map<String, dynamic> toMap() {
    return {"title": title, "path": path};
  }

  factory Music.fromMap(Map<String, dynamic> map) {
    return Music(title: map["title"], path: map["path"]);
  }
}

final List<String> supportedExtensions = [".mp3", ".flac", ".wav"];

//获取文件权限
Future<void> requestPermission() async {
  try {
    await Permission.audio.request();
  } catch (e) {}
}

//获取音乐存储的文件夹列表
Future<List<String>> loadMusicFoldersList() async {
  final prefs = await SharedPreferences.getInstance();
  final List<String>? saved = prefs.getStringList("musicFoldersList");
  return saved ?? [];
}

Future<void> saveMusicFoldersList(List<String> musicFoldersList) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setStringList("musicFoldersList", musicFoldersList);
}

//扫描音乐文件列表
Future<List<Music>> scanMusicFiles() async {
  final List<String> musicFoldersList = await loadMusicFoldersList();
  List<Music> musicFiles = [];
  for (String folder in musicFoldersList) {
    final dir = Directory(folder);
    if (await dir.exists()) {
      //recursive: true 包括子文件夹中的文件
      final entities = dir.list(recursive: true);
      await for (var entity in entities) {
        if (entity is File) {
          if (entity.path.contains(".")) {
            final ext = entity.path.split(".").last.toLowerCase();
            //目标文件判断过滤
            if (supportedExtensions.contains(".$ext")) {
              musicFiles.add(
                Music(
                  title: basenameWithoutExtension(entity.path),
                  path: entity.path,
                ),
              );
            }
          }
        }
      }
    }
  }
  print("scaned music list");
  return musicFiles;
}

Future<List<Music>> loadMusicList() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString("musicList") ?? "[]";
  final jsonList = json.decode(jsonString) as List;
  return jsonList.map((json) => Music.fromMap(json)).toList();
}

Future<void> saveMusicList(List<Music> musicList) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonList = musicList.map((music) => music.toMap()).toList();
  final jsonString = json.encode(jsonList);
  await prefs.setString("musicList", jsonString);
}

Future<int> loadSortMode() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getInt("sortMode") ?? 1;
  return saved;
}

Future<void> saveSortMode(int sortMode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt("sortMode", sortMode);
}

List<Music> sortMusicList(List<Music> musicList, int mode) {
  //先分离出三种列表
  List<Music> englishList = [];
  List<Music> chineseList = [];
  List<Music> otherList = [];
  for (Music music in musicList) {
    if (isEnglishChar(music.title[0])) {
      englishList.add(music);
    } else if (isChineseChar(music.title[0])) {
      chineseList.add(music);
    } else {
      otherList.add(music);
    }
  }

  //冒泡排序
  for (int i = 0; i < englishList.length - 1; i++) {
    for (int j = 0; j < englishList.length - 1 - i; j++) {
      if (englishList[j].title.length > englishList[j + 1].title.length &&
          englishList[j].title.substring(0, englishList[j + 1].title.length) ==
              englishList[j + 1].title) {
        Music t = englishList[j];
        englishList[j] = englishList[j + 1];
        englishList[j + 1] = t;
        continue;
      }
      for (
        int k = 0;
        k < min(englishList[j].title.length, englishList[j + 1].title.length);
        k++
      ) {
        if (englishList[j].title[k].toLowerCase().codeUnitAt(0) >
            englishList[j + 1].title[k].toLowerCase().codeUnitAt(0)) {
          Music t = englishList[j];
          englishList[j] = englishList[j + 1];
          englishList[j + 1] = t;
          break;
        } else if (englishList[j].title[k].toLowerCase().codeUnitAt(0) ==
            englishList[j + 1].title[k].toLowerCase().codeUnitAt(0)) {
          continue;
        } else {
          break;
        }
      }
    }
  }

  for (int i = 0; i < chineseList.length - 1; i++) {
    for (int j = 0; j < chineseList.length - 1 - i; j++) {
      for (
        int k = 0;
        k < min(chineseList[j].title.length, chineseList[j + 1].title.length);
        k++
      ) {
        if (PinyinHelper.getFirstWordPinyin(
              chineseList[j].title[k],
            ).codeUnitAt(0) >
            PinyinHelper.getFirstWordPinyin(
              chineseList[j + 1].title[k],
            ).codeUnitAt(0)) {
          Music t = chineseList[j];
          chineseList[j] = chineseList[j + 1];
          chineseList[j + 1] = t;
          break;
        } else if (PinyinHelper.getFirstWordPinyin(
              chineseList[j].title[k],
            ).codeUnitAt(0) ==
            PinyinHelper.getFirstWordPinyin(
              chineseList[j + 1].title[k],
            ).codeUnitAt(0)) {
          continue;
        } else {
          break;
        }
      }
    }
  }

  switch (mode) {
    case 1:
      musicList = englishList + chineseList + otherList;
      break;
    case 2:
      musicList = chineseList + englishList + otherList;
      break;
  }
  return musicList;
}

bool isChineseChar(String char) {
  int code = char.codeUnitAt(0);
  return (code >= 0x4E00 && code <= 0x9FFF) ||
      (code >= 0x3400 && code <= 0x4DBF) ||
      (code >= 0x20000 && code <= 0x2A6DF) ||
      (code >= 0x2A700 && code <= 0x2B73F) ||
      (code >= 0x2B740 && code <= 0x2B81F) ||
      (code >= 0x2B820 && code <= 0x2CEAF) ||
      (code >= 0xF900 && code <= 0xFAFF) ||
      (code >= 0x2F800 && code <= 0x2FA1F);
}

bool isEnglishChar(String char) {
  int code = char.codeUnitAt(0);
  return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
}
