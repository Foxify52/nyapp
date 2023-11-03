// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:io';

import 'package:anilist_api/anilist.dart';
import 'package:dtorrent_task/dtorrent_task.dart';
import 'package:events_emitter2/events_emitter2.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:dtorrent_parser/dtorrent_parser.dart';
import 'package:dtorrent_task/src/task_events.dart';
import 'package:nyapp/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

AnilistQueryResult<AnilistMedia>? _cacheTrending;

class PrefsManager {
  static void saveData(String key, dynamic value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value is int) {
      prefs.setInt(key, value);
    } else if (value is double) {
      prefs.setDouble(key, value);
    } else if (value is String) {
      prefs.setString(key, value);
    } else if (value is bool) {
      prefs.setBool(key, value);
    } else if (value is List) {
      prefs.setStringList(key, value as List<String>);
    } else {
      throw Exception('Invalid Type');
    }
  }

  static Future<T?> readData<T>(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (T == bool) {
      return prefs.getBool(key) as T?;
    } else if (T == double) {
      return prefs.getDouble(key) as T?;
    } else if (T == int) {
      return prefs.getInt(key) as T?;
    } else if (T == String) {
      return prefs.getString(key) as T?;
    } else if (T == List<String>) {
      return prefs.getStringList(key) as T?;
    } else {
      return prefs.get(key) as T?;
    }
  }

  static Future<bool> deleteData(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }
}

Future<AnilistQueryResult<AnilistMedia>> anilistSearch({
  required String name,
}) async {
  AnilistMediaRequest request = AnilistMediaRequest();
  request
    ..withTitle()
    ..withType()
    ..withEpisodes()
    ..withCoverImage()
    ..withGenres()
    ..withSynonyms()
    ..withMeanScore()
    ..withAverageScore()
    ..withPopularity()
    ..withFavourites()
    ..withTrending()
    ..withTagsId()
    ..withTagsName();
  request.queryType(AnilistMediaType.ANIME);
  request.querySearch(name);

  AnilistQueryResult<AnilistMedia> result = await request.list(10, 1);
  return result;
}

Future<AnilistQueryResult<AnilistMedia>> anilistTrending() async {
  if (_cacheTrending != null) {
    return _cacheTrending!;
  }

  AnilistMediaRequest request = AnilistMediaRequest();
  request
    ..withTitle()
    ..withType()
    ..withCoverImage()
    ..withTrending();
  request.queryType(AnilistMediaType.ANIME);
  request.sort(<AnilistMediaSort>[AnilistMediaSort.TRENDING_DESC]);
  _cacheTrending = await request.list(25, 1);

  return _cacheTrending!;
}

Future<String> checkCache(String fileRef) async {
  String cacheFile = '';
  List<String> lastDownloadedFiles =
      await PrefsManager.readData('lastDownloadedFiles') ?? <String>[];
  List<String> fileReferences =
      await PrefsManager.readData('fileReferences') ?? <String>[];
  Directory temp = await getApplicationCacheDirectory();
  Directory tempDir = Directory(
    '${temp.path}${Platform.pathSeparator}temp${Platform.pathSeparator}',
  );
  if (fileReferences.contains(fileRef)) {
    cacheFile =
        '${tempDir.path}${lastDownloadedFiles[fileReferences.indexOf(fileRef)]}';
  }
  return cacheFile;
}

Future<List<List<String>>> siteSearch(
  String filter,
  String category,
  String query,
  String episode,
  String quality,
) async {
  List<List<String>> results = <List<String>>[];
  try {
    query = '$query+$episode+$quality'.replaceAll(' ', '+');
    String pageUrl = '$baseUrl?f=$filter&c=$category&q=$query';
    http.Response response = await http.get(Uri.parse(pageUrl));
    if (response.statusCode == 200) {
      Document scrape = parse(response.body);
      List<Element> rows =
          scrape.querySelectorAll('tr.success, tr.danger, tr.default');
      for (Element row in rows) {
        List<String> result = <String>[];
        List<Element> content = row.querySelectorAll('td');
        result.add(content[1].querySelectorAll('a').last.innerHtml);
        result.add(
          '$baseUrl${content[2].querySelector('a')!.attributes['href']!}',
        );
        results.add(result);
      }
    }
    return results;
  } catch (_) {
    return <List<String>>[];
  }
}

