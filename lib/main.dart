import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
// import 'package:nyapp/anilist.dart';
import 'package:nyapp/home.dart';
import 'package:nyapp/settings.dart';
import 'package:nyapp/utils.dart';
import 'package:nyapp/widgets/common.dart';
import 'package:window_manager/window_manager.dart';

late String baseUrl;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    windowManager.ensureInitialized();
  }
  List<String> seedColorList =
      (await PrefsManager.readData('seedColor') ?? <String>['0', '127', '128']);
  baseUrl = await PrefsManager.readData('url') ?? '';

  int seedR = int.parse(seedColorList[0]);
  int seedG = int.parse(seedColorList[1]);
  int seedB = int.parse(seedColorList[2]);

  if (Platform.isAndroid || Platform.isIOS) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: <SystemUiOverlay>[],
    );
  }

  runApp(
    MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Quicksand',
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: Color.fromARGB(
            255,
            seedR,
            seedG,
            seedB,
          ),
        ),
      ),
      home: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int currentIndex = 0;
  String baseUrl = '';
  final PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchUrl();
  }

  Future<void> _fetchUrl() async {
    baseUrl = await PrefsManager.readData('url') ?? '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = <Widget>[
      const HomePage(),
      const SettingsPage(),
      // const AnilistPage(),
    ];

    if (baseUrl.isNotEmpty) {
      return Scaffold(
        body: PageView(
          controller: pageController,
          onPageChanged: (int index) {
            setState(() => currentIndex = index);
          },
          children: pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (int index) {
            pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.decelerate,
            );
          },
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.person),
            //   label: "Anilist",
            // ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      );
    } else {
      return const Scaffold(body: UrlPromptPage());
    }
  }
}
