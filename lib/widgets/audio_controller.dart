import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/audio_model.dart';

class AudioController extends StatefulWidget {
  final List<Audio> musics;
  final int initialIndex;
  final ValueChanged<int> onIndexChanged;

  const AudioController({
    super.key,
    required this.musics,
    required this.initialIndex,
    required this.onIndexChanged,
  });

  @override
  State<AudioController> createState() => AudioControllerState();
}

class AudioControllerState extends State<AudioController> {
  late AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _loadPlaylist();

    _player.currentIndexStream.listen((index) {
      if (index != null) {
        widget.onIndexChanged(index);
      }
    });
  }

  Future<void> _loadPlaylist() async {
    final playlist = ConcatenatingAudioSource(
      children: widget.musics
          .map((audio) => AudioSource.uri(Uri.file(audio.path)))
          .toList(),
    );

    await _player.setAudioSource(playlist, initialIndex: widget.initialIndex);
    await _player.play();
  }

  void playFromIndex(int index) async {
    await _player.seek(Duration.zero, index: index);
    await _player.play();
  }

  void disposePlayer() async {
    await _player.dispose();
  }

  void showAudioDetailsSheet() {
    final index = _player.currentIndex ?? 0;
    final audio = widget.musics[index];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.blue[800],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Imagem da capa
                  Container(
                    width: 250,
                    height: 250,
                    color: Colors.grey[300],
                    child: const Icon(Icons.music_note,
                        size: 100, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Nome da música
                  Text(
                    audio.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Nome do artista
                  Text(
                    audio.artist ?? 'Artista desconhecido',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Slider e tempo
                  StreamBuilder<Duration>(
                    stream: _player.positionStream,
                    builder: (context, snapshot) {
                      final current = snapshot.data ?? Duration.zero;
                      final total = _player.duration ?? Duration.zero;

                      return Column(
                        children: [
                          Slider(
                            value: current.inSeconds
                                .toDouble()
                                .clamp(0, total.inSeconds.toDouble()),
                            max: total.inSeconds.toDouble(),
                            onChanged: (value) {
                              _player.seek(Duration(seconds: value.toInt()));
                            },
                            activeColor: Colors.white,
                            inactiveColor: Colors.white30,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(current),
                                  style:
                                      const TextStyle(color: Colors.white70)),
                              Text(_formatDuration(total),
                                  style:
                                      const TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Botões de controle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous,
                            color: Colors.white),
                        iconSize: 36,
                        onPressed: () {
                          _player.seekToPrevious();
                        },
                      ),
                      StreamBuilder<PlayerState>(
                        stream: _player.playerStateStream,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data?.playing ?? false;
                          return IconButton(
                            icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white),
                            iconSize: 56,
                            onPressed: () {
                              if (isPlaying) {
                                _player.pause();
                              } else {
                                _player.play();
                              }
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        iconSize: 36,
                        onPressed: () {
                          _player.seekToNext();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue[800],
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: showAudioDetailsSheet,
            behavior: HitTestBehavior.opaque,
            child: StreamBuilder<SequenceState?>(
              stream: _player.sequenceStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                final current = state?.currentSource;
                final index = state?.currentIndex ?? 0;

                return Column(
                  children: [
                    if (current != null) ...[
                      Text(
                        widget.musics[index].name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.musics[index].artist ?? 'Artista desconhecido',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                color: Colors.white,
                iconSize: 36,
                onPressed: () async {
                  await _player.seekToPrevious();
                },
              ),
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final isPlaying = playerState?.playing ?? false;
                  final processingState = playerState?.processingState;

                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
                    return const SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  return IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    color: Colors.white,
                    iconSize: 56,
                    onPressed: () async {
                      if (isPlaying) {
                        await _player.pause();
                      } else {
                        await _player.play();
                      }
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                color: Colors.white,
                iconSize: 36,
                onPressed: () async {
                  await _player.seekToNext();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
