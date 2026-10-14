import 'package:flutter/material.dart';

import 'chat_inbox_view.dart';

// Compatibility entry point; the old fixed-size Gang list is now the inbox.
class GangListView extends StatelessWidget {
  const GangListView({super.key, required this.uid});
  final String uid;
  @override
  Widget build(BuildContext context) => ChatInboxView(uid: uid);
}
