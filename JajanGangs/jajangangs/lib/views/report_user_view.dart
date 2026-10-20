import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/social_safety_service.dart';

class ReportUserView extends StatefulWidget {
  const ReportUserView({
    super.key,
    required this.uid,
    required this.peer,
    this.eventId,
  });
  final String uid, peer;
  final String? eventId;
  @override
  State<ReportUserView> createState() => _ReportUserViewState();
}

class _ReportUserViewState extends State<ReportUserView> {
  final details = TextEditingController();
  final reportId = FirebaseFirestore.instance
      .collection('user_reports')
      .doc()
      .id;
  String reason = 'spam';
  bool busy = false, failed = false;
  @override
  void dispose() {
    details.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    setState(() {
      busy = true;
      failed = false;
    });
    try {
      await SocialSafetyService().report(
        widget.uid,
        widget.peer,
        reason,
        details.text,
        reportId,
        eventId: widget.eventId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.reportSent)));
      Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.reportUser)),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(context.l10n.reportHint),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: reason,
          isExpanded: true,
          borderRadius: BorderRadius.circular(22),
          dropdownColor: const Color(0xFFFFFAEF),
          elevation: 12,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF176F72),
          ),
          style: const TextStyle(
            color: Color(0xFF102C42),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.flag_outlined,
              color: Color(0xFF176F72),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFD6E5DD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFF176F72), width: 2),
            ),
          ),
          items: [
            for (final key in ['spam', 'harassment', 'unsafe', 'other'])
              DropdownMenuItem(
                value: key,
                child: Text(context.l10n.message('reportReason_$key')),
              ),
          ],
          onChanged: busy ? null : (value) => setState(() => reason = value!),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: details,
          enabled: !busy,
          maxLength: 500,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(labelText: context.l10n.reportDetails),
        ),
        if (failed)
          Text(
            context.l10n.socialFailed,
            style: const TextStyle(color: Colors.red),
          ),
        FilledButton(
          onPressed: busy ? null : submit,
          child: Text(busy ? context.l10n.loading : context.l10n.reportSubmit),
        ),
      ],
    ),
  );
}
