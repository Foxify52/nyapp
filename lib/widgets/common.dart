import 'package:anilist_api/anilist.dart';
import 'package:flutter/material.dart';
import 'package:nyapp/main.dart';
import 'package:nyapp/player.dart';
import 'package:nyapp/utils.dart';
import 'package:nyapp/widgets/animations.dart';

class UrlPromptPage extends StatefulWidget {
  const UrlPromptPage({super.key});
  @override
  State<UrlPromptPage> createState() => _UrlPromptPageState();
}

class _UrlPromptPageState extends State<UrlPromptPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: <Widget>[
            TextField(
              onSubmitted: (String value) {
                setState(
                  () {
                    try {
                      Uri.parse(value);
                      PrefsManager.saveData('url', value);
                      Navigator.push(
                        context,
                        MaterialPageRoute<Widget>(
                          builder: (BuildContext context) => const MainApp(),
                        ),
                      );
                    } catch (_) {}
                  },
                );
              },
              decoration: InputDecoration(
                hintText: 'Provider URL',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                "Enter the URL of your site. If you don't know what this is, join the discord and ask.",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Accordion extends StatefulWidget {
  final String title;
  final Widget body;

  const Accordion({
    Key? key,
    required this.title,
    required this.body,
  }) : super(key: key);

  @override
  State<Accordion> createState() => _AccordionState();
}

class _AccordionState extends State<Accordion> with TickerProviderStateMixin {
  bool _showContent = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          ListTile(
            title: Text(widget.title),
            trailing: IconButton(
              icon: Icon(
                _showContent ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              ),
              onPressed: () {
                setState(
                  () {
                    _showContent = !_showContent;
                  },
                );
              },
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _showContent
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ),
                    child: widget.body,
                  )
                : Container(),
          ),
        ],
      ),
    );
  }
}

class AnimeDetailSelector extends StatefulWidget {
  final AnilistMedia media;

  const AnimeDetailSelector({super.key, required this.media});

  @override
  State<AnimeDetailSelector> createState() => _AnimeDetailSelectorState();
}

