import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../controllers/create_jajan_controller.dart';
import '../l10n/l10n.dart';
import '../models/home_map_state.dart';
import '../models/jajan_event.dart';
import '../widgets/auth_scaffold.dart';
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
      opened = _controller.error == 'jajanLocationOff'
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
        child: AuthScaffold(
          title: context.l10n.hungry,
          subtitle: context.l10n.jajanCreateIntro,
          badge: context.l10n.homeCreate,
          onBack: c.busy ? null : () => Navigator.pop(context),
          children: [
            if (c.restoring) const LinearProgressIndicator(),
            if (c.pending != null && !c.busy && !c.restoring && c.error == null)
              AuthMessage(text: context.l10n.jajanPending),
            Text(
              context.l10n.jajanCravingQuestion,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
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
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(foodIcon(craving.foodKind), size: 31),
                            const SizedBox(height: 8),
                            Text(
                              context.l10n.message(craving.key),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (selected)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
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
            Text(
              context.l10n.jajanAccess,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            Wrap(
              spacing: 12,
              children: [
                ChoiceChip(
                  label: Text(context.l10n.jajanPublic),
                  selected: c.joinPolicy == 'public',
                  onSelected: c.locked ? null : (_) => c.choosePolicy('public'),
                ),
                ChoiceChip(
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
            const SizedBox(height: 24),
            Text(
              context.l10n.jajanPeopleQuestion,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
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
                  labelText: context.l10n.descriptionLabel,
                  hintText: context.l10n.descriptionHint,
                ),
              ),
            const SizedBox(height: 16),
            if (c.error != null)
              AuthMessage(text: context.l10n.message(c.error!), isError: true),
            if (c.error == 'jajanDraftError')
              TextButton(
                onPressed: c.busy || c.restoring ? null : c.restore,
                child: Text(context.l10n.retry),
              ),
            if (c.error == 'jajanLocationBlocked' ||
                c.error == 'jajanLocationOff')
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
            AuthAction(
              label: c.busy || c.pending == null
                  ? context.l10n.homeCreate
                  : context.l10n.jajanRetryCreate,
              busy: c.busy,
              onPressed:
                  c.restoring || c.locating || c.error == 'jajanDraftError'
                  ? null
                  : _submit,
            ),
          ],
        ),
      );
    },
  );
}
