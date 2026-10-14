import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Public landing is local UI. Initialize backend/map services when needed.
  runApp(const JajanGangsApp());
}
