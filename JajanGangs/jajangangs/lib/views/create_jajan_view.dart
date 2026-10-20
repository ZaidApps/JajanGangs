import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../controllers/create_jajan_controller.dart';
import '../l10n/l10n.dart';
import '../models/home_map_state.dart';
import '../models/jajan_event.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/jajan_schedule_badge.dart';
import '../widgets/adventure_header.dart';
import '../widgets/language_selector.dart';
import '../widgets/game_map_canvas.dart';
import '../widgets/welcome_game_elements.dart';

class CreateJajanView extends StatefulWidget {
  const CreateJajanView({super.key, required this.uid, required this.area});
  final String uid;
  final MapArea area;
  @override
  State<CreateJajanView> createState() => _CreateJajanViewState();
}

class _CreateJajanViewState extends State<CreateJajanView> {
  late final _controller = CreateJajanController(
    uid: widget.uid,
    area: widget.area,
  );
  @override
  void initState() {
    super.initState();
    unawaited(_controller.restore());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final latest = now.add(const Duration(days: 7));
    var initial =
        _controller.scheduledAt?.toLocal() ?? now.add(const Duration(hours: 1));
    if (initial.isBefore(now) || initial.isAfter(latest))
      initial = now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: latest,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    _controller.chooseSchedule(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Future<void> _submit() async {
    final event = await _controller.submit();
    if (!mounted || event == null) return;
    // Let PopScope rebuild after busy clears before closing the form.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(event);
    });
  }

