import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nyapp/utils.dart';
import 'package:nyapp/widgets/common.dart';
import 'package:path_provider/path_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String seedColor = '';
  String primaryColor = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Accordion(
          title: 'Global theme colors',
          body: TextField(
            onSubmitted: (String value) {
              setState(
                () {
                  seedColor = value;
                  _updateColor('seedColor', seedColor);
                },
              );
            },
            decoration: InputDecoration(
              hintText: 'Seed color RGB',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ),
        const Accordion(
          title: 'Debug Tools',
          body: Column(
            children: <Widget>[
              Text(
                "Don't mess with these unless you know what you're doing. If the app has issues, you can hit the clear cache button to reset the app but everything else here is designed to be used to debug internal values that otherwise can't be accessed easily.",
              ),
              ElevatedButton(
                onPressed: clearCache,
                child: Text('Clear cache'),
              ),
              SharedPrefsWidget(),
              SizedBox(
                height: 100,
                child: FileListWidget(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _updateColor(String key, String value) async {
    value = value.replaceAll(' ', '');
    if (_isValidRGB(value)) {
      PrefsManager.saveData(key, value.split(','));
    }
  }

  bool _isValidRGB(String value) {
    List<String> rgbValues = value.split(',');
    if (rgbValues.length != 3) return false;

    for (String val in rgbValues) {
      int? intValue = int.tryParse(val);
      if (intValue == null || intValue < 0 || intValue > 255) return false;
    }

    return true;
  }
}

class SharedPrefsWidget extends StatefulWidget {
  const SharedPrefsWidget({super.key});

  @override
  State<SharedPrefsWidget> createState() => _SharedPrefsWidgetState();
}

class _SharedPrefsWidgetState extends State<SharedPrefsWidget> {
  final TextEditingController keyController = TextEditingController();
  final TextEditingController valueController = TextEditingController();
  bool isSaveMode = true;
  String loadedValue = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: keyController,
          decoration: const InputDecoration(labelText: 'Key'),
        ),
        if (isSaveMode)
          TextField(
            controller: valueController,
            decoration: const InputDecoration(labelText: 'Value'),
          ),
        if (!isSaveMode)
          Padding(
            padding: const EdgeInsets.only(top: 17, bottom: 17),
            child: Text('Value: $loadedValue'),
          ),
        const Padding(
          padding: EdgeInsetsDirectional.all(10.0),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const Text('Load'),
            Switch(
              value: isSaveMode,
              onChanged: (bool value) => setState(() => isSaveMode = value),
            ),
            const Text('Save'),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: ElevatedButton(
                onPressed: () async {
                  if (isSaveMode) {
                    PrefsManager.saveData(
                      keyController.text,
                      valueController.text,
                    );
                  } else {
                    loadedValue = ((await PrefsManager.readData<dynamic>(
                              keyController.text,
                            )) ??
                            '')
                        .toString();
                    valueController.text = loadedValue;
                    setState(() {});
                  }
                },
                child: const Text('Enter'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class FileListWidget extends StatefulWidget {
  const FileListWidget({super.key});

  @override
  State<FileListWidget> createState() => _FileListWidgetState();
}

class _FileListWidgetState extends State<FileListWidget> {
  late Future<List<String>> _fileList;

  @override
  void initState() {
    super.initState();
    _fileList = getFiles();
  }

  Future<List<String>> getFiles() async {
    Directory cacheDir = await getApplicationCacheDirectory();
    Directory tempDir = Directory(
      '${cacheDir.path}${Platform.pathSeparator}temp${Platform.pathSeparator}',
    );
    if (tempDir.existsSync()) {
      return tempDir
          .listSync()
          .map((FileSystemEntity file) => file.path)
          .toList();
    }
    return <String>[];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _fileList,
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                leading: Text(snapshot.data![index]),
                trailing: ElevatedButton(
                  onPressed: () async {
                    await File(snapshot.data![index]).delete();
                    setState(() {
                      _fileList = getFiles();
                    });
                  },
                  child: const Text('Delete'),
                ),
              );
            },
          );
        }
      },
    );
  }
}
