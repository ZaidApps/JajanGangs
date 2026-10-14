import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../l10n/l10n.dart';
import '../models/home_map_state.dart';

Color foodColor(FoodKind kind) => switch (kind) {
  FoodKind.noodles => const Color(0xFFFFC541),
  FoodKind.coffee => const Color(0xFF37DEBF),
  FoodKind.satay => const Color(0xFFFF8F65),
  FoodKind.burger => const Color(0xFFE986DA),
  FoodKind.anything => const Color(0xFFFFC541),
  FoodKind.chicken => const Color(0xFFFFA35A),
  FoodKind.pizza => const Color(0xFFEF867D),
};
IconData foodIcon(FoodKind kind) => switch (kind) {
  FoodKind.noodles => Icons.ramen_dining_rounded,
  FoodKind.coffee => Icons.local_cafe_rounded,
  FoodKind.satay => Icons.kebab_dining_rounded,
  FoodKind.burger => Icons.lunch_dining_rounded,
  FoodKind.anything => Icons.restaurant_rounded,
  FoodKind.chicken => Icons.dinner_dining_rounded,
  FoodKind.pizza => Icons.local_pizza_rounded,
};
String foodTitle(BuildContext context, FoodKind kind) => switch (kind) {
  FoodKind.noodles => context.l10n.demoNoodles,
  FoodKind.coffee => context.l10n.demoCoffee,
  FoodKind.satay => context.l10n.demoSatay,
  FoodKind.burger => context.l10n.demoBurger,
  FoodKind.anything => context.l10n.cravingAnything,
  FoodKind.chicken => context.l10n.cravingChicken,
  FoodKind.pizza => context.l10n.cravingPizza,
};

String mapEventTitle(BuildContext context, MapJajan event) => event.isDemo
    ? foodTitle(context, event.kind)
    : context.l10n.message(event.cravingKey!);

/// Native annotations remain geographically anchored during every map gesture.
class GameMapCanvas extends StatefulWidget {
  const GameMapCanvas({
    super.key,
    required this.area,
    required this.events,
    required this.selectedId,
    required this.cameraRevision,
    required this.onSelect,
  });
  final MapArea area;
  final List<MapJajan> events;
  final String selectedId;
  final int cameraRevision;
  final ValueChanged<String> onSelect;
  @override
  State<GameMapCanvas> createState() => _GameMapCanvasState();
}

