import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  String? id;
  String? imageBase64;
  final String category;
  final String description;
  Timestamp? createdAt;
  Timestamp? updatedAt;
  double? latitude;
  double? longitude;
  String? userId;
  String? userFullName;

  Post({
    this.id,
    this.imageBase64,
    required this.description,
    required this.category,
    this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
    this.userId,
    this.userFullName
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      imageBase64: data['image_base_64'],
      description: data['description'],
      category: data['category'],
      createdAt: data['created_at'] as Timestamp,
      updatedAt: data['updated_at'] as Timestamp,
      latitude: data['latitude'],
      longitude: data['longitude'],
      userId: data['user_id'],
      userFullName: data['user_full_name']
    );
  }

  Map<String, dynamic> toDocument() {
    return {
      'image_base_64': imageBase64,
      'description': description,
      'category': category,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'latitude': latitude,
      'longitude': longitude,
      'user_id': userId,
      'user_full_name': userFullName
    };
  }
}