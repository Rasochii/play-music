import 'package:flutter/material.dart';
import 'package:play_music/models/audio_model.dart';
import 'dart:io';
import 'package:play_music/utils/utils.dart' show pickFolder, convertMetadata;
import '../widgets/audio_controller.dart';
import 'package:rive_animated_icon/rive_animated_icon.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<AudioControllerState> _playerKey =
      GlobalKey<AudioControllerState>();
  List<Audio> musics = [];
  int? currentIndex;

  Future<void> musicList() async {
    String? directory = await pickFolder();
    if (directory != null) {
      final dir = Directory(directory);
      final files = dir.listSync(recursive: false).whereType<File>().toList();

      var fileList = files.where((file) {
        final path = file.path.toLowerCase();
        return path.endsWith('.mp3') ||
            path.endsWith('.wav') ||
            path.endsWith('.aac') ||
            path.endsWith('.ogg') ||
            path.endsWith('.m4a');
      }).toList();

      List<Audio> list = await convertMetadata(fileList);

      setState(() {
        musics = list;
      });
    } else {
      setState(() {
        musics = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Play Music',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              if (_playerKey.currentState != null) {
                _playerKey.currentState!.disposePlayer();
              }

              setState(() {
                musics = [];
                currentIndex = null;
              });

              await musicList();
            },
            tooltip: 'Recarregar',
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          (musics.isEmpty)
              ? Center(
                  child: Column(
                    children: [
                      const Text(
                        'Selecione a pasta com as músicas',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      Image.asset(
                        'assets/images/music_folder.png',
                        width: 200,
                        height: 200,
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await musicList();

                          if (musics.isEmpty) {
                            const snackBar = SnackBar(
                              content: Text(
                                'Pasta vazia',
                                style: TextStyle(fontSize: 16),
                              ),
                            );

                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          minimumSize: const Size(300, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text(
                          'Selecionar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      )
                    ],
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: musics.length,
                    itemBuilder: (BuildContext context, int index) {
                      final audio = musics[index];
                      return ListTile(
                        leading: const Icon(Icons.music_note),
                        trailing: (currentIndex == index)
                            ? const RiveAnimatedIcon(
                                riveIcon: RiveIcon.sound,
                                color: Colors.blue,
                                width: 40,
                                height: 40,
                              )
                            : null,
                        title: Text(audio.name,
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(audio.artist ?? 'Artista desconhecido'),
                        onTap: () {
                          if (_playerKey.currentState != null) {
                            _playerKey.currentState!.playFromIndex(index);
                            setState(() {
                              currentIndex = index;
                            });
                          } else {
                            setState(() {
                              currentIndex = index;
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
          if (currentIndex != null)
            AudioController(
              key: _playerKey,
              musics: musics,
              initialIndex: currentIndex!,
              onIndexChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
            ),
        ],
      ),
    );
  }
}
