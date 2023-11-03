import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

class PlayerPage extends StatefulWidget {
  final String filePath;

  const PlayerPage({super.key, required this.filePath});

  @override
  State<PlayerPage> createState() => PlayerPageState();
}

class PlayerPageState extends State<PlayerPage> {
  late final Player player = Player(
    configuration: const PlayerConfiguration(libass: true),
  );
  late final VideoController controller = VideoController(player);
  bool _isVisible = true;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    player.open(Media(widget.filePath));
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  void _toggleFullScreen() async {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      if (Platform.isAndroid || Platform.isIOS) {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: <SystemUiOverlay>[],
        );
        SystemChrome.setPreferredOrientations(<DeviceOrientation>[
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ]);
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        await WindowManager.instance.setFullScreen(true);
      }
    } else {
      if (Platform.isAndroid || Platform.isIOS) {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
        SystemChrome.setPreferredOrientations(<DeviceOrientation>[
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        await WindowManager.instance.setFullScreen(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            _isVisible = !_isVisible;
          });
          if (_isVisible) {
            Future<void>.delayed(const Duration(seconds: 5), () {
              if (mounted) {
                setState(() {
                  _isVisible = false;
                });
              }
            });
          }
        },
        child: Stack(
          children: <Widget>[
            Video(
              controller: controller,
              controls: (VideoState state) {
                return IgnorePointer(
                  ignoring: !_isVisible,
                  child: AnimatedOpacity(
                    opacity: _isVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: MediaQuery.of(context).size.width *
                            (_isFullScreen ? 1 : 0.75),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  IconButton(
                                    icon: Icon(
                                      player.state.playing
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                    ),
                                    onPressed: () {
                                      player.playOrPause();
                                      setState(() {});
                                    },
                                  ),
                                  Expanded(
                                    child: StreamBuilder<Duration>(
                                      stream: player.stream.position,
                                      builder: (
                                        BuildContext context,
                                        AsyncSnapshot<Duration> snapshot,
                                      ) {
                                        final double position = snapshot
                                                .data?.inSeconds
                                                .toDouble() ??
                                            0;
                                        return Slider(
                                          value: position,
                                          min: 0.0,
                                          max: player.state.duration.inSeconds
                                              .toDouble(),
                                          onChanged: (double value) {},
                                          onChangeEnd: (double value) {
                                            player.seek(
                                              Duration(
                                                seconds: value.toInt(),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _isFullScreen
                                          ? Icons.fullscreen_exit
                                          : Icons.fullscreen,
                                    ),
                                    onPressed: _toggleFullScreen,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            IgnorePointer(
              ignoring: !_isVisible,
              child: AnimatedOpacity(
                opacity: _isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(
                          Icons.fast_rewind,
                        ),
                        onPressed: () {
                          player.seek(
                            player.state.position - const Duration(seconds: 5),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          player.state.playing ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: () {
                          player.playOrPause();
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.fast_forward),
                        onPressed: () {
                          player.seek(
                            player.state.position + const Duration(seconds: 5),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              ignoring: !_isVisible,
              child: AnimatedOpacity(
                opacity: _isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_downward),
                      onPressed: () {
                        player.stop();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
