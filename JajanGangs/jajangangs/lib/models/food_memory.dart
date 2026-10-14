import 'package:cloud_firestore/cloud_firestore.dart';

class FoodMemory {
  FoodMemory(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
  String get restaurant => data['restaurant'] as String;
  String get area => data['area'] as String? ?? '';
  String get dish => data['dish'] as String;
  String get review => data['review'] as String;
  int get rating => data['rating'] as int;
  bool get again => data['again'] == true;
  String get visibility => data['visibility'] as String;
  DateTime get visited => (data['visitedAt'] as Timestamp).toDate().toUtc();
}
