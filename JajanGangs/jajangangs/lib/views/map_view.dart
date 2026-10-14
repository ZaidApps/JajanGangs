import '../widgets/notification_sound_tile.dart';
import '../services/jajan_service.dart';
import '../widgets/activity_bell.dart';
import 'chat_inbox_view.dart';
import 'friends_view.dart';
import 'food_passport_view.dart';
import '../models/auth_session.dart';
import 'event_details_view.dart';
import 'create_jajan_view.dart';
import '../models/jajan_event.dart';
import '../widgets/character_avatar.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../config/app_config.dart';
import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../l10n/l10n.dart';
import '../models/home_map_state.dart';
import '../widgets/game_map_canvas.dart';
import '../widgets/language_selector.dart';
import '../widgets/welcome_game_elements.dart';

class MapView extends StatefulWidget {
  const MapView({super.key, required this.auth});
  final AuthController auth;
  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with WidgetsBindingObserver {
  bool _retryAfterSettings = false;
  bool _checkingCreate = false;
  late final _home = HomeController(uid: widget.auth.user!.uid);
  String? _setupError;
  int _mapAttempt = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _configure();
    unawaited(_home.loadEvents());
    unawaited(_home.resumeCancellations());
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_home.locate());
      });
    }
  }

  void _configure() {
    try {
      final config = AppConfig.fromEnvironment();
      config.validate();
      mb.MapboxOptions.setAccessToken(config.mapboxToken);
      _setupError = null;
    } catch (error) {
      _setupError = error is UnsupportedError ? 'mobileOnly' : 'homeMapSetup';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _home.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    if (_checkingCreate) return;
    setState(() => _checkingCreate = true);
    try {
      await JajanService().ensureCanCreate(widget.auth.user!.uid);
    } catch (e) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.l10n.homeCreate),
            content: Text(
              context.l10n.message(
                e is AuthFailure ? e.message : 'jajanActiveCheckFailed',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.gotIt),
              ),
            ],
          ),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _checkingCreate = false);
    }
    if (!mounted) return;
    final event = await Navigator.of(context).push<JajanEvent>(
      MaterialPageRoute(
        builder: (_) =>
            CreateJajanView(uid: widget.auth.user!.uid, area: _home.area),
      ),
    );
    if (!mounted || event == null) return;
    _home.addCreated(event);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          event.isActive
              ? context.l10n.jajanCreated
              : context.l10n.jajanRecoveredExpired,
        ),
      ),
    );
  }

  bool _detailsOpen = false;
  Future<void> _openEvent(String id) async {
    if (_detailsOpen) return;
    _home.select(id);
    final marker = _home.selected;
    if (marker == null || marker.id != id || marker.isDemo) return;
    _detailsOpen = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => EventDetailsView(
            marker: marker,
            area: _home.area,
            uid: widget.auth.user!.uid,
            ownerName: widget.auth.name,
            ownerAvatarId: widget.auth.avatarId,
          ),
        ),
      );
    } finally {
      _detailsOpen = false;
    }
    if (mounted && !marker.isDemo) unawaited(_home.loadEvents());
  }

  void _placeholder(String kind) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFAEF),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (kind == 'profile')
                Center(
                  child: CharacterAvatar(
                    avatarId: widget.auth.avatarId,
                    size: 88,
                  ),
                )
              else
                Icon(
                  kind == 'profile'
                      ? Icons.person_rounded
                      : kind == 'gang'
                      ? Icons.groups_rounded
                      : Icons.add_location_alt_rounded,
                  size: 52,
                  color: WelcomePalette.navy,
                ),
              const SizedBox(height: 16),
              Text(
                kind == 'profile'
                    ? (widget.auth.name ?? sheetContext.l10n.foodie)
                    : kind == 'gang'
                    ? sheetContext.l10n.homeGang
                    : sheetContext.l10n.homeCreate,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 12),
              if (kind != 'profile')
                Text(
                  sheetContext.l10n.homeComingSoon,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
              if (kind == 'profile') ...[
                const NotificationSoundTile(),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FoodPassportView(
                          ownerId: widget.auth.user!.uid,
                          viewerId: widget.auth.user!.uid,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.restaurant_menu_rounded),
                  label: Text(sheetContext.l10n.passportTitle),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FriendsView(uid: widget.auth.user!.uid),
                      ),
                    );
                  },
                  icon: const Icon(Icons.people_alt_rounded),
                  label: Text(sheetContext.l10n.friendsTitle),
                ),
                const SizedBox(height: 12),
              ],
              if (kind == 'profile')
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    unawaited(widget.auth.signOut());
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(sheetContext.l10n.signOut),
                ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: Text(sheetContext.l10n.homeBackMap),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _retryAfterSettings && mounted) {
      _retryAfterSettings = false;
      unawaited(_home.locate());
    }
  }

  Future<void> _openLocationSettings() async {
    _retryAfterSettings = true;
    var opened = false;
    try {
      opened =
          _home.locationMessage == 'locationBlocked' ||
              _home.locationMessage == 'locationDenied'
          ? await Geolocator.openAppSettings()
          : await Geolocator.openLocationSettings();
    } catch (_) {}
    if (!mounted) return;
    if (!opened) {
      _retryAfterSettings = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.locationSettingsUnavailable)),
      );
    }
  }

  Widget _locationControls(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        liveRegion: true,
        child: Text(context.l10n.message(_home.locationMessage)),
      ),
      if (!_home.locating)
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: _home.locate,
              icon: const Icon(Icons.my_location_rounded),
              label: Text(context.l10n.homeLocate),
            ),
            if (_home.locationMessage != 'locationNeeded' &&
                _home.locationMessage != 'locationApproximate')
              TextButton(
                onPressed: _openLocationSettings,
                child: Text(context.l10n.homeSettings),
              ),
          ],
        ),
    ],
  );

  void _locationInfo() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: ListenableBuilder(
            listenable: _home,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.homePrivacy,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(context.l10n.homePrivacyDetails),
                const SizedBox(height: 16),
                if (_home.locating) const LinearProgressIndicator(),
                const SizedBox(height: 8),
                _locationControls(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
    child: Row(
      children: [
        const Icon(
          Icons.local_fire_department_rounded,
          color: WelcomePalette.gold,
          size: 32,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'JAJAN GANGS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  letterSpacing: 1,
                ),
              ),
              Text(
                context.l10n.homeTagline,
                style: const TextStyle(color: Color(0xFF9BD8CC), fontSize: 12),
              ),
            ],
          ),
        ),
        const LanguageSelector(),
        ActivityBell(uid: widget.auth.user!.uid, area: _home.area),
        IconButton(
          tooltip: context.l10n.homeProfile,
          onPressed: () => _placeholder('profile'),
          icon: CharacterAvatar(avatarId: widget.auth.avatarId, size: 38),
        ),
      ],
    ),
  );

  Widget _eventPanel(BuildContext context) {
    final event = _home.selected;
    final l = context.l10n;
    final number = NumberFormat(
      '0.#',
      Localizations.localeOf(context).languageCode,
    );
    final waiting = _home.loadingEvents || _home.locating;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFAEF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.homeNearby,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: WelcomePalette.navy,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.eventRefresh,
                  onPressed: waiting ? null : _home.loadEvents,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            if (waiting) const LinearProgressIndicator(),
            if (_home.area.isFallback) ...[
              const SizedBox(height: 8),
              _locationControls(context),
            ],
            if (_home.recoveringCancellations) Text(l.eventCleaningUp),
            if (_home.cancellationError != null)
              TextButton(
                onPressed: _home.recoveringCancellations
                    ? null
                    : _home.resumeCancellations,
                child: Text(l.message(_home.cancellationError!)),
              ),
            if (_home.eventsError != null)
              TextButton.icon(
                onPressed: waiting ? null : _home.loadEvents,
                icon: const Icon(Icons.cloud_off_rounded),
                label: Text(
                  l.message(_home.eventsError!),
                  textAlign: TextAlign.center,
                ),
              ),
            if (event == null) ...[
              const SizedBox(height: 12),
              Icon(
                waiting
                    ? Icons.travel_explore_rounded
                    : Icons.ramen_dining_rounded,
                size: 42,
                color: WelcomePalette.navy,
              ),
              const SizedBox(height: 8),
              Text(
                waiting
                    ? l.homeFindingEvents
                    : _home.eventsError != null
                    ? l.homeEventsUnavailable
                    : _home.area.isFallback
                    ? l.homeAreaNeeded
                    : l.homeNoEvents,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _home.area.isFallback
                    ? l.homeAreaNeededHint
                    : _home.eventsError != null
                    ? l.homeEventsUnavailableHint
                    : l.homeNoEventsHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF53736F)),
              ),
            ] else ...[
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _home.events
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: e.id == event.id,
                            onSelected: (_) => _home.select(e.id),
                            avatar: Icon(foodIcon(e.kind), size: 18),
                            label: Text(mapEventTitle(context, e)),
                            selectedColor: foodColor(e.kind)
                                .withValues(alpha: .5),
                            showCheckmark: false,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _openEvent(event.id),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: foodColor(event.kind),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            foodIcon(event.kind),
                            color: WelcomePalette.navy,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mapEventTitle(context, event),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (!_home.area.isFallback)
                                Text(
                                  event.distanceKm(_home.area) < 1
                                      ? l.eventSameArea
                                      : l.homeDistance(
                                          number.format(
                                            event.distanceKm(_home.area),
                                          ),
                                        ),
                                ),
                              Text(
                                l.jajanMemberCount(
                                  event.members,
                                  event.capacity,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _openEvent(event.id),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(l.eventDetails),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _checkingCreate ? null : _openCreate,
                    style: FilledButton.styleFrom(
                      backgroundColor: WelcomePalette.gold,
                      foregroundColor: WelcomePalette.navy,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(
                        color: WelcomePalette.navy,
                        width: 2,
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      _checkingCreate ? l.jajanCheckingActive : l.homeCreate,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatInboxView(uid: widget.auth.user!.uid),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 14,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.groups_rounded),
                      Text(l.chatInbox),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WelcomePalette.navy,
    body: SafeArea(
      child: ListenableBuilder(
        listenable: _home,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              _header(context),
              if (widget.auth.error != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    context.l10n.message(widget.auth.error!),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_setupError == null)
                      GameMapCanvas(
                        key: ValueKey(_mapAttempt),
                        area: _home.area,
                        events: _home.events,
                        selectedId: _home.selectedId,
                        cameraRevision: _home.cameraRevision,
                        onSelect: _openEvent,
                      )
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            context.l10n.message(_setupError!),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 68,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ActionChip(
                          avatar: Icon(
                            _home.area.isFallback
                                ? Icons.public_rounded
                                : Icons.shield_rounded,
                            size: 17,
                          ),
                          label: Text(
                            _home.locating
                                ? context.l10n.locationFinding
                                : _home.area.isFallback
                                ? context.l10n.homeJakarta
                                : context.l10n.homeApproximate,
                            maxLines: 2,
                          ),
                          onPressed: _locationInfo,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Column(
                        children: [
                          _mapButton(
                            context.l10n.homeRecenter,
                            Icons.my_location_rounded,
                            _home.locating
                                ? null
                                : () {
                                    if (_home.area.isFallback) {
                                      unawaited(_home.locate());
                                    } else {
                                      _home.recenter();
                                    }
                                  },
                          ),
                          const SizedBox(height: 8),
                          _mapButton(
                            context.l10n.retry,
                            Icons.refresh_rounded,
                            () => setState(() {
                              _configure();
                              _mapAttempt++;
                              unawaited(_home.loadEvents());
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * .48,
                ),
                child: _eventPanel(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _mapButton(String label, IconData icon, VoidCallback? onTap) =>
      Material(
        color: const Color(0xFFFFFAEF),
        borderRadius: BorderRadius.circular(15),
        elevation: 3,
        child: IconButton(
          tooltip: label,
          onPressed: onTap,
          icon: Icon(icon, color: WelcomePalette.navy),
        ),
      );
}
