import 'package:flutter/material.dart';
import 'player_tab.dart';
import 'playlist_tab.dart';

class MusicMainScreen extends StatefulWidget {
  const MusicMainScreen({super.key});
  @override
  State<MusicMainScreen> createState() => _MusicMainScreenState();
}

class _MusicMainScreenState extends State<MusicMainScreen> {
  int _currentIndex = 0;
  final List<Widget> _tabs = [const PlayerTab(), const PlaylistTab(), const Center(child: Text('Cài đặt'))];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill), label: 'Trình phát'),
          BottomNavigationBarItem(icon: Icon(Icons.queue_music), label: 'Playlist'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
    );
  }
}
