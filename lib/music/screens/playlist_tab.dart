import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../widgets/context_menu.dart';

class PlaylistTab extends StatelessWidget {
  const PlaylistTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        child: Column(
          children: [
            const TabBar(
              labelColor: Colors.green,
              unselectedLabelColor: Colors.grey,
              tabs: [Tab(text: 'Tùy chỉnh'), Tab(text: 'Nhạc sỹ'), Tab(text: 'Thể loại')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildCustomPlaylists(context, provider),
                  _buildGroupedPlaylists(context, provider.artistPlaylists, provider),
                  _buildGroupedPlaylists(context, provider.genrePlaylists, provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomPlaylists(BuildContext context, MusicProvider provider) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.add_circle, color: Colors.green),
          title: const Text('Tạo Playlist mới', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          onTap: () {
            TextEditingController ctrl = TextEditingController();
            showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Tên Playlist'),
                content: TextField(controller: ctrl, autofocus: true),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c), child: const Text('Hủy')),
                  TextButton(
                    onPressed: () {
                      if (ctrl.text.isNotEmpty) provider.createCustomPlaylist(ctrl.text);
                      Navigator.pop(c);
                    },
                    child: const Text('Tạo'),
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(child: _buildGroupedPlaylists(context, provider.customPlaylists, provider)),
      ],
    );
  }

  Widget _buildGroupedPlaylists(BuildContext context, List<dynamic> playlists, MusicProvider provider) {
    return ListView.builder(
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final p = playlists[index];
        return ExpansionTile(
          leading: const Icon(Icons.album),
          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${p.songs.length} bài hát'),
          children: p.songs.map<Widget>((s) => ListTile(
            contentPadding: const EdgeInsets.only(left: 40, right: 16),
            title: Text(s.title),
            subtitle: Text(s.artist),
            onTap: () => provider.playSong(s),
            onLongPress: () => ContextMenuHelper.showSongContextMenu(context, s, provider, p.id),
          )).toList(),
        );
      },
    );
  }
}
