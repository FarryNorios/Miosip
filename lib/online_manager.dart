import "dart:convert";
import "package:http/http.dart" as http;
import "package:html/parser.dart" as parser;

Future<List<String>> searchMusicArtistOnline(String title) async {
  List<String> artistList = [];
  try {
    final response = await http.get(Uri.parse("https://api.vkeys.cn/v2/music/netease?word=$title"));
    if (response.statusCode == 200) {
      List<dynamic> items = jsonDecode(response.body)["data"];
      for (var item in items) {
        if (artistList.contains(item["singer"])) {
          continue;
        }
        artistList.add(item["singer"]);
      }
      return artistList;
    } else {
      return artistList;
    }
  } catch (e) {
    return artistList;
  }
}
