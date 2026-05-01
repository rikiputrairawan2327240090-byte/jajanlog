import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jajanlog/models/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class PostService {
  static final FirebaseFirestore _database = FirebaseFirestore.instance;
  static final CollectionReference _postsCollection =
      _database.collection('posts');

  static Future<void> addPost(Post post) async {
    await _postsCollection.add({
      'image_base_64': post.imageBase64,
      'description': post.description,
      'category': post.category,
      'latitude': post.latitude,
      'longitude': post.longitude,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'user_id': post.userId,
      'user_full_name': post.userFullName,
    });
  }

  static Future<XFile?> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    return await picker.pickImage(
      source: source,
      imageQuality: 20,
    );
  }

  static Future<String> convertToBase64(XFile file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Future<void> openInMaps(double? latitude, double? longitude) async {
    if (latitude == null || longitude == null) return;

    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }


  static Future<void> deletePost(Post post) async {
    if (post.id == null) return;
    await _postsCollection.doc(post.id).delete();
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  static Stream<List<Post>> getPostList() {
    return _postsCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Post.fromDocument(doc)).toList());
  }
}