Stream<String> download(
  String name,
  String id,
  String episode,
  String quality,
  String url,
) async* {
  String fileRef = '${id}_${quality}_$episode';
  List<String> lastDownloadedFiles =
      await PrefsManager.readData('lastDownloadedFiles') ?? <String>[];
  List<String> fileReferences =
      await PrefsManager.readData('fileReferences') ?? <String>[];
  List<String> localHistory =
      await PrefsManager.readData('localHistory') ?? <String>[];
  Directory temp = await getApplicationCacheDirectory();
  String torrentFile = '${temp.path}${Platform.pathSeparator}file.torrent';
  Directory tempDir = Directory(
    '${temp.path}${Platform.pathSeparator}temp${Platform.pathSeparator}',
  );
  if (temp.existsSync()) {
    temp.listSync().forEach((FileSystemEntity file) {
      if (file is File &&
          (file.path.endsWith('.state') || file.path.endsWith('.torrent'))) {
        file.deleteSync();
      }
    });
  } else {
    temp.createSync();
  }
  await http.get(Uri.parse(url)).then(
        (http.Response response) =>
            File(torrentFile).writeAsBytes(response.bodyBytes),
      );
  Timer? timer;
  Torrent model = await Torrent.parse(torrentFile);
  TorrentTask task = TorrentTask.newTask(model, tempDir.path);
  EventsListener<TaskEvent> listener = task.createListener();
  String fileName = '';
  StreamController<String> controller = StreamController<String>();
  listener
    ..on<TaskCompleted>((TaskCompleted event) {
      timer?.cancel();
      task.stop();
    })
    ..on<TaskStopped>(
      (TaskStopped event) async {
        while (fileName.isEmpty) {
          List<FileSystemEntity> files = tempDir.listSync();
          for (FileSystemEntity file in files) {
            if (file is File && file.path.endsWith('.mkv')) {
              String potentialFileName =
                  file.path.split(Platform.pathSeparator).last;
              if (!lastDownloadedFiles.contains(potentialFileName)) {
                fileName = potentialFileName;
                break;
              }
            }
          }
        }

        lastDownloadedFiles.add(fileName);
        fileReferences.add(fileRef);
        localHistory.add(name);

        if (lastDownloadedFiles.length > 20) {
          File oldDownloadedFile =
              File('${tempDir.path}${lastDownloadedFiles[0]}');
          if (oldDownloadedFile.existsSync()) {
            oldDownloadedFile.deleteSync();
          }
          lastDownloadedFiles.removeAt(0);
          fileReferences.removeAt(0);
        }

        PrefsManager.saveData('lastDownloadedFiles', lastDownloadedFiles);
        PrefsManager.saveData('fileReferences', fileReferences);
        PrefsManager.saveData('localHistory', localHistory);

        controller.add('${tempDir.path}$fileName');
        controller.close();
      },
    );

  task.start();
  for (Uri element in model.nodes) {
    task.addDHTNode(element);
  }
  timer = Timer.periodic(
    const Duration(seconds: 2),
    (Timer timer) async {
      controller.add(task.progress.toString());
    },
  );
  await for (String update in controller.stream) {
    yield update;
  }
}

Future<List<AnilistMedia>> getLocalHistory() async {
  final List<String> localHistory =
      await PrefsManager.readData('localHistory') ?? <String>[];

  return Future.wait(
    localHistory.map(
      (String name) async {
        AnilistQueryResult<AnilistMedia> result =
            await anilistSearch(name: name);
        return result.results!.first;
      },
    ),
  );
}

void clearCache() async {
  Directory temp = await getApplicationCacheDirectory();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  temp.deleteSync(recursive: true);
  prefs.clear();
}
