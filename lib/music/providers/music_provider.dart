import 'package:flutter/material.dart';
import '../models/models.dart';

class MusicProvider extends ChangeNotifier {
  List<Song> allSongs = [
    Song(id: '1', title: 'A Little Love', artist: 'Fiona Fung', genre: 'Pop', album: 'A Little Love', durationMs: 210000, filePath: '/storage/emulated/0/Music/a_little_love.mp3', fileSize: 5200000),
    Song(id: '2', title: 'Senbonzakura', artist: 'Hatsune Miku', genre: 'Vocaloid', album: 'Vocaloid Hits', durationMs: 245000, filePath: '/storage/emulated/0/Music/senbonzakura.mp3', fileSize: 6100000),
    Song(id: '3', title: 'Pirates of the Caribbean', artist: 'Hans Zimmer', genre: 'Soundtrack', album: 'OST', durationMs: 185000, filePath: '/storage/emulated/0/Music/pirates.mp3', fileSize: 4500000),
    Song(id: '4', title: 'Mẹ Yêu Con', artist: 'Anh Thơ', genre: 'Folk', album: 'Nhạc Quê Hương', durationMs: 280000, filePath: '/storage/emulated/0/Music/me_yeu_con.mp3', fileSize: 7000000),
  ];

  List<Playlist> customPlaylists = [];
  List<Song> currentQueue = [];
  Song? currentSong;

  MusicProvider() {
    if (allSongs.isNotEmpty) {
      currentSong = allSongs[0];
      currentQueue = List.from(allSongs);
    }
  }

  List<Playlist> get artistPlaylists {
    Map<String, List<Song>> map = {};
    for (var s in allSongs) {
      map.putIfAbsent(s.artist, () => []).add(s);
    }
    return map.entries.map((e) => Playlist(id: 'artist_${e.key}', name: e.key, isCustom: false, songs: e.value)).toList();
  }

  List<Playlist> get genrePlaylists {
    Map<String, List<Song>> map = {};
    for (var s in allSongs) {
      map.putIfAbsent(s.genre, () => []).add(s);
    }
    return map.entries.map((e) => Playlist(id: 'genre_${e.key}', name: e.key, isCustom: false, songs: e.value)).toList();
  }

  void createCustomPlaylist(String name) {
    customPlaylists.add(Playlist(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, isCustom: true, songs: []));
    notifyListeners();
  }

  void addSongToCustomPlaylist(String playlistId, Song song) {
    final idx = customPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1 && !customPlaylists[idx].songs.any((s) => s.id == song.id)) {
      customPlaylists[idx].songs.add(song);
      notifyListeners();
    }
  }

  void removeSongFromPlaylist(String playlistId, String songId) {
    final idx = customPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      customPlaylists[idx].songs.removeWhere((s) => s.id == songId);
      notifyListeners();
    }
  }

  void addToQueue(Song song) {
    if (!currentQueue.any((s) => s.id == song.id)) {
      currentQueue.add(song);
      notifyListeners();
    }
  }

  void removeFromQueue(String songId) {
    currentQueue.removeWhere((s) => s.id == songId);
    notifyListeners();
  }

  void playSong(Song song) {
    currentSong = song;
    notifyListeners();
  }
}
