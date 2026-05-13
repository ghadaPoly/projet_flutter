import 'package:cloud_firestore/cloud_firestore.dart';

class CvModel {
  final String id;
  final String userId;
  final String fileName;
  final String extractedText;
  final List<String> keywords;
  final DateTime uploadDate;

  CvModel({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.extractedText,
    required this.keywords,
    required this.uploadDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fileName': fileName,
      'extractedText': extractedText,
      'keywords': keywords,
      'uploadDate': Timestamp.fromDate(uploadDate),
    };
  }

  factory CvModel.fromMap(Map<String, dynamic> map) {
    return CvModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      fileName: map['fileName'] ?? '',
      extractedText: map['extractedText'] ?? '',
      keywords: List<String>.from(map['keywords'] ?? []),
      uploadDate: (map['uploadDate'] as Timestamp).toDate(),
    );
  }
}