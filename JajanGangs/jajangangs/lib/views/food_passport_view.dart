import '../widgets/game_dialog.dart';
import '../widgets/adventure_header.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../controllers/food_passport_controller.dart';
import '../models/food_memory.dart';
import '../models/auth_session.dart';
import '../services/food_passport_service.dart';
import '../widgets/dumpling_rating.dart';
import '../l10n/l10n.dart';

class FoodPassportView extends StatefulWidget {
  const FoodPassportView({
    super.key,
    required this.ownerId,
    required this.viewerId,
  });
  final String ownerId, viewerId;
  @override
  State<FoodPassportView> createState() => _FoodPassportViewState();
}

class _FoodPassportViewState extends State<FoodPassportView> {
  late final c = FoodPassportController(
    widget.ownerId,
    widget.ownerId == widget.viewerId,
  );
  @override
  void initState() {
    super.initState();
    c.load();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> edit([FoodMemory? memory]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FoodMemoryEditor(uid: widget.ownerId, memory: memory),
      ),
    );
    if (saved == true && mounted) c.load(reset: true);
  }

  final deleting = <String>{};
  Future<void> deleteMemory(FoodMemory memory) async {
    if (!c.mine || deleting.contains(memory.id)) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => GameDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: Text(context.l10n.passportDelete),
        content: Text(context.l10n.passportDeleteHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.back),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.passportDelete),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => deleting.add(memory.id));
    try {
      await FoodPassportService().delete(widget.ownerId, memory);
      if (mounted) c.load(reset: true);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.passportError)));
    } finally {
      if (mounted) setState(() => deleting.remove(memory.id));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final l = context.l10n;
      return Scaffold(
        backgroundColor: const Color(0xFFF1F6EC),
        appBar: AppBar(
          title: Text(l.passportTitle),
          backgroundColor: const Color(0xFF102C42),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: l.eventRefresh,
              onPressed: c.loading ? null : () => c.load(reset: true),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: c.mine
            ? FloatingActionButton.extended(
                onPressed: () => edit(),
                backgroundColor: const Color(0xFFFFC647),
                icon: const Icon(Icons.add),
                label: Text(l.passportAdd),
              )
            : null,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF102C42),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 52,
                    color: Color(0xFFFFC647),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.passportSummary(
                      c.items.length,
                      c.items
                          .map((e) => e.restaurant.trim().toLowerCase())
                          .toSet()
                          .length,
                      c.items.where((e) => e.again).length,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (c.loading) const LinearProgressIndicator(),
            if (c.error != null)
              TextButton(
                onPressed: () => c.load(reset: true),
                child: Text(l.message(c.error!)),
              ),
            if (!c.loading && c.error == null && c.items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  c.mine ? l.passportEmpty : l.passportFriendEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            for (final memory in c.items)
              Card(
                margin: const EdgeInsets.only(top: 16),
                color: const Color(0xFFFFFAEF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Color(0xFFFFC647), width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.ramen_dining_rounded,
                            size: 40,
                            color: Color(0xFF137F75),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  memory.dish,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  memory.restaurant,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          if (c.mine)
                            PopupMenuButton<String>(
                              enabled: !deleting.contains(memory.id),
                              icon: deleting.contains(memory.id)
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.more_horiz_rounded),
                              onSelected: (value) => value == 'delete'
                                  ? deleteMemory(memory)
                                  : edit(memory),
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: const Icon(Icons.edit_outlined),
                                    title: Text(l.passportEdit),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFFB44742),
                                    ),
                                    title: Text(l.passportDelete),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      DumplingRating(value: memory.rating),
                      if (memory.area.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.place_outlined, size: 18),
                              const SizedBox(width: 6),
                              Expanded(child: Text(memory.area)),
                            ],
                          ),
                        ),
                      if (memory.review.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            memory.review,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (memory.again)
                            Chip(
                              avatar: const Icon(Icons.favorite, size: 16),
                              label: Text(l.passportAgain),
                            ),
                          if (c.mine)
                            Chip(
                              avatar: Icon(
                                memory.visibility == 'private'
                                    ? Icons.lock
                                    : Icons.people,
                                size: 16,
                              ),
                              label: Text(
                                memory.visibility == 'private'
                                    ? l.passportPrivate
                                    : l.passportFriends,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        DateFormat.yMMMd(
                          Localizations.localeOf(context).languageCode,
                        ).format(memory.visited),
                      ),
                    ],
                  ),
                ),
              ),
            if (c.more && c.items.isNotEmpty)
              TextButton(
                onPressed: c.loading ? null : () => c.load(),
                child: Text(l.eventLoadMore),
              ),
          ],
        ),
      );
    },
  );
}

class FoodMemoryEditor extends StatefulWidget {
  const FoodMemoryEditor({
    super.key,
    required this.uid,
    this.memory,
    this.eventId,
  });
  final String uid;
  final FoodMemory? memory;
  final String? eventId;
  @override
  State<FoodMemoryEditor> createState() => _FoodMemoryEditorState();
}