  Future<void> _openSettings() async {
    var opened = false;
    try {
      opened =
          [
            'jajanLocationOff',
            'jajanLocationTimeout',
            'jajanLocationUnavailable',
          ].contains(_controller.error)
          ? await Geolocator.openLocationSettings()
          : await Geolocator.openAppSettings();
    } catch (_) {
      // Some platforms cannot open settings directly; explain the manual step.
    }
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.jajanSettingsUnavailable)),
    );
  }

  Widget _section({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFDCE6DF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      final c = _controller;
      final number = NumberFormat.decimalPattern(
        Localizations.localeOf(context).languageCode,
      );
      return PopScope(
        canPop: !c.busy,
        child: Scaffold(
          backgroundColor: const Color(0xFFF1F6EC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF1F6EC),
            title: Text(context.l10n.homeCreate),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: c.busy ? null : () => Navigator.pop(context),
            ),
            actions: const [LanguageSelector(), SizedBox(width: 12)],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: AuthAction(
                label: c.busy || c.pending == null
                    ? context.l10n.homeCreate
                    : context.l10n.jajanRetryCreate,
                busy: c.busy,
                onPressed:
                    c.restoring || c.locating || c.error == 'jajanDraftError'
                    ? null
                    : _submit,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              AdventureHeader(
                title: context.l10n.hungry,
                subtitle: context.l10n.jajanCreateIntro,
                icon: foodIcon(c.craving.foodKind),
              ),
              const SizedBox(height: 22),
              _section(
                children: [
                  Text(
                    context.l10n.jajanWhen,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    children: [
                      ChoiceChip(
                        label: Text(context.l10n.jajanNow),
                        selected: c.scheduledAt == null,
                        onSelected: c.locked
                            ? null
                            : (_) => c.chooseSchedule(null),
                      ),
                      ChoiceChip(
                        label: Text(context.l10n.jajanLater),
                        selected: c.scheduledAt != null,
                        onSelected: c.locked
                            ? null
                            : (_) => c.chooseSchedule(
                                DateTime.now().add(const Duration(hours: 1)),
                              ),
                      ),
                    ],
                  ),
                  if (c.scheduledAt != null) ...[
                    const SizedBox(height: 12),
                    JajanScheduleBadge(time: c.scheduledAt),
                    TextButton.icon(
                      onPressed: c.locked ? null : _pickSchedule,
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: Text(context.l10n.jajanChooseTime),
                    ),
                    Text(context.l10n.jajanScheduleHint),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              if (c.restoring) const LinearProgressIndicator(),
              if (c.pending != null &&
                  !c.busy &&
                  !c.restoring &&
                  c.error == null)
                AuthMessage(text: context.l10n.jajanPending),
              Text(
                context.l10n.jajanCravingQuestion,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, box) => Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: Craving.values.map((craving) {
                    final selected = c.craving == craving;
                    return SizedBox(
                      width: (box.maxWidth - 10) / 2,
                      child: Semantics(
                        selected: selected,
                        child: OutlinedButton(
                          onPressed: c.locked
                              ? null
                              : () => c.chooseCraving(craving),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selected
                                ? foodColor(craving.foodKind)
                                      .withValues(alpha: .3)
                                : Colors.white,
                            elevation: selected ? 3 : 0,
                            shadowColor: foodColor(craving.foodKind)
                                .withValues(alpha: .25),
                            foregroundColor: WelcomePalette.navy,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 16,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? WelcomePalette.navy
                                  : const Color(0xFFCEDAD5),
                              width: selected ? 2.5 : 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: foodColor(craving.foodKind)
                                      .withValues(alpha: .22),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  foodIcon(craving.foodKind),
                                  size: 29,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.l10n.message(craving.key),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(
                                  selected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  size: 16,
                                  color: selected
                                      ? WelcomePalette.navy
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              _section(
                children: [
                  Text(
                    context.l10n.jajanAccess,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Wrap(
                    spacing: 12,
                    children: [
                      ChoiceChip(
                        avatar: const Icon(Icons.public_rounded, size: 18),
                        selectedColor: const Color(0xFFBDE9D8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        label: Text(context.l10n.jajanPublic),
                        selected: c.joinPolicy == 'public',
                        onSelected: c.locked
                            ? null
                            : (_) => c.choosePolicy('public'),
                      ),
                      ChoiceChip(
                        avatar: const Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                        ),
                        selectedColor: const Color(0xFFFFE2A0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        label: Text(context.l10n.jajanPrivate),
                        selected: c.joinPolicy == 'private',
                        onSelected: c.locked
                            ? null
                            : (_) => c.choosePolicy('private'),
                      ),
                    ],
                  ),
                  Text(
                    c.joinPolicy == 'public'
                        ? context.l10n.jajanPublicHint
                        : context.l10n.jajanPrivateHint,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _section(
                children: [
                  Text(
                    context.l10n.jajanPeopleQuestion,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.jajanIncludesCreator,
                    style: const TextStyle(color: Color(0xFF566370)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [2, 3, 4, 5]
                        .map(
                          (count) => ChoiceChip(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            label: Text(
                              count == 5
                                  ? context.l10n.jajanFivePlus
                                  : number.format(count),
                            ),
                            selected: count == 5
                                ? c.capacity >= 5
                                : c.capacity == count,
                            selectedColor: WelcomePalette.gold,
                            onSelected: c.locked
                                ? null
                                : (_) => c.chooseCapacity(
                                    count == 5
                                        ? (c.capacity >= 5 ? c.capacity : 5)
                                        : count,
                                  ),
                          ),
                        )
                        .toList(),
                  ),
                  if (c.capacity >= 5) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.jajanExactCapacity(c.capacity),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          tooltip: context.l10n.jajanFewer,
                          onPressed: c.locked || c.capacity <= 5
                              ? null
                              : () => c.chooseCapacity(c.capacity - 1),
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                        ),
                        IconButton(
                          tooltip: context.l10n.jajanMore,
                          onPressed: c.locked || c.capacity >= 12
                              ? null
                              : () => c.chooseCapacity(c.capacity + 1),
                          icon: const Icon(Icons.add_circle_outline_rounded),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.jajanExpiryHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF566370), fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.eventPublicHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF566370), fontSize: 13),
              ),
              const SizedBox(height: 20),
              if (!c.restoring)
                TextFormField(
                  key: ValueKey(c.pending?.id ?? 'new-description'),
                  initialValue: c.description,
                  enabled: !c.locked,
                  minLines: 2,
                  maxLines: 3,
                  maxLength: 150,
                  onChanged: (value) => c.description = value,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.edit_note_rounded,
                      color: Color(0xFF158276),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: Color(0xFFDCE6DF)),
                    ),
                    labelText: context.l10n.descriptionLabel,
                    hintText: context.l10n.descriptionHint,
                  ),
                ),
              const SizedBox(height: 16),
              if (c.error != null)
                AuthMessage(
                  text: context.l10n.message(c.error!),
                  isError: true,
                ),
              if (c.error == 'jajanDraftError')
                TextButton(
                  onPressed: c.busy || c.restoring ? null : c.restore,
                  child: Text(context.l10n.retry),
                ),
              if (c.error == 'jajanLocationBlocked' ||
                  c.error == 'jajanLocationOff' ||
                  c.error == 'jajanLocationTimeout' ||
                  c.error == 'jajanLocationUnavailable')
                TextButton(
                  onPressed: c.busy ? null : _openSettings,
                  child: Text(context.l10n.homeSettings),
                ),
              if (c.busy)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      c.locating
                          ? context.l10n.locationFinding
                          : context.l10n.jajanCreating,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
