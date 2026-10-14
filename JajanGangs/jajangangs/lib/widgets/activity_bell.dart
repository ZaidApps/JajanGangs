import 'package:flutter/material.dart';

import '../controllers/activity_controller.dart';
import '../models/home_map_state.dart';
import '../l10n/l10n.dart';
import '../views/notifications_view.dart';

class ActivityBell extends StatefulWidget {
  const ActivityBell({super.key, required this.uid, required this.area});
  final String uid;
  final MapArea area;
  @override
  State<ActivityBell> createState() => _ActivityBellState();
}

class _ActivityBellState extends State<ActivityBell> {
  late final controller = ActivityController(widget.uid);
  @override
  void initState() {
    super.initState();
    controller.start();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => IconButton(
      tooltip: context.l10n.activityTitle,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              NotificationsView(controller: controller, area: widget.area),
        ),
      ),
      icon: Badge(
        isLabelVisible: controller.unread > 0,
        label: Text('${controller.unread}'),
        child: const Icon(Icons.notifications_outlined, color: Colors.white),
      ),
    ),
  );
}
