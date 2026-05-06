import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jajanlog/models/post.dart';
import 'package:jajanlog/screens/add_post_screen.dart';
import 'package:jajanlog/services/post_services.dart';
import 'package:share_plus/share_plus.dart';

class DetailScreen extends StatelessWidget {
  final Post post;

  const DetailScreen({super.key, required this.post});

  static const _accent = Color(0xFFE8622A);

  String _formatDate(dynamic ts) {
    if (ts == null) return '-';
    final dt = ts.toDate();
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text('Yakin ingin menghapus catatan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await PostService.deletePost(post);
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _share() {
    final loc = (post.latitude != null && post.longitude != null)
        ? 'https://www.google.com/maps/search/?api=1&query=${post.latitude},${post.longitude}'
        : 'Lokasi tidak tersedia';

    Share.share(
      '🍜 JajanLog - Temuan Kuliner!\n\n'
      '📝 ${post.description}\n'
      '🏷️ ${post.category}\n'
      '👤 ${post.userFullName ?? "-"}\n'
      '📍 $loc\n\n'
      'Dicatat via JajanLog 🍜',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: post.imageBase64 != null &&
                          post.imageBase64!.isNotEmpty
                      ? Image.memory(
                          base64Decode(post.imageBase64!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _heroPlaceholder(),
                        )
                      : _heroPlaceholder(),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Color(0xFF1A1A1A), size: 20),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _iconBtn(
                        icon: Icons.share_outlined,
                        onTap: _share,
                      ),
                      const SizedBox(width: 8),
                      _iconBtn(
                        icon: Icons.delete_outline,
                        onTap: () => _confirmDelete(context),
                        color: Colors.red.shade400,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      post.category,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.description,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 14, color: Color(0xFF888888)),
                        const SizedBox(width: 4),
                        Text(
                          post.userFullName ?? 'Anonim',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF888888)),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.calendar_today_outlined,
                            size: 13, color: Color(0xFF888888)),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(post.createdAt),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF888888)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 16),

                    const Text(
                      'Lokasi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFF0F0F0), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF0EA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.location_on,
                                color: _accent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: post.latitude != null &&
                                    post.longitude != null
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${post.latitude!.toStringAsFixed(6)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF333333)),
                                      ),
                                      Text(
                                        '${post.longitude!.toStringAsFixed(6)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF888888)),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Lokasi tidak tersedia',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF888888)),
                                  ),
                          ),
                          if (post.latitude != null &&
                              post.longitude != null)
                            GestureDetector(
                              onTap: () => PostService.openInMaps(
                                  post.latitude, post.longitude),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _accent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Buka Maps',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddPostScreen(postToEdit: post),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Catatan',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: const Color(0xFFF5F5F5),
                        foregroundColor: const Color(0xFF555555),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Bagikan',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroPlaceholder() {
    return Container(
      color: const Color(0xFFF8E8D5),
      child: const Center(
        child: Text('🍜', style: TextStyle(fontSize: 64)),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color ?? const Color(0xFF1A1A1A), size: 20),
      ),
    );
  }
}