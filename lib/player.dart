// ignore_for_file: library_private_types_in_public_api, unused_field

import 'dart:async';
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:streamer/repository/MusicBrainz/mbid.dart';
import 'package:streamer/utils/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class Player extends StatefulWidget {
  final String url;
  final String title;
  final String artist;
  final String album;

  const Player(
      {Key? key,
      required this.url,
      required this.title,
      required this.artist,
      required this.album})
      : super(key: key);

  @override
  _Player createState() => _Player();
}

class _Player extends State<Player> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  late ScrollController _scrollController;
  String songURL = "";
  bool hasCachedArt = false;

  @override
  void initState() {
    super.initState();
    _setSong();
    _play();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    super.dispose();
  }

  void _setSong() async {
    await _audioPlayer.setUrl(widget.url);
  }

  void _play() async {
    try {
      setState(() {
        _isPlaying = true;
      });
      await _audioPlayer.play();
    } catch (e) {
      log("error while playing: $e");
    }
  }

  void _pause() async {
    await _audioPlayer.pause();
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  Future getURL() async {
    String mBid = await fetchMBID(widget.album, widget.artist) ?? "";
    setState(() async {
      songURL = await fetchAlbumArtURL(mBid) ?? "";
    });
    debugPrint("songURL: $songURL");
  }

  Future<void> cacheImage() async {

    final Directory temp = await getTemporaryDirectory();
    final File imageFile = File('${temp.path}/images/someImageFile.png'); //

    if (await imageFile.exists()) {
    } else {
    await imageFile.create(recursive: true);
    }
  }

  // Future<File> _fileFromImageUrl() async {
  //   final response = await http.get(Uri.parse('https://example.com/xyz.jpg)');
  //
  //       final documentDirectory = await getApplicationDocumentsDirectory();
  //
  //   final file = File(join(documentDirectory.path, 'imagetest.png'));
  //
  //   file.writeAsBytesSync(response.bodyBytes);
  //
  //   return file;
  // }


  Future<Widget> getImageData() async {
    String mBid = await fetchMBID(widget.album, widget.artist) ?? "";
    songURL = await fetchAlbumArtURL(mBid) ?? "";

    if (songURL == "") {
      return Image.asset('./assets/vinyl record.webp');
    } else {

      saveImageName(songURL, true);
      return Image.network(songURL);
    }
  }

  FutureBuilder albumArt() {
    return FutureBuilder(
      future: getImageData(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data as Widget;
        } else {
          return Center(
            child: LoadingAnimationWidget.staggeredDotsWave(
              // LoadingAnimationWidget that call the
              color: Colors.green, // staggeredDotsWave animation
              size: 50,
            ),
          );
        }
      },
    );
  }

  FutureBuilder getAlbumArt() {
    return FutureBuilder(
      builder: (context, snapshot) {
        if (songURL == "" && !hasCachedArt) {
          getURL();
          hasCachedArt = true;
          return Center(
            child: LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.green,
              size: 50,
            ),
          );
        } else {
          return CachedNetworkImage(
            imageUrl: songURL,
            placeholder: (context, url) =>
                Image.asset('./assets/vinyl record.webp'),
            errorWidget: (context, url, error) =>
                Image.asset('./assets/vinyl record.webp'),
          );
        }
      },
    );
  }

  Future<Widget> get1AlbumArt() async {
    if (songURL == "" && !hasCachedArt) {
      songURL = await getURL();
      hasCachedArt = true;
      return LoadingAnimationWidget.staggeredDotsWave(
        color: Colors.green,
        size: 50,
      );
    } else {
      return CachedNetworkImage(
        imageUrl: songURL,
        placeholder: (context, url) =>
            Image.asset('./assets/vinyl record.webp'),
        errorWidget: (context, url, error) =>
            Image.asset('./assets/vinyl record.webp'),
      );
    }
  }

  //////////////////////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Now Playing',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.black,
            Colors.teal,
          ]),
        ),
        child:
            Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          const Padding(padding: EdgeInsets.all(16.0)),
          // Album cover
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height / 3,
              child: Center(
                child: albumArt(),
              ),
            ),
          ),

          // Song title and artist
          Column(
            children: [
              PlatformText(
                widget.title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.white),
              ),
              PlatformText(
                widget.artist,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),

          // Seeker
          Column(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 30,
                child: StreamBuilder<Duration>(
                  stream: _audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    Duration progress = snapshot.data ?? const Duration();
                    return PlatformSlider(
                      activeColor: Colors.purple,
                      value: progress.inMilliseconds.toDouble(),
                      onChangeEnd: (double value) {
                        _audioPlayer
                            .seek(Duration(milliseconds: value.toInt()));
                      },
                      min: 0.0,
                      max: _audioPlayer.duration?.inMilliseconds.toDouble() ??
                          3.0,
                      onChanged: (value) {},
                    );
                  },
                ),
              ),
              Container(
                child: StreamBuilder<Duration>(
                    stream: _audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      Duration progress = snapshot.data ?? const Duration();

                      String sDuration =
                          "${_audioPlayer.duration?.inMinutes.remainder(60)}:${(_audioPlayer.duration?.inSeconds.remainder(60))}";
                      return Text(
                        "${progress.inMinutes.remainder(60)}: ${progress.inSeconds.remainder(60)} / $sDuration",
                        style: const TextStyle(color: Colors.white),
                      );
                    }),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                fit: FlexFit.tight,
                child: PlatformIconButton(
                  materialIcon: const Icon(
                    Icons.skip_previous,
                    color: Colors.white,
                  ),
                  cupertinoIcon: const Icon(
                    CupertinoIcons.backward,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
              ),
              Flexible(
                fit: FlexFit.tight,
                child: PlatformElevatedButton(
                  material: (context, platform) {
                    return MaterialElevatedButtonData(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.teal),
                          shape: MaterialStateProperty.all<CircleBorder>(
                              const CircleBorder())),
                    );
                  },
                  cupertino: (context, platform) {
                    return CupertinoElevatedButtonData(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(60),
                    );
                  },
                  color: Colors.teal,
                  child: _isPlaying
                      ? const Icon(Icons.pause)
                      : const Icon(Icons.play_arrow),
                  onPressed: () {
                    _isPlaying ? _pause() : _play();
                    setState(() {
                      _isPlaying = !_isPlaying;
                    });
                  },
                ),
              ),
              Flexible(
                fit: FlexFit.tight,
                child: PlatformIconButton(
                  materialIcon: const Icon(
                    Icons.skip_next,
                    color: Colors.white,
                  ),
                  cupertinoIcon: const Icon(
                    CupertinoIcons.forward_end_alt,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
