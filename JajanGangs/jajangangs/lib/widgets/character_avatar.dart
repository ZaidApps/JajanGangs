import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/user_profile.dart';
import 'avatar_preview_dialog.dart';

String avatarName(BuildContext context, String id) =>
    switch (AvatarCatalog.displayId(id)) {
      'anime_02' => context.l10n.avatarAnime02,
      'anime_03' => context.l10n.avatarAnime03,
      'anime_04' => context.l10n.avatarAnime04,
      'anime_05' => context.l10n.avatarAnime05,
      'anime_06' => context.l10n.avatarAnime06,
      'anime_07' => context.l10n.avatarAnime07,
      'anime_08' => context.l10n.avatarAnime08,
      'anime_09' => context.l10n.avatarAnime09,
      'anime_10' => context.l10n.avatarAnime10,
      _ => context.l10n.avatarAnime01,
    };

/// Bundled portraits: no network images or extra Firestore reads.
class CharacterAvatar extends StatelessWidget {
  const CharacterAvatar({super.key, required this.avatarId, this.size = 64});
  final String? avatarId;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: avatarName(context, AvatarCatalog.displayId(avatarId)),
    child: SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: Image.asset(
          AvatarCatalog.asset(avatarId),
          fit: BoxFit.cover,
          // Fixed decode size keeps the cache shared across avatar widgets.
          cacheWidth: 256,
          cacheHeight: 256,
          excludeFromSemantics: true,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => const ColoredBox(
            color: Color(0xFFDED3F8),
            child: Icon(Icons.person_rounded, color: Color(0xFF34305F)),
          ),
        ),
      ),
    ),
  );
}

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.enabled = true,
  });
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => FormField<String>(
    enabled: enabled,
    initialValue: initialValue == null
        ? null
        : AvatarCatalog.displayId(initialValue),
    validator: (value) =>
        AvatarCatalog.ids.contains(value) ? null : context.l10n.avatarRequired,
    builder: (field) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.avatarChoose,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.avatarHint,
          style: const TextStyle(fontSize: 13, color: Color(0xFF566370)),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, box) {
            final count = box.maxWidth < 270 ? 3 : 5;
            final width = (box.maxWidth - (count - 1) * 8) / count;
            return Wrap(
              spacing: 8,
              runSpacing: 10,
              children: AvatarCatalog.ids.map((id) {
                final selected = field.value == id;
                return SizedBox(
                  width: width,
                  child: Semantics(
                    label: avatarName(context, id),
                    selected: selected,
                    button: true,
                    enabled: enabled,
                    child: Tooltip(
                      message: avatarName(context, id),
                      child: Material(
                        color: selected
                            ? const Color(0xFFFFE6A1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: enabled
                              ? () async {
                                  final chosen = await showAvatarPreview(
                                    context,
                                    avatarId: id,
                                    name: avatarName(context, id),
                                  );
                                  if (!field.mounted ||
                                      !chosen ||
                                      !field.widget.enabled)
                                    return;
                                  field.didChange(id);
                                  onChanged(id);
                                }
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF143745)
                                    : const Color(0xFFDCE4E7),
                                width: selected ? 3 : 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: ExcludeSemantics(
                                    child: CharacterAvatar(avatarId: id),
                                  ),
                                ),
                                if (selected)
                                  const Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF143745),
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        if (field.value != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              avatarName(context, field.value!),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        if (field.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                field.errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
      ],
    ),
  );
}