class _FoodMemoryEditorState extends State<FoodMemoryEditor> {
  final service = FoodPassportService();
  late final id = widget.memory?.id ?? service.entries(widget.uid).doc().id;
  late final restaurant = TextEditingController(
    text: widget.memory?.restaurant ?? '',
  );
  late final area = TextEditingController(text: widget.memory?.area ?? '');
  late final dish = TextEditingController(text: widget.memory?.dish ?? '');
  late final review = TextEditingController(text: widget.memory?.review ?? '');
  late int rating = widget.memory?.rating ?? 0;
  late bool again = widget.memory?.again ?? false;
  late String visibility = widget.memory?.visibility ?? 'private';
  late DateTime visited = widget.memory?.visited ?? DateTime.now();
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    prefill();
  }

  Future<void> prefill() async {
    if (widget.eventId == null) return;
    try {
      final value = await service.destination(widget.eventId!);
      if (mounted && !busy && restaurant.text.isEmpty && value != null)
        restaurant.text = value;
    } catch (_) {
      /* Prefill is optional; manual entry always remains available. */
    }
  }

  @override
  void dispose() {
    restaurant.dispose();
    area.dispose();
    dish.dispose();
    review.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await service.save(widget.uid, id, {
        'restaurant': restaurant.text.trim(),
        'area': area.text.trim(),
        'dish': dish.text.trim(),
        'review': review.text.trim(),
        'rating': rating,
        'again': again,
        'visibility': visibility,
        'visitedAt': Timestamp.fromDate(
          DateTime.utc(visited.year, visited.month, visited.day),
        ),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        setState(() => error = e is AuthFailure ? e.message : 'passportError');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> remove() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => GameDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: Text(context.l10n.passportDelete),
        content: Text(context.l10n.passportDeleteHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.back),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.passportDelete),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await service.delete(widget.uid, widget.memory!);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => error = 'passportError');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  InputDecoration fieldDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF158276)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDDE7DF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDDE7DF)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = [l.rating1, l.rating2, l.rating3, l.rating4, l.rating5];
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F4EC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F4EC),
          title: Text(widget.memory == null ? l.passportAdd : l.passportEdit),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFCD61),
                foregroundColor: const Color(0xFF102C42),
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: busy ? null : save,
              icon: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                l.passportSave,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AdventureHeader(
              title: l.passportTitle,
              subtitle: l.passportEditorHint,
              icon: Icons.restaurant_menu_rounded,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: restaurant,
              enabled: !busy,
              maxLength: 80,
              decoration: fieldDecoration(
                l.passportRestaurant,
                Icons.storefront_rounded,
              ),
            ),
            TextField(
              controller: area,
              enabled: !busy,
              maxLength: 80,
              decoration: fieldDecoration(l.passportArea, Icons.place_outlined),
            ),
            TextField(
              controller: dish,
              enabled: !busy,
              maxLength: 80,
              decoration: fieldDecoration(
                l.passportDish,
                Icons.ramen_dining_rounded,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8A9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: DumplingRating(
                value: rating,
                onChanged: busy ? null : (v) => setState(() => rating = v),
              ),
            ),
            const SizedBox(height: 10),
            if (rating > 0)
              Text(
                labels[rating - 1],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: review,
              enabled: !busy,
              maxLength: 200,
              maxLines: 3,
              decoration: fieldDecoration(
                l.passportReview,
                Icons.edit_note_rounded,
              ),
            ),
            SwitchListTile(
              tileColor: const Color(0xFFE4EFE8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              secondary: const Icon(
                Icons.favorite_rounded,
                color: Color(0xFF158276),
              ),
              value: again,
              onChanged: busy ? null : (v) => setState(() => again = v),
              title: Text(l.passportAgain),
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(l.passportDate),
              subtitle: Text(
                DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
                    .format(visited),
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: busy
                  ? null
                  : () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: visited,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (mounted && date != null)
                        setState(() => visited = date);
                    },
            ),
            const SizedBox(height: 20),
            Text(
              l.passportVisibility,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l.passportPrivate),
                  selected: visibility == 'private',
                  onSelected: busy
                      ? null
                      : (_) => setState(() => visibility = 'private'),
                ),
                ChoiceChip(
                  label: Text(l.passportFriends),
                  selected: visibility == 'friends',
                  onSelected: busy
                      ? null
                      : (_) => setState(() => visibility = 'friends'),
                ),
              ],
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  l.message(error!),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (busy) const LinearProgressIndicator(),
            const SizedBox(height: 16),

            if (widget.memory != null)
              TextButton(
                onPressed: busy ? null : remove,
                child: Text(l.passportDelete),
              ),
          ],
        ),
      ),
    );
  }
}
