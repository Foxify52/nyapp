import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:nyapp/utils.dart';
import 'package:anilist_api/anilist.dart';
import 'package:nyapp/widgets/animations.dart';
import 'package:nyapp/widgets/carousels.dart';
import 'package:nyapp/widgets/common.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? selectedEpisode;
  String? selectedQuality;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    onSubmitted: (String value) {
                      if (value.isNotEmpty) {
                        anilistSearch(name: value).then(
                          (AnilistQueryResult<AnilistMedia> result) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AnimatedDialog(
                                  child: AlertDialog(
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        itemCount: result.results!.length,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          AnilistMedia media =
                                              result.results![index];
                                          return ListTile(
                                            title: Row(
                                              children: <Widget>[
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    10.0,
                                                  ),
                                                  child: FutureBuilder<File>(
                                                    future:
                                                        DefaultCacheManager()
                                                            .getSingleFile(
                                                      media.coverImage
                                                              ?.medium ??
                                                          '',
                                                    ),
                                                    builder: (
                                                      BuildContext context,
                                                      AsyncSnapshot<File>
                                                          snapshot,
                                                    ) {
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return const Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: <Widget>[
                                                            SizedBox(
                                                              width: 40,
                                                              height: 40,
                                                              child:
                                                                  CircularProgressIndicator(),
                                                            ),
                                                          ],
                                                        );
                                                      } else {
                                                        if (snapshot.error !=
                                                            null) {
                                                          return const Center(
                                                            child: Text(
                                                              'Error loading image',
                                                            ),
                                                          );
                                                        } else {
                                                          return Image.file(
                                                            snapshot.data!,
                                                          );
                                                        }
                                                      }
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  media.title!.english ??
                                                      media.title!.romaji ??
                                                      'No Title',
                                                ),
                                              ],
                                            ),
                                            onTap: () {
                                              AnimatedDialog.of(context)
                                                  ?.slideOut()
                                                  .then((_) {
                                                Navigator.pop(context);
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AnimatedDialog(
                                                      child:
                                                          AnimeDetailSelector(
                                                        media: media,
                                                      ),
                                                    );
                                                  },
                                                );
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Search',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              height: 50,
              padding: const EdgeInsets.all(10.0),
              child: const Text(
                'Now trending:',
                style: TextStyle(fontSize: 20),
              ),
            ),
            const Padding(
              padding: EdgeInsetsDirectional.all(0.8),
              child: AnimeCarousel(),
            ),
            Container(
              height: 50,
              padding: const EdgeInsets.all(10.0),
              child: const Text(
                'Continue watching:',
                style: TextStyle(fontSize: 20),
              ),
            ),
            const HistoryCarousel(),
          ],
        ),
      ),
    );
  }
}
