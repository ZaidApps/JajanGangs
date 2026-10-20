import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/auth_session.dart';
import '../models/user_profile.dart';
import '../l10n/l10n.dart';
import '../widgets/adventure_header.dart';
import '../widgets/character_avatar.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key, required this.auth});
  final AuthController auth;
  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.auth.name);
  late final bio = TextEditingController(text: widget.auth.bio);
  late String avatar = AvatarCatalog.displayId(widget.auth.avatarId);
  bool saving = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    await widget.auth.saveProfile(name.text, avatar, bio: bio.text);
    if (!mounted) return;
    if (widget.auth.error == null) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      saving = false;
      error = widget.auth.error;
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Scaffold(
      backgroundColor: const Color(0xFFF1F6EC),
      appBar: AppBar(
        title: Text(context.l10n.profileEdit),
        backgroundColor: const Color(0xFFF1F6EC),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFCD61),
              foregroundColor: const Color(0xFF102C42),
              padding: const EdgeInsets.all(18),
            ),
            onPressed: saving ? null : save,
            icon: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_rounded),
            label: Text(context.l10n.profileSave),
          ),
        ),
      ),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AdventureHeader(
              title: context.l10n.profileEdit,
              subtitle: '',
              icon: Icons.person_rounded,
              leading: CharacterAvatar(avatarId: avatar, size: 64),
            ),
            const SizedBox(height: 24),
            AvatarPicker(
              initialValue: avatar,
              enabled: !saving,
              onChanged: (value) => setState(() => avatar = value),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: name,
              enabled: !saving,
              maxLength: 50,
              validator: (value) =>
                  context.l10n.validation(AuthValidation.name(value)),
              decoration: decoration(
                context.l10n.nameLabel,
                Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: bio,
              enabled: !saving,
              maxLength: 150,
              minLines: 3,
              maxLines: 5,
              validator: (value) => (value ?? '').trim().runes.length > 150
                  ? context.l10n.bioLong
                  : null,
              decoration: decoration(
                context.l10n.bioLabel,
                Icons.edit_note_rounded,
              ).copyWith(hintText: context.l10n.bioHint),
            ),
            if (error != null)
              Text(
                context.l10n.message(error!),
                style: const TextStyle(color: Color(0xFFB44742)),
              ),
          ],
        ),
      ),
    ),
  );
  InputDecoration decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
  );
}