class _AnimeDetailSelectorState extends State<AnimeDetailSelector> {
  String? selectedEpisode;
  String? selectedQuality;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(
                  10.0,
                ),
                child: Text(
                  widget.media.title?.english ??
                      widget.media.title?.romaji ??
                      '',
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(
                  10,
                ),
                child: Text(
                  'Select Episode:',
                ),
              ),
              DropdownButton<String>(
                value: selectedEpisode,
                items: List<String>.generate(
                  widget.media.episodes ?? 12,
                  (int i) => (i + 1).toString().padLeft(
                        2,
                        '0',
                      ),
                ).map((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                    ),
                  );
                }).toList(),
                onChanged: (String? episode) {
                  setState(
                    () {
                      selectedEpisode = episode;
                    },
                  );
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(
                  10.0,
                ),
                child: Text(
                  'Select Quality:',
                ),
              ),
              DropdownButton<String>(
                value: selectedQuality,
                items: <String>[
                  '480',
                  '720',
                  '1080',
                ].map(
                  (
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                      ),
                    );
                  },
                ).toList(),
                onChanged: (String? quality) {
                  setState(
                    () {
                      selectedQuality = quality;
                    },
                  );
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(
              10.0,
            ),
            child: ElevatedButton(
              onPressed: (selectedEpisode != null && selectedQuality != null)
                  ? () {
                      AnimatedDialog.of(context)?.slideOut().then(
                        (_) {
                          Navigator.pop(context);
                          checkCache(
                            '${widget.media.id}_${selectedQuality}_$selectedEpisode',
                          ).then(
                            (isCached) => {
                              if (isCached != '')
                                {playerPageNav(context, isCached)}
                              else
                                {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AnimatedDialog(
                                        child: AlertDialog(
                                          content: SizedBox(
                                            width: double.maxFinite,
                                            height: double.maxFinite,
                                            child: FutureBuilder<
                                                List<List<String>>>(
                                              future: siteSearch(
                                                '2',
                                                '0_0',
                                                widget.media.title?.romaji ??
                                                    widget
                                                        .media.title?.native ??
                                                    '',
                                                selectedEpisode!,
                                                selectedQuality!,
                                              ),
                                              builder: (
                                                BuildContext context,
                                                AsyncSnapshot<
                                                        List<List<String>>>
                                                    snapshot,
                                              ) {
                                                if (snapshot.hasData) {
                                                  return ListView.builder(
                                                    itemCount:
                                                        snapshot.data!.length,
                                                    itemBuilder: (
                                                      BuildContext context,
                                                      int index,
                                                    ) {
                                                      return ListTile(
                                                        title: Text(
                                                          snapshot.data![index]
                                                              [0],
                                                        ),
                                                        onTap: () {
                                                          AnimatedDialog.of(
                                                            context,
                                                          )?.slideOut().then(
                                                            (_) {
                                                              Navigator.pop(
                                                                context,
                                                              );
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                barrierDismissible:
                                                                    false,
                                                                builder: (
                                                                  BuildContext
                                                                      context,
                                                                ) {
                                                                  return AnimatedDialog(
                                                                    child: StreamBuilder<
                                                                        String>(
                                                                      stream:
                                                                          download(
                                                                        widget.media.title?.romaji ??
                                                                            widget.media.title?.native ??
                                                                            '',
                                                                        widget
                                                                            .media
                                                                            .id
                                                                            .toString(),
                                                                        selectedEpisode!,
                                                                        selectedQuality!,
                                                                        snapshot.data![index]
                                                                            [1],
                                                                      ),
                                                                      builder: (
                                                                        BuildContext
                                                                            context,
                                                                        AsyncSnapshot<String>
                                                                            snapshot,
                                                                      ) {
                                                                        if (snapshot.connectionState ==
                                                                            ConnectionState
                                                                                .waiting) {
                                                                          return const AlertDialog(
                                                                            content:
                                                                                Column(
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              children: <Widget>[
                                                                                Padding(
                                                                                  padding: EdgeInsets.all(
                                                                                    10.0,
                                                                                  ),
                                                                                  child: Text(
                                                                                    'Starting download...',
                                                                                  ),
                                                                                ),
                                                                                CircularProgressIndicator(),
                                                                              ],
                                                                            ),
                                                                          );
                                                                        } else if (snapshot.connectionState ==
                                                                            ConnectionState
                                                                                .active) {
                                                                          double
                                                                              progress =
                                                                              double.parse(
                                                                            snapshot.data ??
                                                                                '0',
                                                                          );
                                                                          return AlertDialog(
                                                                            content:
                                                                                Column(
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              children: <Widget>[
                                                                                Padding(
                                                                                  padding: const EdgeInsets.all(
                                                                                    10.0,
                                                                                  ),
                                                                                  child: Text(
                                                                                    'Progress: ${(progress * 100).round().toString()}%',
                                                                                  ),
                                                                                ),
                                                                                LinearProgressIndicator(
                                                                                  value: progress,
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          );
                                                                        } else if (snapshot.connectionState ==
                                                                            ConnectionState.done) {
                                                                          WidgetsBinding
                                                                              .instance
                                                                              .addPostFrameCallback(
                                                                            (_) {
                                                                              AnimatedDialog.of(
                                                                                context,
                                                                              )?.slideOut().then(
                                                                                (_) {
                                                                                  Navigator.pop(
                                                                                    context,
                                                                                  );
                                                                                  playerPageNav(
                                                                                    context,
                                                                                    snapshot.data!,
                                                                                  );
                                                                                },
                                                                              );
                                                                            },
                                                                          );
                                                                          return Container();
                                                                        } else {
                                                                          return Container();
                                                                        }
                                                                      },
                                                                    ),
                                                                  );
                                                                },
                                                              );
                                                            },
                                                          );
                                                        },
                                                      );
                                                    },
                                                  );
                                                } else if (snapshot.hasError) {
                                                  return Text(
                                                    '${snapshot.error}',
                                                  );
                                                }
                                                return const Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: <Widget>[
                                                    CircularProgressIndicator(),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                },
                            },
                          );
                        },
                      );
                    }
                  : null,
              child: const Text('Download and Play'),
            ),
          ),
        ],
      ),
    );
  }
}

void playerPageNav(BuildContext context, String filePath) {
  Navigator.of(context).push(
    PageRouteBuilder<dynamic>(
      pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) =>
          PlayerPage(filePath: filePath),
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        Offset begin = const Offset(0.0, 1.0);
        Offset end = Offset.zero;
        Cubic curve = Curves.ease;
        Animatable<Offset> tween = Tween<Offset>(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    ),
  );
}