class _GameMapCanvasState extends State<GameMapCanvas>
    with WidgetsBindingObserver {
  late final mb.CameraViewportState _initialViewport = mb.CameraViewportState(
    center: _point(widget.area.latitude, widget.area.longitude),
    zoom: 13.2,
    pitch: 35,
    bearing: -12,
  );
  mb.MapboxMap? _map;
  mb.PointAnnotationManager? _pins;
  mb.PolygonAnnotationManager? _areas;
  mb.CircleAnnotationManager? _circles;
  mb.CircleAnnotation? _halo;
  mb.Cancelable? _taps;
  final _ids = <String, String>{};
  final _images = <FoodKind, Uint8List>{};
  Timer? _pulse;
  Timer? _loadDeadline;
  bool _ready = false;
  bool _preparing = false;
  bool _failed = false;
  bool _rendering = false;
  bool _renderAgain = false;
  bool _pulseBusy = false;
  bool _foreground = true;
  bool _reducedMotion = false;
  double _phase = 0;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    final code = Localizations.localeOf(context).languageCode;
    if (_language != code) {
      _language = code;
      if (_ready) unawaited(_localizeMap());
    }
    _restartPulse();
  }

  @override
  void didUpdateWidget(covariant GameMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pins == null) return;
    if (oldWidget.events != widget.events ||
        oldWidget.area != widget.area ||
        oldWidget.selectedId != widget.selectedId)
      unawaited(_render());
    if (oldWidget.cameraRevision != widget.cameraRevision)
      unawaited(_recenter());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _restartPulse();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulse?.cancel();
    _loadDeadline?.cancel();
    _taps?.cancel();
    _map = null;
    super.dispose();
  }

  mb.Point _point(double lat, double lng) =>
      mb.Point(coordinates: mb.Position(lng, lat));
  void _fail() {
    _loadDeadline?.cancel();
    _pulse?.cancel();
    if (mounted)
      setState(() {
        _failed = true;
      });
  }

  Future<void> _created(mb.MapboxMap map) async {
    _map = map;
    _loadDeadline = Timer(const Duration(seconds: 25), () {
      if (!_ready) _fail();
    });
    try {
      // Map ornaments stay inside the unobstructed map viewport.
      await map.logo.updateSettings(
        mb.LogoSettings(
          position: mb.OrnamentPosition.BOTTOM_LEFT,
          marginLeft: 12,
          marginBottom: 10,
        ),
      );
      await map.attribution.updateSettings(
        mb.AttributionSettings(
          position: mb.OrnamentPosition.BOTTOM_LEFT,
          marginLeft: 104,
          marginBottom: 10,
        ),
      );
      final style = jsonDecode(
        await rootBundle.loadString('assets/maps/jajan_arcade.json'),
      ) as Map<String, dynamic>;
      final layers = style['layers'] as List;
      final labels = layers.last as Map<String, dynamic>;
      (labels['layout'] as Map<String, dynamic>)['text-field'] = [
        'coalesce',
        ['get', 'name_$_language'],
        ['get', 'name'],
      ];
      if (!mounted) return;
      await map.loadStyleJson(jsonEncode(style));
    } catch (_) {
      _fail();
    }
  }

  Future<void> _styleLoaded() async {
    final map = _map;
    if (map == null || _ready || _preparing) return;
    try {
      // Ignore the initial empty style event.
      if (!await map.style.styleLayerExists('jg-roads') || !mounted) return;
      if (_preparing) return;
      _preparing = true;
      _areas = await map.annotations.createPolygonAnnotationManager();
      _circles = await map.annotations.createCircleAnnotationManager();
      _pins = await map.annotations.createPointAnnotationManager();
      await _pins!.setIconAllowOverlap(true);
      _taps = _pins!.tapEvents(
        onTap: (annotation) {
          final id = _ids[annotation.id];
          if (id != null && mounted) widget.onSelect(id);
        },
      );
      if (!mounted) return;
      await _render();
      if (_failed || !mounted) return;
      await _recenter();
      if (!mounted) return;
      _loadDeadline?.cancel();
      setState(() {
        _ready = true;
        _failed = false;
      });
      _restartPulse();
    } catch (_) {
      _fail();
    }
  }

  Future<void> _localizeMap() async {
    try {
      await _map?.style.setStyleLayerProperty('jg-place-labels', 'text-field', [
        'coalesce',
        ['get', 'name_$_language'],
        ['get', 'name'],
      ]);
    } catch (_) {
      /* Provider labels may not exist in every language. */
    }
  }

  Future<void> _recenter() async {
    final area = widget.area;
    try {
      await _map?.flyTo(
        mb.CameraOptions(
          center: _point(area.latitude, area.longitude),
          zoom: (13.2 - math.log(area.radius / 2000) / math.ln2)
              .clamp(4.0, 13.2)
              .toDouble(),
          pitch: 35,
          bearing: -12,
        ),
        mb.MapAnimationOptions(duration: _reducedMotion ? 0 : 800),
      );
    } catch (_) {
      if (mounted) _fail();
    }
  }

  Future<void> _render() async {
    if (_pins == null || _areas == null || _circles == null || !mounted) return;
    if (_rendering) {
      _renderAgain = true;
      return;
    }
    _rendering = true;
    _pulse?.cancel();
    try {
      do {
        _renderAgain = false;
        final area = widget.area;
        final events = widget.events;
        final selected = widget.selectedId;
        _halo = null;
        await _pins!.deleteAll();
        await _areas!.deleteAll();
        await _circles!.deleteAll();
        _ids.clear();
        if (!mounted) return;
        if (!area.isFallback) {
          final ring = List.generate(48, (i) {
            final angle = i * math.pi * 2 / 48;
            return mb.Position(
              area.longitude +
                  math.cos(angle) *
                      area.radius /
                      (111320 *
                          math.max(
                            .1,
                            math.cos(area.latitude * math.pi / 180),
                          )),
              area.latitude + math.sin(angle) * area.radius / 111320,
            );
          });
          ring.add(ring.first);
          await _areas!.create(
            mb.PolygonAnnotationOptions(
              geometry: mb.Polygon(coordinates: [ring]),
              fillColor: 0xFF4ADDC7,
              fillOpacity: .12,
              fillOutlineColor: 0xFF68E3CF,
            ),
          );
        }
        for (final event in events) {
          final bytes = _images[event.kind] ??= await _pinImage(event.kind);
          if (!mounted) return;
          final annotation = await _pins!.create(
            mb.PointAnnotationOptions(
              geometry: _point(event.latitude, event.longitude),
              image: bytes,
              iconAnchor: mb.IconAnchor.BOTTOM,
              iconSize: event.id == selected ? .65 : .52,
            ),
          );
          _ids[annotation.id] = event.id;
        }
        for (final event in events.where((e) => e.id == selected)) {
          _halo = await _circles!.create(
            mb.CircleAnnotationOptions(
              geometry: _point(event.latitude, event.longitude),
              circleColor: foodColor(event.kind).toARGB32(),
              circleRadius: 23,
              circleOpacity: .18,
              circleStrokeColor: foodColor(event.kind).toARGB32(),
              circleStrokeWidth: 2,
            ),
          );
        }
      } while (_renderAgain && mounted);
    } catch (_) {
      _fail();
    } finally {
      _rendering = false;
      _restartPulse();
    }
  }

  void _restartPulse() {
    _pulse?.cancel();
    if (!_ready ||
        _failed ||
        _reducedMotion ||
        !_foreground ||
        !mounted ||
        _halo == null)
      return;
    // Small, local annotation updates only. No location streams or search calls.
    _pulse = Timer.periodic(const Duration(milliseconds: 120), (_) async {
      if (_pulseBusy || _rendering || _halo == null) return;
      _pulseBusy = true;
      try {
        _phase += .24;
        _halo!.circleRadius = 25 + 6 * math.sin(_phase);
        _halo!.circleOpacity = .16 + .05 * math.sin(_phase);
        await _circles?.update(_halo!);
      } catch (_) {
        _pulse?.cancel();
      } finally {
        _pulseBusy = false;
      }
    });
  }

  Future<Uint8List> _pinImage(FoodKind kind) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final path = Path()
      ..moveTo(64, 150)
      ..cubicTo(49, 130, 12, 89, 12, 64)
      ..cubicTo(12, -4, 116, -4, 116, 64)
      ..cubicTo(116, 89, 79, 130, 64, 150)
      ..close();
    canvas.drawShadow(path, const Color(0xFF031B2A), 9, true);
    canvas.drawPath(path, Paint()..color = const Color(0xFF092C3A));
    canvas.save();
    canvas.translate(64, 68);
    canvas.scale(.88);
    canvas.translate(-64, -68);
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(15, 10),
          const Offset(100, 140),
          [Color.lerp(foodColor(kind), Colors.white, .35)!, foodColor(kind)],
        ),
    );
    canvas.restore();
    canvas.drawCircle(
      const Offset(64, 59),
      35,
      Paint()..color = const Color(0xFF153744),
    );
    final icon = foodIcon(kind);
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 45,
          color: Colors.white,
        ),
      ),
    )..layout();
    painter.paint(
      canvas,
      Offset(64 - painter.width / 2, 59 - painter.height / 2),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(128, 164);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    painter.dispose();
    return data!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      mb.MapWidget(
        styleUri: '',
        viewport: _initialViewport,
        onMapCreated: _created,
        onStyleLoadedListener: (_) => unawaited(_styleLoaded()),
        onMapLoadErrorListener: (_) => _fail(),
      ),
      if (!_ready && !_failed)
        const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFCB3E)),
        ),
      if (_failed)
        Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(context.l10n.mapError, textAlign: TextAlign.center),
            ),
          ),
        ),
    ],
  );
}
