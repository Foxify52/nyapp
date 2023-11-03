import 'dart:io';

import 'package:anilist_api/anilist.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:nyapp/utils.dart';
import 'package:nyapp/widgets/animations.dart';
import 'package:nyapp/widgets/common.dart';

class AnimeCarousel extends StatelessWidget {
  const AnimeCarousel({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AnilistQueryResult<AnilistMedia>>(
      future: anilistTrending(),
      builder: (
        BuildContext context,
        AsyncSnapshot<AnilistQueryResult<AnilistMedia>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          AnilistQueryResult<AnilistMedia> result = snapshot.data!;
          return CarouselSlider.builder(
            itemCount: result.results!.length,
            itemBuilder:
                (BuildContext context, int itemIndex, int pageViewIndex) {
              AnilistMedia media = result.results![itemIndex];
              return GestureDetector(
                onTap: () {
                  anilistSearch(name: media.title!.romaji ?? '').then((_) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AnimatedDialog(
                          child: AnimeDetailSelector(
                            media: media,
                          ),
                        );
                      },
                    );
                  });
                },
                child: FutureBuilder<File>(
                  future: DefaultCacheManager()
                      .getSingleFile(media.coverImage?.medium ?? ''),
                  builder:
                      (BuildContext context, AsyncSnapshot<File> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(),
                          ),
                        ],
                      );
                    } else if (snapshot.hasError) {
                      return const Center(
                        child: Text('Error loading image'),
                      );
                    } else {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        width: 100,
                        height: 200,
                        child: Stack(
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10.0),
                                topRight: Radius.circular(10.0),
                              ),
                              child: FittedBox(
                                child: Image.file(
                                  snapshot.data!,
                                  width: 100,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 150,
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: LayoutBuilder(
                                builder: (
                                  BuildContext context,
                                  BoxConstraints constraints,
                                ) {
                                  final String text = media.title?.english ??
                                      media.title!.romaji!;
                                  final TextStyle style =
                                      DefaultTextStyle.of(context).style;
                                  double scale = 1.0;
                                  while (scale > 0.0) {
                                    final TextSpan span = TextSpan(
                                      style: style.copyWith(
                                        fontSize: style.fontSize! * scale,
                                      ),
                                      text: text,
                                    );
                                    final TextPainter tp = TextPainter(
                                      text: span,
                                      maxLines: null,
                                      textDirection: TextDirection.ltr,
                                    );
                                    tp.layout(
                                      maxWidth: constraints.maxWidth,
                                    );
                                    if (tp.height > constraints.maxHeight) {
                                      scale -= 0.1;
                                      continue;
                                    }
                                    break;
                                  }
                                  return Text(
                                    text,
                                    textAlign: TextAlign.center,
                                    style: style.copyWith(
                                      fontSize: style.fontSize! * scale,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              );
            },
            options: CarouselOptions(
              height: 200,
              viewportFraction: (120 /
                  ((double.parse(
                                MediaQuery.of(context)
                                    .size
                                    .width
                                    .toStringAsFixed(0),
                              ) /
                              120)
                          .floor() *
                      120)),
              enableInfiniteScroll: true,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 6),
              scrollDirection: Axis.horizontal,
            ),
          );
        }
      },
    );
  }
}

class HistoryCarousel extends StatelessWidget {
  const HistoryCarousel({super.key});

  Future<List<AnilistMedia>> getLocalHistory() async {
    final List<String> localHistory =
        (await PrefsManager.readData('localHistory') ?? <String>[]);

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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AnilistMedia>>(
      future: getLocalHistory(),
      builder:
          (BuildContext context, AsyncSnapshot<List<AnilistMedia>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List<AnilistMedia> mediaList = snapshot.data!;
          if (mediaList.isNotEmpty) {
            return CarouselSlider.builder(
              itemCount: mediaList.length,
              itemBuilder:
                  (BuildContext context, int itemIndex, int pageViewIndex) {
                AnilistMedia media = mediaList[itemIndex];
                return GestureDetector(
                  onTap: () {
                    anilistSearch(name: media.title!.romaji ?? '').then((_) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AnimatedDialog(
                            child: AnimeDetailSelector(
                              media: media,
                            ),
                          );
                        },
                      );
                    });
                  },
                  child: FutureBuilder<File>(
                    future: DefaultCacheManager()
                        .getSingleFile(media.coverImage?.medium ?? ''),
                    builder:
                        (BuildContext context, AsyncSnapshot<File> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(),
                            ),
                          ],
                        );
                      } else if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading image'),
                        );
                      } else {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          width: 100,
                          height: 200,
                          child: Stack(
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10.0),
                                  topRight: Radius.circular(10.0),
                                ),
                                child: FittedBox(
                                  child: Image.file(
                                    snapshot.data!,
                                    width: 100,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 150,
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: LayoutBuilder(
                                  builder: (
                                    BuildContext context,
                                    BoxConstraints constraints,
                                  ) {
                                    final String text = media.title?.english ??
                                        media.title!.romaji!;
                                    final TextStyle style =
                                        DefaultTextStyle.of(context).style;
                                    double scale = 1.0;
                                    while (scale > 0.0) {
                                      final TextSpan span = TextSpan(
                                        style: style.copyWith(
                                          fontSize: style.fontSize! * scale,
                                        ),
                                        text: text,
                                      );
                                      final TextPainter tp = TextPainter(
                                        text: span,
                                        maxLines: null,
                                        textDirection: TextDirection.ltr,
                                      );
                                      tp.layout(
                                        maxWidth: constraints.maxWidth,
                                      );
                                      if (tp.height > constraints.maxHeight) {
                                        scale -= 0.1;
                                        continue;
                                      }
                                      break;
                                    }
                                    return Text(
                                      text,
                                      textAlign: TextAlign.center,
                                      style: style.copyWith(
                                        fontSize: style.fontSize! * scale,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                );
              },
              options: CarouselOptions(
                height: 200,
                viewportFraction: (120 /
                    ((double.parse(
                                  MediaQuery.of(context)
                                      .size
                                      .width
                                      .toStringAsFixed(0),
                                ) /
                                120)
                            .floor() *
                        120)),
                enableInfiniteScroll: false,
                scrollDirection: Axis.horizontal,
              ),
            );
          } else {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('No history found.'),
              ),
            );
          }
        }
      },
    );
  }
}
