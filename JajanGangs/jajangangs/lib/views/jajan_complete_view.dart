import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'food_passport_view.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/jajan_event.dart';
import '../l10n/l10n.dart';
import '../widgets/character_avatar.dart';

class JajanCompleteView extends StatefulWidget {
  const JajanCompleteView({super.key, required this.event});
  final JajanEvent event;
  @override
  State<JajanCompleteView> createState() => _JajanCompleteViewState();
}

class _JajanCompleteViewState extends State<JajanCompleteView> {
  Future<QuerySnapshot<Map<String, dynamic>>> load() => FirebaseFirestore
      .instance
      .collection('jajan_events')
      .doc(widget.event.id)
      .collection('join_requests')
      .where('status', isEqualTo: 'ACCEPTED')
      .limit(12)
      .get()
      .timeout(const Duration(seconds: 15));
  late Future<QuerySnapshot<Map<String, dynamic>>> members = load();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF102C42),
    appBar: AppBar(
      backgroundColor: const Color(0xFF102C42),
      foregroundColor: Colors.white,
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xFFFFC647),
            size: 96,
          ),
          const SizedBox(height: 20),
          Text(
            context.l10n.eventCompleteTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFC647),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    context.l10n.eventCompleteWith,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ListTile(
                    leading: CharacterAvatar(
                      avatarId: widget.event.creatorAvatarId,
                      size: 42,
                    ),
                    title: Text(
                      widget.event.creatorName ?? context.l10n.foodie,
                    ),
                  ),
                  FutureBuilder(
                    future: members,
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return Column(
                          children: [
                            Text(context.l10n.chatMembersError),
                            TextButton(
                              onPressed: () => setState(() => members = load()),
                              child: Text(context.l10n.retry),
                            ),
                          ],
                        );
                      if (!snapshot.hasData)
                        return const LinearProgressIndicator();
                      return Column(
                        children: [
                          for (final member in snapshot.data!.docs)
                            ListTile(
                              leading: CharacterAvatar(
                                avatarId: member.data()['avatarId'] as String?,
                                size: 42,
                              ),
                              title: Text(
                                member.data()['name'] as String? ??
                                    context.l10n.foodie,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (FirebaseAuth.instance.currentUser != null)
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FoodMemoryEditor(
                    uid: FirebaseAuth.instance.currentUser!.uid,
                    eventId: widget.event.id,
                  ),
                ),
              ),
              icon: const Icon(Icons.restaurant_menu_rounded),
              label: Text(context.l10n.passportAdd),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: Text(context.l10n.eventDone),
          ),
        ],
      ),
    ),
  );
}
