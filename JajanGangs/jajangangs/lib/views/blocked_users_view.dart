import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/social_safety_service.dart';

class BlockedUsersView extends StatefulWidget {
  const BlockedUsersView({super.key, required this.uid});
  final String uid;
  @override
  State<BlockedUsersView> createState() => _BlockedUsersViewState();
}

class _BlockedUsersViewState extends State<BlockedUsersView> {
  final items = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  DocumentSnapshot<Map<String, dynamic>>? cursor;
  bool busy = false, more = true, failed = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (busy) return;
    setState(() {
      busy = true;
      failed = false;
    });
    try {
      Query<Map<String, dynamic>> q = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('blocks')
          .orderBy(FieldPath.documentId);
      if (cursor != null) q = q.startAfterDocument(cursor!);
      final page = await q
          .limit(20)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        items.addAll(page.docs);
        if (page.docs.isNotEmpty) cursor = page.docs.last;
        more = page.docs.length == 20;
      });
    } catch (_) {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> unblock(String peer) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await SocialSafetyService().unblock(widget.uid, peer);
      if (mounted) setState(() => items.removeWhere((d) => d.id == peer));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.socialFailed)));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.blockedUsers)),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(context.l10n.unblockHint),
        if (busy) const LinearProgressIndicator(),
        if (!busy && !failed && items.isEmpty) Text(context.l10n.blockedEmpty),
        for (final doc in items)
          ListTile(
            title: Text(doc.data()['name'] as String),
            trailing: TextButton(
              onPressed: busy ? null : () => unblock(doc.id),
              child: Text(context.l10n.unblockUser),
            ),
          ),
        if (failed) Text(context.l10n.socialFailed),
        if (more || failed)
          TextButton(
            onPressed: busy ? null : load,
            child: Text(
              failed ? context.l10n.retry : context.l10n.socialLoadMore,
            ),
          ),
      ],
    ),
  );
}
