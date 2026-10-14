import 'package:cloud_firestore/cloud_firestore.dart';

class Friendship {
  Friendship(this.doc);
  final DocumentSnapshot<Map<String, dynamic>> doc;
  Map<String, dynamic> get data => doc.data()!;
  String get status => data['status'] as String;
  String get from => data['fromId'] as String;
  String get to => data['toId'] as String;
  String peer(String uid) => uid == from ? to : from;
  String name(String uid) =>
      data[uid == from ? 'toName' : 'fromName'] as String;
  String avatar(String uid) =>
      data[uid == from ? 'toAvatarId' : 'fromAvatarId'] as String;
}
