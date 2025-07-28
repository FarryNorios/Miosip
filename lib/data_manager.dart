import "dart:io";
import "dart:math";
import "dart:convert";
import "package:path/path.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:lpinyin/lpinyin.dart";
import "permission_manager.dart";
import "package:audiotags/audiotags.dart";
import "package:audio_metadata_reader/audio_metadata_reader.dart";

class Music {
  final String path;
  String title;
  String artist;

  Music({required this.path, required this.title, required this.artist});

  Map<String, dynamic> toMap() {
    return {"path": path, "title": title, "artist": artist};
  }

  factory Music.fromMap(Map<String, dynamic> map) {
    return Music(path: map["path"], title: map["title"], artist: map["artist"]);
  }
}

final List<String> supportedExtensions = [".mp3", ".flac", ".wav"];

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
Future<List<String>> scanMusicFiles() async {
  await checkAudioPermission();
  final List<String> musicFoldersList = await loadMusicFoldersList();
  List<String> musicFiles = [];
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
              // Tag? tags = await readTags(entity.path);
              musicFiles.add(entity.path);
            }
          }
        }
      }
    }
  }
  print("Scaned music list");
  return musicFiles;
}

List<Music> handleMusicFiles(List<String> musicFiles, List<Music> musicList) {
  List<Music> newMusicList = [];
  for (String musicFile in musicFiles) {
    Music music = musicList.firstWhere(
      (music) => music.path == musicFile,
      orElse:
          () => Music(
            path: musicFile,
            title: basenameWithoutExtension(musicFile),
            artist: "",
          ),
    );
    newMusicList.add(music);
  }
  return newMusicList;
}

Future<List<Music>> loadMusicList() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString("musicList") ?? "[]";
  final jsonList = json.decode(jsonString) as List;
  try {
    return jsonList.map((json) => Music.fromMap(json)).toList();
  } catch (e) {
    print("Error loading music list: $e");
    await clearMusicList();
    return [];
  }
}

Future<void> saveMusicList(List<Music> musicList) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonList = musicList.map((music) => music.toMap()).toList();
  final jsonString = json.encode(jsonList);
  await prefs.setString("musicList", jsonString);
  print("Saved music list");
}

Future<void> clearMusicList() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove("musicList");
  print("Cleared music list");
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

Future<Tag?> readTags(String path) async {
  try {
    return await AudioTags.read(path);
  } catch (e) {
    try {
      final metadata = await readMetadata(File(path), getImage: false);
      final tags = Tag(
        title: metadata.title ?? basenameWithoutExtension(path),
        trackArtist: metadata.artist ?? "Unknown",
        pictures: List.empty(),
      );
      print(
        "Using AudioTags to read $path tags failed but using AudioMetadataReader to read succeeded.",
      );
      return tags;
    } catch (e) {
      print("Read $path tags failed: $e, returning null.");
      return null;
    }
  }
}

Future<void> saveTags(String path, String title, String artist) async {
  await AudioTags.write(
    path,
    Tag(title: title, trackArtist: artist, pictures: List.empty()),
  );
}
