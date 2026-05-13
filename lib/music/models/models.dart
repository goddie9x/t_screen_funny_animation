class Song {
  final String id;
  final String title;
  final String artist;
  final String genre;
  final String album;
  final int durationMs;
  final String filePath;
  final int fileSize;

  Song({required this.id, required this.title, required this.artist, required this.genre, required this.album, required this.durationMs, required this.filePath, required this.fileSize});
}

class Playlist {
  final String id;
  final String name;
  final bool isCustom;
  final List<Song> songs;

  Playlist({required this.id, required this.name, required this.isCustom, required this.songs});
}
