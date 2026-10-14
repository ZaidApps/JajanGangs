import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  final _preferences = SharedPreferencesAsync();
  Future<void> _writes = Future.value();
  bool _selected = false;
  bool _disposed = false;

  Future<void> restore() async {
    try {
      final code = await _preferences.getString('app_language');
      if (!_selected && !_disposed && (code == 'en' || code == 'id')) {
        _locale = Locale(code!);
        notifyListeners();
      }
    } catch (_) {
      // English remains usable if local storage is unavailable.
    }
  }

  Future<bool> select(String code) async {
    if (code != 'en' && code != 'id') return false;
    _selected = true;
    _locale = Locale(code);
    if (!_disposed) notifyListeners();
    var saved = true;
    // Serialize writes so rapid switching cannot save an older choice last.
    _writes = _writes.then((_) async {
      try {
        await _preferences.setString('app_language', code);
      } catch (_) {
        saved = false;
      }
    });
    await _writes;
    return saved;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocaleScope>()!.notifier!;
}
