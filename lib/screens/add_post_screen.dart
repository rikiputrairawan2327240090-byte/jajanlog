import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jajanlog/models/post.dart';
import 'package:jajanlog/services/post_services.dart';

class AddPostScreen extends StatefulWidget {
  final Post? postToEdit;

  const AddPostScreen({super.key, this.postToEdit});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  static const _accent = Color(0xFFE8622A);

  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();

  String _selectedCategory = 'Warung';
  String? _imageBase64;
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.postToEdit != null;

  final List<String> _categories = [
    'Warung',
    'Kaki Lima',
    'Kedai',
    'Restoran',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _descController.text = widget.postToEdit!.description;
      _selectedCategory = widget.postToEdit!.category;
      _imageBase64 = widget.postToEdit!.imageBase64;
      _latitude = widget.postToEdit!.latitude;
      _longitude = widget.postToEdit!.longitude;
    } else {
      _detectLocation();
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); 
    final file = await PostService.pickImage(source);
    if (file == null) return;
    final base64 = await PostService.convertToBase64(file);
    setState(() => _imageBase64 = base64);
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEF0EA),
                  child: Icon(Icons.camera_alt_outlined, color: _accent),
                ),
                title: const Text('Kamera'),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEF0EA),
                  child: Icon(Icons.photo_library_outlined, color: _accent),
                ),
                title: const Text('Galeri'),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              if (_imageBase64 != null)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade50,
                    child:
                        Icon(Icons.delete_outline, color: Colors.red.shade400),
                  ),
                  title: const Text('Hapus Foto'),
                  onTap: () {
                    setState(() => _imageBase64 = null);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _detectLocation() async {
    setState(() => _isLoadingLocation = true);
    final position = await PostService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _latitude = position?.latitude;
        _longitude = position?.longitude;
        _isLoadingLocation = false;
      });
      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Gagal mendapatkan lokasi. Pastikan GPS aktif & izin diberikan.'),
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (_isEditMode) {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postToEdit!.id)
            .update({
          'description': _descController.text.trim(),
          'category': _selectedCategory,
          'image_base_64': _imageBase64,
          'latitude': _latitude,
          'longitude': _longitude,
          'updated_at': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan berhasil diperbarui ✅'),
            backgroundColor: _accent,
          ),
        );
      } else {
        final post = Post(
          description: _descController.text.trim(),
          category: _selectedCategory,
          imageBase64: _imageBase64,
          latitude: _latitude,
          longitude: _longitude,
          userId: user?.uid,
          userFullName: user?.displayName ?? user?.email ?? 'Anonim',
        );
        await PostService.addPost(post);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Temuan berhasil dicatat! 🎉'),
            backgroundColor: _accent,
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Catatan' : 'Catat Temuan Baru'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Simpan',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF0EA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _accent.withOpacity(0.4),
                        width: 1,
                        style: BorderStyle.solid),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _imageBase64 != null && _imageBase64!.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              base64Decode(_imageBase64!),
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit,
                                        size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('Ganti',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.camera_alt_outlined,
                                  color: _accent, size: 28),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Tambah Foto Makanan',
                              style: TextStyle(
                                  color: _accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Ketuk untuk ambil / pilih foto',
                              style: TextStyle(
                                  color: Color(0xFFBBBBBB), fontSize: 11),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              _sectionLabel('Catatan / Deskripsi'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText:
                      'Ceritakan temuan jajananmu... rasa, suasana, tips, dll.',
                  hintStyle:
                      TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Deskripsi wajib diisi';
                  }
                  if (v.trim().length < 5) {
                    return 'Deskripsi terlalu singkat';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              _sectionLabel('Kategori'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _accent : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? _accent : const Color(0xFFDDDDDD),
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF555555),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              _sectionLabel('Lokasi'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFEEEEEE), width: 0.5),
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
                      child: _isLoadingLocation
                          ? const Row(
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    color: _accent, strokeWidth: 2
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Mendeteksi lokasi...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF888888)
                                  )
                                ),
                              ],
                            )
                          : _latitude != null && _longitude != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Lokasi terdeteksi',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF333333)),
                                    ),
                                    Text(
                                      '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF888888)),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Lokasi belum terdeteksi',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF888888)),
                                ),
                    ),
                    GestureDetector(
                      onTap: _isLoadingLocation ? null : _detectLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _latitude != null ? 'Ulang' : 'Deteksi',
                          style: const TextStyle(
                              color: _accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: Icon(
                    _isEditMode ? Icons.save_outlined : Icons.check_circle_outline,
                    size: 20),
                label: Text(
                  _isEditMode ? 'Simpan Perubahan' : 'Catat Temuan',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF333333),
      ),
    );
  }
}