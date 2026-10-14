import 'package:cloud_firestore/cloud_firestore.dart';

class FoodWheel {
  FoodWheel(this.data);
  final Map<String, dynamic> data;
  String get round => data['roundId'] as String;
  String get creator => data['creatorId'] as String;
  String get creatorName => data['creatorName'] as String;
  bool get closed => data['status'] == 'CLOSED';
  Map<String, dynamic> get choices =>
      Map<String, dynamic>.from(data['choices'] as Map);
  List<String> get uids => choices.keys.toList()..sort();
  String get winner => data['winnerUid'] as String;
  String food(String uid) => (choices[uid] as Map)['food'] as String;
  String name(String uid) => (choices[uid] as Map)['name'] as String;
  String? avatar(String uid) => (choices[uid] as Map)['avatarId'] as String?;
  DateTime? get spunAt => (data['spunAt'] as Timestamp?)?.toDate();
}
