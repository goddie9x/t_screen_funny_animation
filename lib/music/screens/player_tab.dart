import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../widgets/context_menu.dart';

class PlayerTab extends StatelessWidget {
  const PlayerTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final song = provider.currentSong;

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.green.shade900,
            child: Column(
              children: [
                if (song != null) ...[
                  Text(song.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(song.artist, style: const TextStyle(fontSize: 16, color: Colors.white70)),
                  const SizedBox(height: 20),
                  Slider(value: 0.3, onChanged: (v) {}, activeColor: Colors.lightGreenAccent),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.pause_circle_filled, color: Colors.white, size: 64), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.skip_next, color: Colors.white, size: 36), onPressed: () {}),
                    ],
                  ),
                ]
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            alignment: Alignment.centerLeft,
            child: const Text('Hàng đợi hiện tại', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: provider.currentQueue.length,
              itemBuilder: (context, index) {
                final s = provider.currentQueue[index];
                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(s.title),
                  subtitle: Text(s.artist),
                  trailing: s.id == song?.id ? const Icon(Icons.volume_up, color: Colors.green) : null,
                  onTap: () => provider.playSong(s),
                  onLongPress: () => ContextMenuHelper.showSongContextMenu(context, s, provider, 'queue'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
