import 'package:flutter/material.dart';
import '../models/models.dart';
import '../providers/music_provider.dart';

class ContextMenuHelper {
  static void showSongContextMenu(BuildContext context, Song song, MusicProvider provider, String currentListId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text('${song.artist} • ${song.genre}'),
              leading: const CircleAvatar(child: Icon(Icons.music_note)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: const Text('Thêm vào hàng đợi hiện tại'),
              onTap: () { provider.addToQueue(song); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Thêm vào playlist tùy chỉnh'),
              onTap: () {
                Navigator.pop(ctx);
                _showCustomPlaylistSelector(context, song, provider);
              },
            ),
            if (currentListId != 'queue' && !currentListId.startsWith('artist_') && !currentListId.startsWith('genre_'))
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Xóa khỏi playlist', style: TextStyle(color: Colors.red)),
                onTap: () { provider.removeSongFromPlaylist(currentListId, song.id); Navigator.pop(ctx); },
              )
            else if (currentListId == 'queue')
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Xóa khỏi hàng đợi', style: TextStyle(color: Colors.red)),
                onTap: () { provider.removeFromQueue(song.id); Navigator.pop(ctx); },
              ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Chia sẻ'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang mở menu chia sẻ...')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Chi tiết'),
              onTap: () {
                Navigator.pop(ctx);
                _showSongDetailsDialog(context, song);
              },
            ),
          ],
        ),
      ),
    );
  }

  static void _showCustomPlaylistSelector(BuildContext context, Song song, MusicProvider provider) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Chọn Playlist'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.customPlaylists.length,
            itemBuilder: (ctx, i) {
              final p = provider.customPlaylists[i];
              return ListTile(
                title: Text(p.name),
                onTap: () {
                  provider.addSongToCustomPlaylist(p.id, song);
                  Navigator.pop(c);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã thêm vào ${p.name}')));
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Đóng'))],
      ),
    );
  }

  static void _showSongDetailsDialog(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Chi tiết bài hát'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${song.id}'),
              Text('Tên: ${song.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Nhạc sỹ: ${song.artist}'),
              Text('Thể loại: ${song.genre}'),
              Text('Album: ${song.album}'),
              Text('Thời lượng: ${(song.durationMs / 60000).toStringAsFixed(2)} phút'),
              Text('Kích thước: ${(song.fileSize / 1024 / 1024).toStringAsFixed(2)} MB'),
              const SizedBox(height: 10),
              const Text('Đường dẫn:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(song.filePath, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Đóng'))],
      ),
    );
  }
}
