import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jajanlog/models/post.dart';
import 'package:jajanlog/screens/add_post_screen.dart';
import 'package:jajanlog/screens/detail_screen.dart';
import 'package:jajanlog/services/post_services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _accent = Color(0xFFE8622A);
  final _searchController = TextEditingController();

  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  final List<String> _categories = [
    'Semua',
    'Warung',
    'Kaki Lima',
    'Kedai',
    'Restoran',
    'Lainnya',
  ];

  String get _userInitials {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final parts = user.displayName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    return user?.email?.substring(0, 1).toUpperCase() ?? 'U';
  }

  String get _userName {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!.split(' ').first;
    }
    return user?.email?.split('@').first ?? 'Pengguna';
  }

  List<Post> _applyFilter(List<Post> posts) {
    return posts.where((p) {
      final matchCat =
          _selectedCategory == 'Semua' || p.category == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) await PostService.signOut();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'JajanLog',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _accent,
                            ),
                          ),
                          Text(
                            'Halo, $_userName 👋',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF888888)),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _confirmSignOut,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFFEF0EA),
                          child: Text(
                            _userInitials,
                            style: const TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Cari makanan atau tempat...',
                      hintStyle: const TextStyle(
                          color: Color(0xFFBBBBBB), fontSize: 13),
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0xFFBBBBBB), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              })
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _accent
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? _accent
                                    : const Color(0xFFE0E0E0),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF666666),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<List<Post>>(
                stream: PostService.getPostList(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _accent),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final allPosts = snapshot.data ?? [];
                  final filtered = _applyFilter(allPosts);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🍽️', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            allPosts.isEmpty
                                ? 'Belum ada catatan kuliner'
                                : 'Tidak ada yang cocok',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF555555)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            allPosts.isEmpty
                                ? 'Mulai catat temuan jajananmu!'
                                : 'Coba kategori atau kata kunci lain',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF999999)),
                          ),
                        ],
                      ),
                    );
                  }

                  return CustomScrollView(
                    slivers: [
                      if (allPosts.isNotEmpty &&
                          _selectedCategory == 'Semua' &&
                          _searchQuery.isEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Temuan Terbaru',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                Text(
                                  '${allPosts.length} tempat',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: _accent,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 155,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemCount: allPosts.take(5).length,
                              itemBuilder: (_, i) {
                                final post = allPosts[i];
                                return _HorizontalPostCard(
                                  post: post,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            DetailScreen(post: post)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                            child: Text(
                              'Semua Catatanku',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        ),
                      ] else
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                            child: Text(
                              '${filtered.length} hasil ditemukan',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF888888)),
                            ),
                          ),
                        ),

                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final post = filtered[i];
                            return _PostListItem(
                              post: post,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => DetailScreen(post: post)),
                              ),
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPostScreen()),
        ),
        backgroundColor: _accent,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class _HorizontalPostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;

  const _HorizontalPostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0F0F0), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 80,
                width: double.infinity,
                child: post.imageBase64 != null && post.imageBase64!.isNotEmpty
                    ? Image.memory(
                        base64Decode(post.imageBase64!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF222222)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF0EA),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      post.category,
                      style: const TextStyle(
                          fontSize: 8,
                          color: Color(0xFFE8622A),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF8E8D8),
      child: const Center(
          child: Text('🍜', style: TextStyle(fontSize: 28))),
    );
  }
}

class _PostListItem extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;

  const _PostListItem({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0F0F0), width: 0.5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 60,
                height: 60,
                child: post.imageBase64 != null && post.imageBase64!.isNotEmpty
                    ? Image.memory(
                        base64Decode(post.imageBase64!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: Color(0xFF999999)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          post.latitude != null && post.longitude != null
                              ? '${post.latitude!.toStringAsFixed(4)}, ${post.longitude!.toStringAsFixed(4)}'
                              : 'Lokasi tidak tersedia',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF999999)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF0EA),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          post.category,
                          style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFFE8622A),
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        post.userFullName ?? '',
                        style: const TextStyle(
                            fontSize: 9, color: Color(0xFFBBBBBB)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFFCCCCCC), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF8E8D8),
      child: const Center(
          child: Text('🍜', style: TextStyle(fontSize: 24))),
    );
  }
}