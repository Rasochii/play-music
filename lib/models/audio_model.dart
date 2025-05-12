class Audio {
  final String path;
  final String name;
  final String? artist;
  final Duration? duration;

  Audio({
    required this.path,
    required this.name,
    this.artist,
    this.duration,
  });
}
