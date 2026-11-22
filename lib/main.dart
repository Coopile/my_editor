import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'home_screen.dart';
import 'mangacut_editor.dart';

final ValueNotifier<Color> editShiftAccent =
    ValueNotifier<Color>(const Color(0xFF79C8FF));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  editShiftAccent.value = Color(prefs.getInt('editshift.accent') ?? 0xFF79C8FF);
  runApp(const EditShiftApp());
}

class EditShiftApp extends StatelessWidget {
  const EditShiftApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Color>(
    valueListenable: editShiftAccent,
    builder: (context, accent, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0D12),
        colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    ),
  );
}

// ---------- Effects library ----------
const fxLibrary = [
  ('None', Icons.block),
  ('Soft Blur', Icons.auto_awesome),
  ('Motion Blur', Icons.auto_awesome),
  ('Dream Blur', Icons.auto_awesome),
  ('Gaussian Blur', Icons.auto_awesome),
  ('Grayscale', Icons.auto_awesome),
  ('Mono', Icons.auto_awesome),
  ('Noir', Icons.auto_awesome),
  ('Vintage', Icons.auto_awesome),
  ('Sepia', Icons.auto_awesome),
  ('Warm Film', Icons.auto_awesome),
  ('Cool Film', Icons.auto_awesome),
  ('Negative', Icons.auto_awesome),
  ('Invert', Icons.auto_awesome),
  ('Brighten', Icons.auto_awesome),
  ('Darken', Icons.auto_awesome),
  ('High Contrast', Icons.auto_awesome),
  ('Matte', Icons.auto_awesome),
  ('Fade', Icons.auto_awesome),
  ('Vivid', Icons.auto_awesome),
  ('Saturation', Icons.auto_awesome),
  ('Desaturate', Icons.auto_awesome),
  ('Golden Hour', Icons.auto_awesome),
  ('Arctic', Icons.auto_awesome),
  ('Rose Tint', Icons.auto_awesome),
  ('Violet Haze', Icons.auto_awesome),
  ('Emerald', Icons.auto_awesome),
  ('Crimson', Icons.auto_awesome),
  ('Amber', Icons.auto_awesome),
  ('Cinematic', Icons.auto_awesome),
  ('Teal & Orange', Icons.auto_awesome),
  ('Dusty', Icons.auto_awesome),
  ('Pastel', Icons.auto_awesome),
  ('Neon', Icons.auto_awesome),
  ('Glow', Icons.auto_awesome),
  ('Frost', Icons.auto_awesome),
  ('Shadow', Icons.auto_awesome),
  ('Sunset', Icons.auto_awesome),
  ('Midnight', Icons.auto_awesome),
  ('Retro', Icons.auto_awesome),
  ('Polaroid', Icons.auto_awesome),
  ('Dreamscape', Icons.auto_awesome),
  ('Horror', Icons.auto_awesome),
  ('Comic', Icons.auto_awesome),
  ('Sketch', Icons.auto_awesome),
  ('Soft Focus', Icons.auto_awesome),
  ('Hard Light', Icons.auto_awesome),
  ('Washed Out', Icons.auto_awesome),
  ('Deep Contrast', Icons.auto_awesome),
  ('Color Pop', Icons.auto_awesome),
  ('Chromatic', Icons.auto_awesome),
  ('Bend', Icons.auto_awesome),
  ('Wave Warp', Icons.waves_rounded),
  ('Shake', Icons.vibration),
  ('Scale Assist', Icons.zoom_in),
  ('Zoom Pulse', Icons.zoom_in),
  ('Spin', Icons.rotate_right),
  ('Glitch', Icons.broken_image),
  ('RGB Split', Icons.filter_b_and_w),
  ('Flash', Icons.flash_on),
  ('Vignette', Icons.lens_blur),
  ('Film Grain', Icons.grain),
  ('Pixelate', Icons.grid_on),
];
const _m = {
  'Gray': [0.21, 0.72, 0.07, 0, 0, 0.21, 0.72, 0.07, 0, 0, 0.21, 0.72, 0.07, 0, 0, 0, 0, 0, 1, 0],
  'Sepia': [0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272, 0.534, 0.131, 0, 0, 0, 0, 0, 1, 0],
  'Invert': [-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0],
  'Bright': [1, 0, 0, 0, 45, 0, 1, 0, 0, 45, 0, 0, 1, 0, 45, 0, 0, 0, 1, 0],
  'Contrast': [1.5, 0, 0, 0, -64, 0, 1.5, 0, 0, -64, 0, 0, 1.5, 0, -64, 0, 0, 0, 1, 0],
};

Widget applyFx(
  int i,
  Widget w, {
  double strength = 1,
  double speed = 1,
  double time = 0,
}) {
  final n = fxLibrary[i].$1;
  final amount = strength.clamp(0.0, 2.0).toDouble();
  if (n == 'None' || n == 'Bend') return w;

  // Motion and lens effects are rendered as actual transforms/layers in preview.
  switch (n) {
    case 'Shake':
      return Transform.translate(
        offset: Offset(
          math.sin(time * 32 * speed) * 10 * amount,
          math.cos(time * 27 * speed) * 7 * amount,
        ),
        child: Transform.rotate(
          angle: math.sin(time * 23 * speed) * .018 * amount,
          child: w,
        ),
      );
    case 'Wave Warp':
      return _WaveWarp(child: w, time: time, strength: amount, speed: speed);
    case 'Scale Assist':
      return Transform.scale(
        scale: 1 + math.sin(time * 2.4 * speed) * .028 * amount,
        child: w,
      );
    case 'Zoom Pulse':
      return Transform.scale(
        scale: 1 + math.sin(time * 6 * speed) * .055 * amount,
        child: w,
      );
    case 'Spin':
      return Transform.rotate(
        angle: math.sin(time * 2.4 * speed) * .18 * amount,
        child: w,
      );
    case 'Glitch':
    case 'RGB Split':
      return Stack(clipBehavior: Clip.none, children: [
        Transform.translate(
          offset: Offset(math.sin(time * 42 * speed) * 5 * amount, 0),
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              1, 0, 0, 0, 0,
              0, 0, 0, 0, 0,
              0, 0, 0, 0, 0,
              0, 0, 0, .55, 0,
            ]),
            child: w,
          ),
        ),
        Transform.translate(
          offset: Offset(-math.sin(time * 37 * speed) * 5 * amount, 0),
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0, 0, 0, 0, 0,
              0, 0, 0, 0, 0,
              0, 0, 1, 0, 0,
              0, 0, 0, .42, 0,
            ]),
            child: w,
          ),
        ),
        w,
      ]);
    case 'Flash':
      return Stack(children: [
        w,
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: Colors.white.withOpacity(
                (math.sin(time * 18 * speed).clamp(0.0, 1.0) * .38 * amount)
                    .clamp(0.0, .65).toDouble(),
              ),
            ),
          ),
        ),
      ]);
    case 'Glow':
      return Stack(children: [
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 12 * amount, sigmaY: 12 * amount),
          child: Opacity(opacity: .42, child: w),
        ),
        w,
      ]);
    case 'Vignette':
      return Stack(children: [
        w,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: .72,
                  colors: [Colors.transparent, Colors.black.withOpacity(.82 * amount.clamp(0.0, 1.0).toDouble())],
                  stops: const [.42, 1],
                ),
              ),
            ),
          ),
        ),
      ]);
    case 'Film Grain':
      return CustomPaint(
        foregroundPainter: _GrainPainter(time: time, strength: amount),
        child: w,
      );
    case 'Pixelate':
      return ImageFiltered(
        imageFilter: ui.ImageFilter.matrix(
          (Matrix4.identity()
            ..scale(0.16 + (1 - amount.clamp(0.0, 1.0).toDouble()) * .12))
              .storage,
        ),
        child: w,
      );
  }

  if (n.toLowerCase().contains('blur') || n == 'Soft Focus') {
    final sigma = n == 'Motion Blur' ? 7.0 : n == 'Gaussian Blur' ? 5.0 : 3.0;
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: sigma * amount, sigmaY: sigma * amount),
      child: w,
    );
  }

  final key = switch (n) {
    'Grayscale' || 'Mono' || 'Noir' => 'Gray',
    'Vintage' || 'Sepia' || 'Warm Film' || 'Golden Hour' || 'Polaroid' => 'Sepia',
    'Negative' || 'Invert' => 'Invert',
    'Brighten' => 'Bright',
    'High Contrast' || 'Deep Contrast' => 'Contrast',
    _ => '',
  };
  final matrix = key.isNotEmpty
      ? _m[key]!.map((e) => e.toDouble()).toList()
      : _presetMatrix(i);
  return ColorFiltered(colorFilter: ColorFilter.matrix(matrix), child: w);
}



/// A lightweight animated horizontal displacement effect. Each clipped band
/// is shifted by a sine wave, so the preview shows a genuine wave-like warp.
class _WaveWarp extends StatelessWidget {
  final Widget child;
  final double time, strength, speed;
  const _WaveWarp({required this.child, required this.time, required this.strength, required this.speed});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final size = Size(constraints.maxWidth, constraints.maxHeight);
    if (!size.width.isFinite || !size.height.isFinite || size.width <= 0 || size.height <= 0) {
      return child;
    }
    const bands = 18;
    final bandHeight = size.height / bands;
    final amplitude = 8.0 * strength;
    return SizedBox.fromSize(size: size, child: Stack(clipBehavior: Clip.hardEdge, children: [
      for (int i = 0; i < bands; i++)
        Positioned.fill(
          child: ClipRect(
            clipper: _WaveBandClipper(top: i * bandHeight, bottom: (i + 1) * bandHeight),
            child: Transform.translate(
              offset: Offset(math.sin((i / bands * math.pi * 2) + time * 2.0 * speed) * amplitude, 0),
              child: child,
            ),
          ),
        ),
    ]));
  });
}

class _WaveBandClipper extends CustomClipper<Rect> {
  final double top, bottom;
  const _WaveBandClipper({required this.top, required this.bottom});
  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, top, size.width, bottom);
  @override
  bool shouldReclip(_WaveBandClipper old) => top != old.top || bottom != old.bottom;
}

class _GrainPainter extends CustomPainter {
  final double time;
  final double strength;
  _GrainPainter({required this.time, required this.strength});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(time.floor() + 17);
    final paint = Paint()..strokeWidth = 1;
    final count = (size.width * size.height / 180 * strength).round().clamp(0, 2200).toInt();
    for (int i = 0; i < count; i++) {
      paint.color = (i.isEven ? Colors.white : Colors.black)
          .withOpacity(.12 + random.nextDouble() * .2);
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawPoints(ui.PointMode.points, [Offset(x, y)], paint);
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) =>
      old.time.floor() != time.floor() || old.strength != strength;
}

class _EffectThumbnail extends StatefulWidget {
  final int effectIndex;
  const _EffectThumbnail({required this.effectIndex});

  @override
  State<_EffectThumbnail> createState() => _EffectThumbnailState();
}

class _EffectThumbnailState extends State<_EffectThumbnail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AnimatedBuilder(
        animation: _clock,
        builder: (context, _) {
          final t = _clock.value * math.pi * 2;
          final sample = SizedBox.expand(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF102F59), Color(0xFF17213B), Color(0xFF512B69)],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 10 + math.sin(t) * 5,
                    top: 8,
                    child: const Icon(Icons.auto_awesome, size: 12, color: Color(0xFFFFC56F)),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 8 + math.cos(t * .8) * 4,
                    child: const Icon(Icons.circle, size: 9, color: Color(0xFF61DDF4)),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFF8AEAFF), Color(0xFF2687E8), Color(0xFF263B88)],
                      ),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF37BFFF).withOpacity(.48), blurRadius: 16),
                      ],
                    ),
                    child: const Icon(Icons.rocket_launch_rounded, size: 27, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 5,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 34,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          return applyFx(
            widget.effectIndex,
            sample,
            time: t,
            strength: .9,
            speed: 1,
          );
        },
      ),
    );
  }
}

List<double> _presetMatrix(int index) {
  final saturation = 0.35 + (index % 10) * 0.17;
  final contrast = 0.72 + ((index ~/ 10) % 5) * 0.22;
  final brightness = ((index % 7) - 3) * 8.0;
  final a = 0.213 * (1 - saturation);
  final b = 0.715 * (1 - saturation);
  final c = 0.072 * (1 - saturation);
  final bias = 128 * (1 - contrast) + brightness;
  return [
    (0.213 + 0.787 * saturation) * contrast, (0.715 - 0.715 * saturation) * contrast, (0.072 - 0.072 * saturation) * contrast, 0, bias,
    (0.213 - 0.213 * saturation) * contrast, (0.715 + 0.285 * saturation) * contrast, (0.072 - 0.072 * saturation) * contrast, 0, bias,
    (0.213 - 0.213 * saturation) * contrast, (0.715 - 0.715 * saturation) * contrast, (0.072 + 0.928 * saturation) * contrast, 0, bias,
    0, 0, 0, 1, 0,
  ];
}

// ---------- Layers ----------
List<Offset> defaultMesh() =>
    [for (int r = 0; r < 3; r++) for (int c = 0; c < 3; c++) Offset(c / 2, r / 2)];

class KF {
  int t;
  Offset pos;
  double scale, rot, opacity;
  KF(this.t, this.pos, this.scale, this.rot, this.opacity);
}

class EffectKF {
  int t;
  double strength, speed;
  EffectKF(this.t, this.strength, this.speed);
}

class Layer {
  final bool isMesh;
  final bool isImage;
  final bool isNull;
  final bool isSolid;
  final bool isShape;
  final bool isAdjustment;
  final bool isCamera;
  int? parentIndex;
  int? groupId;
  String? imagePath;
  String text;
  Offset pos;
  double scale = 1, rot = 0, opacity = 1, fontSize = 30, start = 0, end = 1, bend = 0;
  double fxStrength = 1, fxSpeed = 1;
  Offset pivot = const Offset(.5, .5);
  int fx = 0;
  Color color = Colors.white;
  bool bold = true, italic = false, flipX = false, flipY = false, shadow = false, hidden = false;
  List<Offset> mesh = defaultMesh();
  List<KF> kfs = [];
  List<EffectKF> effectKfs = [];
  List<MangaCutEffectClip> mangaEffects = [];
  double curveEase = .65;
  Offset curveHandle1 = const Offset(.42, 0);
  Offset curveHandle2 = const Offset(.58, 1);
  bool curveCyclic = false;

  Layer.text(this.text, this.pos) : isMesh = false, isImage = false, isNull = false, isSolid = false, isShape = false, isAdjustment = false, isCamera = false;
  Layer.mesh(this.pos) : isMesh = true, isImage = false, isNull = false, isSolid = false, isShape = false, isAdjustment = false, isCamera = false, text = 'Mesh';
  Layer.image(this.imagePath, this.pos) : isMesh = false, isImage = true, isNull = false, isSolid = false, isShape = false, isAdjustment = false, isCamera = false, text = 'Photo';
  Layer.nullObject(this.pos) : isMesh = false, isImage = false, isNull = true, isSolid = false, isShape = false, isAdjustment = false, isCamera = false, text = 'Null';
  Layer.solid(this.pos) : isMesh = false, isImage = false, isNull = false, isSolid = true, isShape = false, isAdjustment = false, isCamera = false, text = 'Solid Color';
  Layer.shape(this.pos) : isMesh = false, isImage = false, isNull = false, isSolid = false, isShape = true, isAdjustment = false, isCamera = false, text = 'Shape';
  Layer.adjustment(this.pos) : isMesh = false, isImage = false, isNull = false, isSolid = false, isShape = false, isAdjustment = true, isCamera = false, text = 'Adjustment';
  Layer.camera(this.pos) : isMesh = false, isImage = false, isNull = false, isSolid = false, isShape = false, isAdjustment = false, isCamera = true, text = 'Camera';
  bool get isController => isNull || isCamera;

  Layer _copyAt(Offset position) {
    final clone = isCamera ? Layer.camera(position) : isNull ? Layer.nullObject(position) : isSolid ? Layer.solid(position) : isShape ? Layer.shape(position) : isAdjustment ? Layer.adjustment(position) : isMesh ? Layer.mesh(position) : isImage ? Layer.image(imagePath, position) : Layer.text(text, position);
    clone
      ..scale = scale
      ..rot = rot
      ..opacity = opacity
      ..fontSize = fontSize
      ..start = start
      ..end = end
      ..bend = bend
      ..fxStrength = fxStrength
      ..fxSpeed = fxSpeed
      ..pivot = pivot
      ..fx = fx
      ..color = color
      ..bold = bold
      ..italic = italic
      ..flipX = flipX
      ..flipY = flipY
      ..shadow = shadow
      ..hidden = hidden
      ..curveEase = curveEase
      ..curveHandle1 = curveHandle1
      ..curveHandle2 = curveHandle2
      ..curveCyclic = curveCyclic
      ..parentIndex = parentIndex
      ..groupId = groupId
      ..mesh = List.of(mesh)
      ..kfs = kfs.map((k) => KF(k.t, k.pos, k.scale, k.rot, k.opacity)).toList()
      ..effectKfs = effectKfs.map((k) => EffectKF(k.t, k.strength, k.speed)).toList()
      ..mangaEffects = mangaEffects.map((e) => MangaCutEffectClip(e.id,e.name,e.target,e.start,e.end,strength:e.strength,keys:List<int>.of(e.keys),strengthKeys:Map<double,double>.of(e.strengthKeys))).toList();
    return clone;
  }

  Layer copy() => _copyAt(pos + const Offset(20, 20));
  Layer snapshot() => _copyAt(pos);

  void upsert(int ms) {
    kfs.removeWhere((k) => (k.t - ms).abs() < 60);
    kfs.add(KF(ms, pos, scale, rot, opacity));
    kfs.sort((a, b) => a.t - b.t);
  }

  void applyEffect(int ms) {
    if (effectKfs.isEmpty) return;
    var a = effectKfs.first, b = effectKfs.last;
    if (ms <= a.t) {
      b = a;
    } else if (ms >= b.t) {
      a = b;
    } else {
      for (int i = 0; i < effectKfs.length - 1; i++) {
        if (ms >= effectKfs[i].t && ms <= effectKfs[i + 1].t) {
          a = effectKfs[i];
          b = effectKfs[i + 1];
          break;
        }
      }
    }
    final progress = a.t == b.t ? 0.0 : _bezierProgress((ms - a.t) / (b.t - a.t), curveHandle1, curveHandle2);
    fxStrength = ui.lerpDouble(a.strength, b.strength, progress)!;
    fxSpeed = ui.lerpDouble(a.speed, b.speed, progress)!;
  }

  void apply(int ms) {
    if (kfs.isEmpty) return;
    var a = kfs.first, b = kfs.last;
    if (ms <= a.t) {
      b = a;
    } else if (ms >= b.t) {
      a = b;
    } else {
      for (int i = 0; i < kfs.length - 1; i++) {
        if (ms >= kfs[i].t && ms <= kfs[i + 1].t) {
          a = kfs[i];
          b = kfs[i + 1];
          break;
        }
      }
    }
    var f = a.t == b.t ? 0.0 : (ms - a.t) / (b.t - a.t);
    f = curveCyclic
        ? (f + .18 * math.sin(f * math.pi * 6)).clamp(0.0, 1.0).toDouble()
        : _bezierProgress(f, curveHandle1, curveHandle2);
    pos = Offset.lerp(a.pos, b.pos, f)!;
    scale = ui.lerpDouble(a.scale, b.scale, f)!;
    rot = ui.lerpDouble(a.rot, b.rot, f)!;
    opacity = ui.lerpDouble(a.opacity, b.opacity, f)!;
  }
}

double _cubic(double a, double b, double c, double d, double t) {
  final u = 1 - t;
  return u * u * u * a + 3 * u * u * t * b +
      3 * u * t * t * c + t * t * t * d;
}

double _bezierProgress(double x, Offset first, Offset second) {
  final target = x.clamp(0.0, 1.0).toDouble();
  var low = 0.0, high = 1.0;
  for (int i = 0; i < 18; i++) {
    final t = (low + high) / 2;
    if (_cubic(0, first.dx, second.dx, 1, t) < target) {
      low = t;
    } else {
      high = t;
    }
  }
  return _cubic(0, first.dy, second.dy, 1, (low + high) / 2);
}

class _EaseGraphPainter extends CustomPainter {
  final Offset first, second;
  final bool cyclic;
  _EaseGraphPainter(this.first, this.second, this.cyclic);

  Offset _point(Offset p, Size size) => Offset(
    8 + p.dx * (size.width - 16),
    size.height - 8 - p.dy * (size.height - 16),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = Colors.white.withOpacity(.09)..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      final x = i * size.width / 4, y = i * size.height / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final a = Offset(8, size.height - 8);
    final d = Offset(size.width - 8, 8);
    final b = _point(first, size), c = _point(second, size);
    final guide = Paint()..color = Colors.white38..strokeWidth = 1;
    canvas.drawLine(a, b, guide);
    canvas.drawLine(d, c, guide);
    final curve = Path()..moveTo(a.dx, a.dy);
    if (cyclic) {
      for (int i = 1; i <= 120; i++) {
        final x = i / 120;
        final y = (x + .18 * math.sin(x * math.pi * 6)).clamp(0.0, 1.0);
        curve.lineTo(8 + x * (size.width - 16), size.height - 8 - y * (size.height - 16));
      }
    } else {
      curve.cubicTo(b.dx, b.dy, c.dx, c.dy, d.dx, d.dy);
    }
    canvas.drawPath(
      curve,
      Paint()..color = editShiftAccent.value..strokeWidth = 3
        ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round,
    );
    for (final p in [a, d]) { canvas.drawCircle(p, 4, Paint()..color = Colors.white); }
    for (final p in [b, c]) {
      canvas.drawCircle(p, 8, Paint()..color = editShiftAccent.value);
      canvas.drawCircle(p, 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_EaseGraphPainter old) =>
      old.first != first || old.second != second || old.cyclic != cyclic;
}

class _BezierCurveEditor extends StatefulWidget {
  final Offset first, second;
  final bool cyclic;
  final void Function(Offset, Offset) onChanged;
  const _BezierCurveEditor({
    required this.first, required this.second, required this.onChanged,
    this.cyclic = false,
  });
  @override
  State<_BezierCurveEditor> createState() => _BezierCurveEditorState();
}

class _BezierCurveEditorState extends State<_BezierCurveEditor> {
  int _dragging = 1;

  Offset _pixel(Offset p, Size s) =>
      Offset(8 + p.dx * (s.width - 16), s.height - 8 - p.dy * (s.height - 16));

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    final size = Size(box.maxWidth, 142);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) {
        final a = _pixel(widget.first, size), b = _pixel(widget.second, size);
        _dragging = (d.localPosition - a).distance < (d.localPosition - b).distance ? 1 : 2;
      },
      onPanUpdate: (d) {
        final p = Offset(
          ((d.localPosition.dx - 8) / (size.width - 16)).clamp(0.0, 1.0).toDouble(),
          (1 - (d.localPosition.dy - 8) / (size.height - 16)).clamp(-.25, 1.25).toDouble(),
        );
        if (_dragging == 1) {
          widget.onChanged(Offset(p.dx.clamp(0.0, widget.second.dx).toDouble(), p.dy), widget.second);
        } else {
          widget.onChanged(widget.first, Offset(p.dx.clamp(widget.first.dx, 1.0).toDouble(), p.dy));
        }
      },
      child: Container(
        height: 142,
        decoration: BoxDecoration(
          color: const Color(0xFF101522),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: CustomPaint(
          painter: _EaseGraphPainter(widget.first, widget.second, widget.cyclic),
          child: const SizedBox.expand(),
        ),
      ),
    );
  });
}


class _TimelineRulerPainter extends CustomPainter {
  final double duration;
  final double currentSeconds;
  final List<int> bookmarks;
  _TimelineRulerPainter({required this.duration, required this.currentSeconds, required this.bookmarks});

  @override
  void paint(Canvas canvas, Size size) {
    final total = duration <= 0 ? 1.0 : duration;
    final base = Paint()..color = Colors.white24..strokeWidth = 1;
    final minor = Paint()..color = Colors.white12..strokeWidth = 1;
    final active = Paint()..color = const Color(0xFF79C8FF)..strokeWidth = 1.4;
    canvas.drawLine(Offset(0, size.height - 1), Offset(size.width, size.height - 1), base);
    final step = total > 45 ? 5 : total > 18 ? 2 : 1;
    for (int seconds = 0; seconds <= total.ceil(); seconds++) {
      final x = seconds / total * size.width;
      final major = seconds % step == 0;
      canvas.drawLine(Offset(x, major ? 12 : 21), Offset(x, size.height), major ? base : minor);
      if (major) {
        final painter = TextPainter(
          text: TextSpan(text: seconds.toString(), style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w600)),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(canvas, Offset(x + 3, 1));
      }
    }
    for (final mark in bookmarks) {
      final x = mark / 1000 / total * size.width;
      canvas.drawLine(Offset(x, 11), Offset(x, size.height), Paint()..color = const Color(0xFFFFD45B)..strokeWidth = 1.3);
    }
    final playheadX = (currentSeconds / total * size.width).clamp(0.0, size.width).toDouble();
    canvas.drawLine(Offset(playheadX, 0), Offset(playheadX, size.height), active);
  }

  @override
  bool shouldRepaint(_TimelineRulerPainter old) =>
      old.duration != duration || old.currentSeconds != currentSeconds || old.bookmarks.length != bookmarks.length ||
      old.bookmarks.join(',') != bookmarks.join(',');
}

class AudioTrack {
  final String path;
  final String title;
  final AudioPlayer player;
  double volume;
  double start = 0;
  double end = 1;
  bool hidden = false;
  AudioTrack({required this.path, required this.title, this.volume = .8})
      : player = AudioPlayer();
}

class MeshPainter extends CustomPainter {
  final List<Offset> pts;
  final Color center;
  MeshPainter(this.pts, this.center);
  @override
  void paint(Canvas canvas, Size s) {
    final cols = [Colors.pink, Colors.orange, Colors.yellow, Colors.purple, center,
      Colors.green, Colors.indigo, Colors.cyan, Colors.teal];
    final idx = <int>[];
    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < 2; c++) {
        final a = r * 3 + c;
        idx.addAll([a, a + 1, a + 3, a + 1, a + 4, a + 3]);
      }
    }
    final v = ui.Vertices(ui.VertexMode.triangles,
        [for (final p in pts) Offset(p.dx * s.width, p.dy * s.height)],
        colors: cols, indices: idx);
    canvas.drawVertices(v, BlendMode.srcOver, Paint());
  }

  @override
  bool shouldRepaint(MeshPainter old) => true;
}

const tabs = [
  ('Transform', Icons.open_with), ('Adjust', Icons.tune), ('Color', Icons.palette),
  ('Effects', Icons.auto_awesome), ('Mesh', Icons.grid_on), ('Text', Icons.text_fields),
  ('Opacity', Icons.opacity), ('Keyframes', Icons.diamond_outlined),
  ('Timing', Icons.timelapse), ('Audio', Icons.volume_up), ('Layer', Icons.layers),
];

// ---------- Editor ----------
class Editor extends StatefulWidget {
  final String projectName;
  final String projectId;
  const Editor({super.key, this.projectName = 'Untitled project', this.projectId = 'default'});
  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> with SingleTickerProviderStateMixin {
  VideoPlayerController? _vc;
  final List<Layer> _layers = [];
  final List<AudioTrack> _audioTracks = [];
  final List<List<Layer>> _undoStack = [];
  final List<List<Layer>> _redoStack = [];
  final Set<int> _multiSelection = <int>{};
  bool _multiSelectMode = false;
  int? _sel;
  int _videoFx = 0, _tab = 0;
  String _fxCategory = 'All', _fxSearch = '';
  bool _pivotMode = false, _exporting = false;
  double _previewZoom = 1.0;
  double _timelineZoom = 1.0;
  double _vol = 1;
  int _lastAudioSyncBucket = -1;
  double _trimStart = 0, _trimEnd = 0;
  double _videoFxStrength = 1, _videoFxSpeed = 1;
  double _brightness = 0, _contrast = 1, _saturation = 1;
  String? _videoPath;
  Size _stageSize = const Size(360, 230);
  bool _showGrid = false, _previewFull = false, _videoHidden = false;
  final List<int> _bookmarks = [];
  int? _draggingBookmarkTime;
  Ticker? _playbackTicker;
  final Stopwatch _previewStopwatch = Stopwatch();
  int _previewAnchorMs = 0;
  int _tickDivider = 0;
  Timer? _autosaveTimer;
  bool _restoringProject = false;
  StateSetter? _inspectorSheetSetState;
  String _projectAspect = '16:9';
  int _projectWidth = 1920, _projectHeight = 1080, _projectFps = 30;
  Color _projectBackground = Colors.black;

  @override
  void initState() {
    super.initState();
    _restoreProject();
    _playbackTicker = createTicker((_) {
      final controller = _vc;
      if (controller == null || !controller.value.isPlaying) {
        if (_playbackTicker?.isActive == true) _playbackTicker!.stop();
        if (mounted) setState(() {});
        return;
      }
      if (++_tickDivider % 2 != 0) return;
      final frameMs = _ms;
      for (final layer in _layers) { layer.apply(frameMs); }
      if (mounted) setState(() {});
    });
  }

  void _queueProjectSave() {
    if (_restoringProject || _vc?.value.isPlaying == true) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 650), _saveProject);
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _queueProjectSave();
  }

  Future<String> _keepProjectMedia(String source, String kind) async {
    final docs = await getApplicationDocumentsDirectory();
    final folder = Directory('${docs.path}/EditShiftProjects/${widget.projectId}/media');
    await folder.create(recursive: true);
    final extension = source.contains('.') ? source.split('.').last.split('?').first : 'dat';
    final destination = '${folder.path}/${kind}_${DateTime.now().microsecondsSinceEpoch}.$extension';
    return (await File(source).copy(destination)).path;
  }

  Map<String, dynamic> _encodeLayer(Layer layer) => {
    'type': layer.isCamera ? 'camera' : layer.isNull ? 'null' : layer.isSolid ? 'solid' :
      layer.isShape ? 'shape' : layer.isAdjustment ? 'adjustment' :
      layer.isMesh ? 'mesh' : layer.isImage ? 'image' : 'text',
    'imagePath': layer.imagePath, 'text': layer.text,
    'pos': [layer.pos.dx, layer.pos.dy], 'scale': layer.scale,
    'rot': layer.rot, 'opacity': layer.opacity, 'fontSize': layer.fontSize,
    'start': layer.start, 'end': layer.end, 'bend': layer.bend,
    'fxStrength': layer.fxStrength, 'fxSpeed': layer.fxSpeed,
    'mangaEffects': layer.mangaEffects.map((e)=>e.toJson()).toList(),
    'pivot': [layer.pivot.dx, layer.pivot.dy], 'fx': layer.fx,
    'color': layer.color.value, 'bold': layer.bold, 'italic': layer.italic,
    'flipX': layer.flipX, 'flipY': layer.flipY, 'shadow': layer.shadow,
    'hidden': layer.hidden, 'parentIndex': layer.parentIndex, 'groupId': layer.groupId,
    'effectKeyframes': layer.effectKfs.map((key) => {'t': key.t, 'strength': key.strength, 'speed': key.speed}).toList(),
    'mesh': layer.mesh.map((p) => [p.dx, p.dy]).toList(),
    'keyframes': layer.kfs.map((k) => {
      't': k.t, 'pos': [k.pos.dx, k.pos.dy], 'scale': k.scale,
      'rot': k.rot, 'opacity': k.opacity,
    }).toList(),
    'curveHandle1': [layer.curveHandle1.dx, layer.curveHandle1.dy],
    'curveHandle2': [layer.curveHandle2.dx, layer.curveHandle2.dy],
    'curveCyclic': layer.curveCyclic,
  };

  Layer _decodeLayer(Map<String, dynamic> data) {
    final p = (data['pos'] as List?) ?? [0, 0];
    final pos = Offset((p[0] as num).toDouble(), (p[1] as num).toDouble());
    final type = data['type'];
    final layer = switch (type) {
      'camera' => Layer.camera(pos),
      'null' => Layer.nullObject(pos),
      'solid' => Layer.solid(pos),
      'shape' => Layer.shape(pos),
      'adjustment' => Layer.adjustment(pos),
      'mesh' => Layer.mesh(pos),
      'image' => Layer.image(data['imagePath'] as String?, pos),
      _ => Layer.text((data['text'] ?? 'Text').toString(), pos),
    };
    final pivot = (data['pivot'] as List?) ?? [.5, .5];
    final h1 = (data['curveHandle1'] as List?) ?? [.42, 0];
    final h2 = (data['curveHandle2'] as List?) ?? [.58, 1];
    layer
      ..text = (data['text'] ?? layer.text).toString()
      ..scale = (data['scale'] as num? ?? 1).toDouble()
      ..rot = (data['rot'] as num? ?? 0).toDouble()
      ..opacity = (data['opacity'] as num? ?? 1).toDouble()
      ..fontSize = (data['fontSize'] as num? ?? 30).toDouble()
      ..start = (data['start'] as num? ?? 0).toDouble()
      ..end = (data['end'] as num? ?? 1).toDouble()
      ..bend = (data['bend'] as num? ?? 0).toDouble()
      ..fxStrength = (data['fxStrength'] as num? ?? 1).toDouble()
      ..fxSpeed = (data['fxSpeed'] as num? ?? 1).toDouble()
      ..mangaEffects = (data['mangaEffects'] as List? ?? []).map((e)=>MangaCutEffectClip.fromJson(Map<String,dynamic>.from(e))).toList()
      ..pivot = Offset((pivot[0] as num).toDouble(), (pivot[1] as num).toDouble())
      ..fx = (data['fx'] as num? ?? 0).toInt().clamp(0, fxLibrary.length - 1).toInt()
      ..color = Color((data['color'] as num? ?? Colors.white.value).toInt())
      ..bold = data['bold'] as bool? ?? true
      ..italic = data['italic'] as bool? ?? false
      ..flipX = data['flipX'] as bool? ?? false
      ..flipY = data['flipY'] as bool? ?? false
      ..shadow = data['shadow'] as bool? ?? false
      ..hidden = data['hidden'] as bool? ?? false
      ..parentIndex = (data['parentIndex'] as num?)?.toInt()
      ..groupId = (data['groupId'] as num?)?.toInt()
      ..curveHandle1 = Offset((h1[0] as num).toDouble(), (h1[1] as num).toDouble())
      ..curveHandle2 = Offset((h2[0] as num).toDouble(), (h2[1] as num).toDouble())
      ..curveCyclic = data['curveCyclic'] as bool? ?? false;
    final mesh = data['mesh'] as List?;
    if (mesh != null) {
      layer.mesh = mesh.map((point) => Offset(
        (point[0] as num).toDouble(), (point[1] as num).toDouble(),
      )).toList();
    }
    final keys = data['keyframes'] as List? ?? [];
    layer.effectKfs = ((data['effectKeyframes'] as List?) ?? []).map((item) {
      final key = Map<String, dynamic>.from(item as Map);
      return EffectKF((key['t'] as num).toInt(), (key['strength'] as num? ?? 1).toDouble(), (key['speed'] as num? ?? 1).toDouble());
    }).toList()..sort((a, b) => a.t.compareTo(b.t));
    layer.kfs = keys.map((item) {
      final key = Map<String, dynamic>.from(item as Map);
      final kp = key['pos'] as List;
      return KF(
        (key['t'] as num).toInt(),
        Offset((kp[0] as num).toDouble(), (kp[1] as num).toDouble()),
        (key['scale'] as num).toDouble(),
        (key['rot'] as num).toDouble(),
        (key['opacity'] as num).toDouble(),
      );
    }).toList()..sort((a, b) => a.t.compareTo(b.t));
    return layer;
  }

  Future<void> _saveProject() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, dynamic>{
        'version': 1,
        'projectAspect': _projectAspect, 'projectWidth': _projectWidth,
        'projectHeight': _projectHeight, 'projectFps': _projectFps,
        'projectBackground': _projectBackground.value,
        'videoPath': _videoPath,
        'trimStart': _trimStart, 'trimEnd': _trimEnd,
        'videoFx': _videoFx, 'videoFxStrength': _videoFxStrength,
        'videoFxSpeed': _videoFxSpeed,
        'brightness': _brightness, 'contrast': _contrast,
        'saturation': _saturation, 'videoHidden': _videoHidden,
        'layers': _layers.map(_encodeLayer).toList(),
        'audio': _audioTracks.map((track) => {
          'path': track.path, 'title': track.title, 'volume': track.volume,
          'start': track.start, 'end': track.end, 'hidden': track.hidden,
        }).toList(),
        'bookmarks': _bookmarks,
        'selected': _sel,
      };
      await prefs.setString('editshift.project.${widget.projectId}', jsonEncode(data));
    } catch (_) {
      // Autosave must never interrupt editing; the last valid save remains intact.
    }
  }

  Future<void> _restoreProject() async {
    _restoringProject = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('editshift.project.${widget.projectId}');
      if (raw == null) return;
      final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      _layers
        ..clear()
        ..addAll((data['layers'] as List? ?? []).map((item) =>
          _decodeLayer(Map<String, dynamic>.from(item as Map))));
      _bookmarks
        ..clear()
        ..addAll((data['bookmarks'] as List? ?? []).map((v) => (v as num).toInt()));
      _projectAspect = (data['projectAspect'] ?? '16:9').toString();
      _projectWidth = (data['projectWidth'] as num? ?? 1920).toInt();
      _projectHeight = (data['projectHeight'] as num? ?? 1080).toInt();
      _projectFps = (data['projectFps'] as num? ?? 30).toInt();
      _projectBackground = Color((data['projectBackground'] as num? ?? Colors.black.value).toInt());
      _videoFx = (data['videoFx'] as num? ?? 0).toInt().clamp(0, fxLibrary.length - 1).toInt();
      _videoFxStrength = (data['videoFxStrength'] as num? ?? 1).toDouble();
      _videoFxSpeed = (data['videoFxSpeed'] as num? ?? 1).toDouble();
      _brightness = (data['brightness'] as num? ?? 0).toDouble();
      _contrast = (data['contrast'] as num? ?? 1).toDouble();
      _saturation = (data['saturation'] as num? ?? 1).toDouble();
      _videoHidden = data['videoHidden'] as bool? ?? false;
      _trimStart = (data['trimStart'] as num? ?? 0).toDouble();
      _trimEnd = (data['trimEnd'] as num? ?? 0).toDouble();
      _sel = (data['selected'] as num?)?.toInt();
      _audioTracks.clear();
      for (final item in (data['audio'] as List? ?? [])) {
        final audio = Map<String, dynamic>.from(item as Map);
        final path = audio['path'] as String;
        if (!File(path).existsSync()) continue;
        final track = AudioTrack(
          path: path, title: (audio['title'] ?? 'Audio').toString(),
          volume: (audio['volume'] as num? ?? .8).toDouble(),
        )
          ..start = (audio['start'] as num? ?? 0).toDouble()
          ..end = (audio['end'] as num? ?? 1).toDouble()
          ..hidden = audio['hidden'] as bool? ?? false;
        await track.player.setSourceDeviceFile(path);
        _audioTracks.add(track);
      }
      final video = data['videoPath'] as String?;
      if (video != null && File(video).existsSync()) {
        _videoPath = video;
        final controller = VideoPlayerController.file(File(video));
        await controller.initialize();
        _trimEnd = _trimEnd > 0 ? _trimEnd : controller.value.duration.inMilliseconds / 1000;
        controller.addListener(() {
          if (mounted && !controller.value.isPlaying) setState(() {});
        });
        _vc = controller;
        await controller.setVolume(_vol);
      }
    } catch (_) {
      // Ignore an incomplete/corrupt draft and leave the editor usable.
    } finally {
      _restoringProject = false;
      if (mounted) setState(() {});
    }
  }

  int get _ms => _vc?.value.isPlaying == true
      ? _previewAnchorMs + _previewStopwatch.elapsedMilliseconds
      : (_vc?.value.position.inMilliseconds ?? 0);
  double get _t {
    final d = _vc?.value.duration.inMilliseconds ?? 0;
    return d == 0 ? 0 : _ms / d;
  }
  double get _videoDuration {
    final d = (_vc?.value.duration.inMilliseconds ?? 0) / 1000;
    return d > 0 ? d : 1;
  }
  Duration _time(double seconds) =>
      Duration(milliseconds: (seconds * 1000).round());

  List<Layer> _layerSnapshot() =>
      _layers.map((layer) => layer.snapshot()).toList();

  void _pushUndo() {
    _undoStack.add(_layerSnapshot());
    if (_undoStack.length > 40) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_layerSnapshot());
    final previous = _undoStack.removeLast();
    setState(() {
      _layers
        ..clear()
        ..addAll(previous.map((layer) => layer.snapshot()));
      _sel = _layers.isEmpty ? null : (_sel ?? 0).clamp(0, _layers.length - 1).toInt();
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_layerSnapshot());
    final next = _redoStack.removeLast();
    setState(() {
      _layers
        ..clear()
        ..addAll(next.map((layer) => layer.snapshot()));
      _sel = _layers.isEmpty ? null : (_sel ?? 0).clamp(0, _layers.length - 1).toInt();
    });
  }

  void _refreshInspector() {
    if (mounted) setState(() {});
    _inspectorSheetSetState?.call(() {});
  }

  void _ed(Layer l, VoidCallback f) {
    _pushUndo();
    setState(() {
      f();
      if (l.kfs.isNotEmpty) l.upsert(_ms);
    });
    _inspectorSheetSetState?.call(() {});
  }

  void _addEffectKeyframe(Layer layer) {
    _pushUndo();
    layer.effectKfs.removeWhere((key) => (key.t - _ms).abs() < 60);
    layer.effectKfs.add(EffectKF(_ms, layer.fxStrength, layer.fxSpeed));
    layer.effectKfs.sort((a, b) => a.t.compareTo(b.t));
    _refreshInspector();
  }

  void _removeEffectKeyframe(Layer layer) {
    final index = layer.effectKfs.indexWhere((key) => (key.t - _ms).abs() < 60);
    if (index < 0) return;
    _pushUndo();
    layer.effectKfs.removeAt(index);
    _refreshInspector();
  }

  // Shared slider used by the layer inspector. Keep the compact, flat
  // Keyflow-inspired styling while routing edits through the undo system.
  Widget _s(
    Layer layer,
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    final safeValue = value.clamp(min, max).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                safeValue.toStringAsFixed(2),
                style: const TextStyle(
                  color: Color(0xFF20E36F),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [ui.FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Slider(
            value: safeValue,
            min: min,
            max: max,
            onChanged: (next) => _ed(layer, () => onChanged(next)),
          ),
        ],
      ),
    );
  }

  // Project/video-level slider; its callback owns the setState update.
  Widget _globalS(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String suffix = '',
  }) {
    final safeValue = value.clamp(min, max).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${safeValue.toStringAsFixed(2)}$suffix',
                style: const TextStyle(
                  color: Color(0xFF20E36F),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [ui.FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Slider(
            value: safeValue,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _pauseAudio() async {
    for (final track in _audioTracks) {
      await track.player.pause();
    }
  }

  Future<void> _syncAudio() async {
    final now = _ms / 1000;
    for (final track in _audioTracks) {
      if (track.hidden) {
        if (track.player.state == PlayerState.playing) await track.player.pause();
        continue;
      }
      final startMs = (track.start * _videoDuration * 1000).round();
      final endMs = (track.end * _videoDuration * 1000).round();
      if (now * 1000 >= startMs && now * 1000 < endMs) {
        final offset = Duration(milliseconds: (_ms - startMs).clamp(0, 1 << 30).toInt());
        if (track.player.state != PlayerState.playing) {
          await track.player.play(
            DeviceFileSource(track.path),
            volume: track.volume,
            position: offset,
          );
        } else {
          await track.player.setVolume(track.volume);
        }
      } else if (track.player.state == PlayerState.playing) {
        await track.player.pause();
      }
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _vc;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      await controller.pause();
      _previewStopwatch.stop();
      _playbackTicker?.stop();
      await _pauseAudio();
    } else {
      if (controller.value.position >= _time(_trimEnd)) {
        await controller.seekTo(_time(_trimStart));
      }
      await controller.setVolume(_vol);
      _lastAudioSyncBucket = -1;
      await controller.play();
      _previewAnchorMs = controller.value.position.inMilliseconds;
      _previewStopwatch..reset()..start();
      if (_playbackTicker?.isActive != true) _playbackTicker?.start();
      await _syncAudio();
    }
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    final savedPath = await _keepProjectMedia(picked.path, 'video');
    await _vc?.dispose();
    _videoPath = savedPath;
    final controller = VideoPlayerController.file(File(savedPath));
    await controller.initialize();
    await controller.setLooping(false);
    _trimStart = 0;
    _trimEnd = controller.value.duration.inMilliseconds / 1000;
    controller.addListener(() {
      final position = controller.value.position;
      if (controller.value.isPlaying) {
        _previewAnchorMs = position.inMilliseconds;
        _previewStopwatch..reset()..start();
        final bucket = position.inMilliseconds ~/ 200;
        if (bucket != _lastAudioSyncBucket) {
          _lastAudioSyncBucket = bucket;
          _syncAudio();
        }
      }
      if (!controller.value.isPlaying) _previewStopwatch.stop();
      if (!controller.value.isPlaying && mounted) setState(() {});
      if (controller.value.isPlaying &&
          _trimEnd > _trimStart &&
          position >= _time(_trimEnd)) {
        controller.pause();
        controller.seekTo(_time(_trimStart));
        _pauseAudio();
      }
      if (mounted) setState(() {});
    });
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _vc = controller);
    await controller.setVolume(_vol);
  }

  Future<void> _addPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final savedPath = await _keepProjectMedia(picked.path, 'image');
    _add(Layer.image(savedPath, const Offset(52, 52)));
  }

  Future<void> _addAudio() async {
    final picked = await FilePicker.pickFile(type: FileType.audio);
    if (picked == null || picked.path == null) return;
    final savedPath = await _keepProjectMedia(picked.path!, 'audio');
    final track = AudioTrack(path: savedPath, title: picked.name)
      ..start = _t.clamp(0.0, 1.0).toDouble();
    await track.player.setSourceDeviceFile(track.path);
    if (!mounted) {
      await track.player.dispose();
      return;
    }
    setState(() => _audioTracks.add(track));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added audio: ${track.title}')),
    );
  }

  Uint8List _makeSfxWave(String kind) {
    final sampleRate = 22050;
    final seconds = switch (kind) {
      'Click' => .075,
      'Pop' => .24,
      'Whoosh' => .8,
      _ => 1.0,
    };
    final sampleCount = (sampleRate * seconds).round();
    final bytes = Uint8List(44 + sampleCount * 2);
    final data = ByteData.sublistView(bytes);
    void writeTag(int offset, String tag) {
      for (int i = 0; i < tag.length; i++) {
        data.setUint8(offset + i, tag.codeUnitAt(i));
      }
    }
    writeTag(0, 'RIFF');
    data.setUint32(4, 36 + sampleCount * 2, Endian.little);
    writeTag(8, 'WAVE');
    writeTag(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    writeTag(36, 'data');
    data.setUint32(40, sampleCount * 2, Endian.little);

    final random = math.Random(7919 + kind.hashCode);
    for (int i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final progress = t / seconds;
      final envelope = switch (kind) {
        'Click' => math.pow(1 - progress, 4).toDouble(),
        'Pop' => math.pow(1 - progress, 3).toDouble(),
        'Whoosh' => math.sin(math.pi * progress).clamp(0.0, 1.0).toDouble(),
        _ => math.pow(progress, .6).toDouble() * (1 - progress),
      };
      final frequency = switch (kind) {
        'Click' => 1800 - 900 * progress,
        'Pop' => 360 - 230 * progress,
        'Whoosh' => 130 + 520 * progress,
        _ => 160 + 1100 * progress,
      };
      final tone = math.sin(2 * math.pi * frequency * t);
      final noise = random.nextDouble() * 2 - 1;
      final sample = kind == 'Whoosh'
          ? (tone * .3 + noise * .7) * envelope * .52
          : kind == 'Click'
              ? tone * envelope * .75
              : (tone * .78 + noise * .12) * envelope * .68;
      data.setInt16(
        44 + i * 2,
        (sample.clamp(-1.0, 1.0) * 32767).round(),
        Endian.little,
      );
    }
    return bytes;
  }

  Future<void> _addSoundEffect(String kind) async {
    final directory = await getApplicationDocumentsDirectory();
    final safeName = kind.toLowerCase().replaceAll(' ', '_');
    final folder = Directory('${directory.path}/EditShiftProjects/${widget.projectId}/media');
    await folder.create(recursive: true);
    final path = '${folder.path}/${safeName}_${DateTime.now().microsecondsSinceEpoch}.wav';
    final file = File(path);
    await file.writeAsBytes(_makeSfxWave(kind), flush: true);
    final effectDuration = switch (kind) { 'Click' => .075, 'Pop' => .24, 'Whoosh' => .8, _ => 1.0 };
    final start = _t.clamp(0.0, 1.0).toDouble();
    final track = AudioTrack(path: path, title: 'EditShift $kind')
      ..start = start
      ..end = (start + effectDuration / _videoDuration).clamp(start, 1.0).toDouble();
    await track.player.setSourceDeviceFile(path);
    if (!mounted) {
      await track.player.dispose();
      return;
    }
    setState(() => _audioTracks.add(track));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$kind sound effect added to the timeline')),
    );
  }

  Future<void> _addText() async {
    final ctrl = TextEditingController(text: 'Your caption');
    final t = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF171A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add a caption'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Add caption'),
          ),
        ],
      ),
    );
    if (t != null && t.isNotEmpty) {
      _add(Layer.text(t, const Offset(60, 60)));
    }
  }

  void _add(Layer layer) {
    _pushUndo();
    setState(() {
      _layers.add(layer);
      _sel = _layers.length - 1;
    });
  }

  void _splitSelected() {
    final index = _sel;
    if (index == null || index < 0 || index >= _layers.length) return;
    final layer = _layers[index];
    final splitAt = (_ms / 1000 / _videoDuration).clamp(0.0, 1.0).toDouble();
    if (splitAt <= layer.start + .01 || splitAt >= layer.end - .01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Move the playhead inside the selected clip to split it.')),
      );
      return;
    }
    _pushUndo();
    final right = layer.snapshot()..start = splitAt;
    setState(() {
      layer.end = splitAt;
      _layers.insert(index + 1, right);
      _sel = index + 1;
    });
  }

  bool _wouldCreateParentCycle(int childIndex, int proposedParent) {
    var cursor = proposedParent;
    final visited = <int>{};
    while (cursor >= 0 && cursor < _layers.length && visited.add(cursor)) {
      if (cursor == childIndex) return true;
      final next = _layers[cursor].parentIndex;
      if (next == null) return false;
      cursor = next;
    }
    return false;
  }

  void _openEditorTab(String tab) {
    final index = tabs.indexWhere((item) => item.$1 == tab);
    if (index < 0) return;
    setState(() => _tab = index);
    _openInspectorSheet();
  }

  void _addCamera() => _add(Layer.camera(const Offset(120, 85)));
  void _addNull() => _add(Layer.nullObject(const Offset(90, 90)));

  void _toggleMultiSelect(int index) {
    if (index < 0 || index >= _layers.length) return;
    setState(() {
      _multiSelectMode = true;
      if (!_multiSelection.add(index)) _multiSelection.remove(index);
      _sel = index;
      if (_multiSelection.isEmpty) _multiSelectMode = false;
    });
  }

  void _clearMultiSelect() {
    setState(() {
      _multiSelection.clear();
      _multiSelectMode = false;
    });
  }

  Future<void> _parentSelectedLayer() async {
    final child = _sel;
    if (child == null || child < 0 || child >= _layers.length) return;
    final parent = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: const Color(0xFF151719),
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(title: Text('Parent layer', style: TextStyle(fontWeight: FontWeight.w800))),
          ListTile(
            leading: const Icon(Icons.link_off_rounded),
            title: const Text('No parent'),
            onTap: () => Navigator.pop(sheetContext, -1),
          ),
          for (int i = 0; i < _layers.length; i++)
            if (i != child && _layers[i].isController && !_wouldCreateParentCycle(child, i))
              ListTile(
                leading: Icon(_layers[i].isCamera ? Icons.videocam_rounded : Icons.control_camera_rounded),
                title: Text(_layers[i].text),
                onTap: () => Navigator.pop(sheetContext, i),
              ),
          if (!_layers.any((layer) => layer.isController))
            ListTile(
              leading: const Icon(Icons.add_circle_outline_rounded),
              title: const Text('Create Null parent'),
              onTap: () => Navigator.pop(sheetContext, -2),
            ),
        ]),
      ),
    );
    if (parent == null) return;
    if (parent == -2) {
      final controllerIndex = _layers.length;
      _add(Layer.nullObject(const Offset(90, 90))..text = 'Parent Null');
      if (child < _layers.length) {
        _ed(_layers[child], () => _layers[child].parentIndex = controllerIndex);
      }
      return;
    }
    _ed(_layers[child], () => _layers[child].parentIndex = parent < 0 ? null : parent);
  }

  void _groupSelectedLayers() {
    final selected = _multiSelection.where((i) => i >= 0 && i < _layers.length).toList()..sort();
    if (selected.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Long-press layer rows to select at least two layers to group.')),
      );
      return;
    }
    _pushUndo();
    final groupId = _layers.fold<int>(0, (highest, layer) =>
        layer.groupId == null ? highest : math.max(highest, layer.groupId!)) + 1;
    setState(() {
      for (final index in selected) {
        _layers[index].groupId = groupId;
      }
      _sel = selected.last;
      _multiSelection.clear();
      _multiSelectMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Grouped ${selected.length} layers. No Null object was created.')),
    );
  }

  void _createParentForSelectedLayers() {
    final selected = (_multiSelectMode && _multiSelection.isNotEmpty
        ? _multiSelection
        : <int>{if (_sel != null) _sel!})
        .where((i) => i >= 0 && i < _layers.length)
        .toList()
      ..sort();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select one or more layers first.')),
      );
      return;
    }
    final parentIndex = _layers.length;
    _pushUndo();
    setState(() {
      final parent = Layer.nullObject(const Offset(90, 90))
        ..text = 'Parent ${parentIndex + 1}';
      _layers.add(parent);
      for (final index in selected) {
        if (index != parentIndex && !_wouldCreateParentCycle(index, parentIndex)) {
          _layers[index].parentIndex = parentIndex;
        }
      }
      _sel = parentIndex;
      _multiSelection.clear();
      _multiSelectMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created parent for ${selected.length} layer${selected.length == 1 ? '' : 's'}.')),
    );
  }

  void _addKeyframeNow() {
    if (_sel == null || _sel! >= _layers.length) return;
    _ed(_layers[_sel!], () => _layers[_sel!].upsert(_ms));
  }

  void _removeKeyframeAtPlayhead() {
    if (_sel == null || _sel! >= _layers.length) return;
    final layer = _layers[_sel!];
    final index = layer.kfs.indexWhere((key) => (key.t - _ms).abs() < 60);
    if (index < 0) return;
    _pushUndo();
    setState(() => layer.kfs.removeAt(index));
  }

  void _deleteSelected() {
    final index = _sel;
    if (index == null || index < 0 || index >= _layers.length) return;
    _pushUndo();
    setState(() {
      _layers.removeAt(index);
      for (final layer in _layers) {
        if (layer.parentIndex == index) layer.parentIndex = null;
        else if (layer.parentIndex != null && layer.parentIndex! > index) layer.parentIndex = layer.parentIndex! - 1;
      }
      _sel = _layers.isEmpty ? null : math.min(index, _layers.length - 1).toInt();
      _pivotMode = false;
    });
  }

  Future<void> _removeVideo() async {
    await _vc?.pause();
    await _pauseAudio();
    await _vc?.dispose();
    if (!mounted) return;
    setState(() {
      _vc = null;
      _videoPath = null;
      _trimStart = 0;
      _trimEnd = 0;
      _lastAudioSyncBucket = -1;
    });
  }

  void _deleteAudio(AudioTrack track) {
    setState(() => _audioTracks.remove(track));
    track.player.dispose();
  }

  List<double> _adjustmentMatrix() {
    final s = _saturation;
    final c = _contrast;
    final b = _brightness * 255 + 128 * (1 - c);
    return [
      (.213 + .787 * s) * c, (.715 - .715 * s) * c, (.072 - .072 * s) * c, 0, b,
      (.213 - .213 * s) * c, (.715 + .285 * s) * c, (.072 - .072 * s) * c, 0, b,
      (.213 - .213 * s) * c, (.715 - .715 * s) * c, (.072 + .928 * s) * c, 0, b,
      0, 0, 0, 1, 0,
    ];
  }

  String _ffArg(String value) =>
      '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

  String _filterText(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll(':', r'\:')
      .replaceAll("'", r"\'")
      .replaceAll(',', r'\,')
      .replaceAll('%', r'\%')
      .replaceAll('[', r'\[')
      .replaceAll(']', r'\]')
      .replaceAll(';', r'\;')
      .replaceAll('\n', r'\n');

  String _exportEffectFilter() {
    final name = fxLibrary[_videoFx].$1;
    final amount = _videoFxStrength.clamp(0.0, 2.0);
    final speed = _videoFxSpeed.clamp(.1, 3.0).toDouble();
    if (name == 'None' || name == 'Bend') return '';
    switch (name) {
      case 'Wave Warp':
        final amplitude = (8 * amount).toStringAsFixed(2);
        final wavelength = (80 / amount.clamp(.25, 2)).toStringAsFixed(2);
        return "geq=lum='lum(X+sin(Y/$wavelength+T*${2 * speed})*$amplitude,Y)':cb='cb(X+sin(Y/$wavelength+T*${2 * speed})*$amplitude,Y)':cr='cr(X+sin(Y/$wavelength+T*${2 * speed})*$amplitude,Y)'";
      case 'Shake':
        final drift = (.025 * amount).toStringAsFixed(4);
        return "crop=iw*0.92:ih*0.92:x='(iw-ow)/2+sin(t*${32 * speed})*iw*$drift':y='(ih-oh)/2+cos(t*${27 * speed})*ih*$drift',scale=trunc(iw/0.92/2)*2:trunc(ih/0.92/2)*2";
      case 'Scale Assist':
        return "scale=w='iw*(1+" + (0.028 * amount).toStringAsFixed(4) + "*sin(t*2.4*" + speed.toStringAsFixed(2) + "))':h='ih*(1+" + (0.028 * amount).toStringAsFixed(4) + "*sin(t*2.4*" + speed.toStringAsFixed(2) + "))':eval=frame,crop=iw/1.06:ih/1.06";
      case 'Zoom Pulse':
        return 'scale=iw*1.08:ih*1.08,crop=iw/1.08:ih/1.08';
      case 'Spin':
        return "rotate='0.025*sin(t*${2.4 * speed})':c=black@0";
      case 'Glitch':
      case 'RGB Split':
        return "rgbashift=rh='sin(t*${42 * speed})*${(5 * amount).toStringAsFixed(2)}':bh='-sin(t*${37 * speed})*${(5 * amount).toStringAsFixed(2)}'";
      case 'Flash':
        return "eq=brightness='if(lt(mod(t,${(0.5 / speed).toStringAsFixed(3)}),0.08),${(0.65 * amount).toStringAsFixed(3)},0)'";
      case 'Glow':
        return "gblur=sigma=${(2.5 * amount).toStringAsFixed(2)}";
      case 'Vignette':
        return "vignette=PI/4";
      case 'Film Grain':
        return "noise=alls=${(18 * amount).round()}:allf=t+u";
      case 'Pixelate':
        return "scale=iw/16:ih/16:flags=neighbor,scale=iw*16:ih*16:flags=neighbor";
      case 'Soft Blur':
      case 'Dream Blur':
      case 'Gaussian Blur':
      case 'Motion Blur':
      case 'Soft Focus':
        return "gblur=sigma=${(2.5 * amount).toStringAsFixed(2)}";
      case 'Grayscale':
      case 'Mono':
      case 'Noir':
      case 'Desaturate':
        return 'hue=s=0';
      case 'Negative':
      case 'Invert':
        return 'negate';
      case 'Vintage':
      case 'Sepia':
      case 'Warm Film':
      case 'Golden Hour':
      case 'Polaroid':
        return 'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131';
      case 'Brighten':
        return 'eq=brightness=0.16';
      case 'Darken':
        return 'eq=brightness=-0.16';
      case 'High Contrast':
      case 'Deep Contrast':
        return 'eq=contrast=1.45:saturation=1.15';
      case 'Neon':
        return 'eq=saturation=1.8:contrast=1.25,unsharp=5:5:0.8';
      case 'Frost':
      case 'Arctic':
        return 'colorbalance=bs=0.18:gs=0.04';
      case 'Chromatic':
        return 'rgbashift=rh=3:bh=-3';
      default:
        final saturation = .8 + (_videoFx % 5) * .18;
        final contrast = .92 + ((_videoFx ~/ 5) % 4) * .08;
        return 'eq=contrast=${contrast.toStringAsFixed(2)}:saturation=${saturation.toStringAsFixed(2)}';
    }
  }

  String _mangaClipStrengthExpression(MangaCutEffectClip clip,double totalDuration,double trimStart){
    final frames=clip.strengthKeys.entries.toList()..sort((a,b)=>a.key.compareTo(b.key));
    if(frames.isEmpty)return clip.strength.toStringAsFixed(4);
    final timeExpr='((t+${trimStart.toStringAsFixed(4)})/${math.max(.001,totalDuration).toStringAsFixed(4)})';
    var expression=frames.last.value.toStringAsFixed(4);
    for(var i=frames.length-2;i>=0;i--){
      final a=frames[i],b=frames[i+1];
      final segment='(${a.value.toStringAsFixed(4)}+(${(b.value-a.value).toStringAsFixed(4)})*(($timeExpr-${a.key.toStringAsFixed(6)})/${(b.key-a.key).toStringAsFixed(6)}))';
      expression='if(lt($timeExpr,${b.key.toStringAsFixed(6)}),$segment,$expression)';
    }
    expression='if(lt($timeExpr,${frames.first.key.toStringAsFixed(6)}),${frames.first.value.toStringAsFixed(4)},$expression)';
    return expression;
  }

  String? _exportMangaClipFilter(MangaCutEffectClip clip,double totalDuration,double trimStart,double clipDuration){
    final start=(clip.start*totalDuration-trimStart).clamp(0.0,clipDuration).toStringAsFixed(3);
    final end=(clip.end*totalDuration-trimStart).clamp(0.0,clipDuration).toStringAsFixed(3);
    if(double.parse(end)<=double.parse(start))return null;
    final strength=_mangaClipStrengthExpression(clip,totalDuration,trimStart);
    final enable=":enable='between(t,$start,$end)'";
    switch(clip.name.toLowerCase()){
      case 'shake':
      case 'drift':
      case 'twitch':
        return "rgbashift=rh='sin(t*42)*(5*($strength))':bh='-sin(t*37)*(5*($strength))'$enable";
      case 'pulse':
      case 'bounce':
        return "eq=brightness='0.025*sin(t*5)*($strength)'$enable";
      case 'spin':
      case 'swing':
      case 'wobble':
        return "rotate='0.04*sin(t*4)*($strength)':c=none$enable";
      case 'impact':
        return "eq=brightness='if(lt(mod(t,0.5),0.08),0.5*($strength),0)'$enable";
      case 'bend':
      case 'wind':
      case 'liquify':
      case 'oscillate':
        return "geq=lum='lum(X+sin(Y/80+T*2)*(8*($strength)),Y)':cb='cb(X+sin(Y/80+T*2)*(8*($strength)),Y)':cr='cr(X+sin(Y/80+T*2)*(8*($strength)),Y)'$enable";
      default:return null;
    }
  }

  String? _exportLayerFilter(Layer layer) {
    final name = fxLibrary[layer.fx].$1;
    final strength = layer.fxStrength.clamp(0.0, 2.0).toDouble();
    final speed = layer.fxSpeed.clamp(.2, 3.0).toDouble();
    switch (name) {
      case 'None':
      case 'Bend':
      case 'Shake':
      case 'Spin':
        return null;
      case 'Wave Warp':
        final amplitude = (8 * strength).toStringAsFixed(2);
        final wavelength = (80 / strength.clamp(.25, 2)).toStringAsFixed(2);
        return "geq=lum='lum(X+sin(Y/$wavelength+T*${2 * speed})*$amplitude,Y)':cb='cb(X+sin(Y/$wavelength+T*${2 * speed})*$amplitude,Y)':cr='cr(X+sin(Y/$wavelength+T*${2 * speed})*$amplitude,Y)'";
      case 'Scale Assist':
        return "scale=w='iw*(1+" + (0.028 * strength).toStringAsFixed(4) + "*sin(t*2.4*" + speed.toStringAsFixed(2) + "))':h='ih*(1+" + (0.028 * strength).toStringAsFixed(4) + "*sin(t*2.4*" + speed.toStringAsFixed(2) + "))':eval=frame";
      case 'Zoom Pulse':
        return 'scale=iw*1.08:ih*1.08';
      case 'Glitch':
      case 'RGB Split':
      case 'Chromatic':
        return "rgbashift=rh='sin(t*" +
            (42 * speed).toStringAsFixed(2) + ")*" +
            (5 * strength).toStringAsFixed(2) +
            "':bh='-sin(t*" + (37 * speed).toStringAsFixed(2) +
            ")*" + (5 * strength).toStringAsFixed(2) + "'";
      case 'Flash':
        return "eq=brightness='if(lt(mod(t," +
            (0.5 / speed).toStringAsFixed(3) + "),0.08)," +
            (0.65 * strength).toStringAsFixed(3) + ",0)'";
      case 'Glow':
        return 'gblur=sigma=' + (2.5 * strength).toStringAsFixed(2);
      case 'Vignette':
        return 'vignette=PI/4';
      case 'Film Grain':
        return 'noise=alls=' + (18 * strength).round().toString() + ':allf=t+u';
      case 'Pixelate':
        return 'scale=iw/16:ih/16:flags=neighbor,scale=iw*16:ih*16:flags=neighbor';
      case 'Soft Blur':
      case 'Dream Blur':
      case 'Gaussian Blur':
      case 'Motion Blur':
      case 'Soft Focus':
        return 'gblur=sigma=' + (2.5 * strength).toStringAsFixed(2);
      case 'Grayscale':
      case 'Mono':
      case 'Noir':
      case 'Desaturate':
        return 'hue=s=0';
      case 'Negative':
      case 'Invert':
        return 'negate';
      case 'Vintage':
      case 'Sepia':
      case 'Warm Film':
      case 'Golden Hour':
      case 'Polaroid':
        return 'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131';
      case 'Brighten':
        return 'eq=brightness=0.16';
      case 'Darken':
        return 'eq=brightness=-0.16';
      case 'High Contrast':
      case 'Deep Contrast':
        return 'eq=contrast=1.45:saturation=1.15';
      case 'Neon':
        return 'eq=saturation=1.8:contrast=1.25,unsharp=5:5:0.8';
      case 'Frost':
      case 'Arctic':
        return 'colorbalance=bs=0.18:gs=0.04';
      default:
        return null;
    }
  }

  Future<void> _exportVideo() async {
    final source = _videoPath;
    if (source == null || !File(source).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a video clip before exporting.')),
      );
      return;
    }
    if (_exporting) return;
    setState(() => _exporting = true);
    await _vc?.pause();
    await _pauseAudio();

    try {
      final totalDuration = _videoDuration;
      final trimStart = _trimStart.clamp(0.0, math.max(0.0, totalDuration - .05)).toDouble();
      final trimEnd = _trimEnd.clamp(trimStart + .05, totalDuration).toDouble();
      final clipDuration = trimEnd - trimStart;
      final documents = await getApplicationDocumentsDirectory();
      final outputDir = Directory('${documents.path}/EditShiftLibrary');
      await outputDir.create(recursive: true);
      final outputPath =
          '${outputDir.path}/EditShift_${DateTime.now().millisecondsSinceEpoch}.mp4';

      var sourceHasAudio = false;
      try {
        final probe = await FFprobeKit.getMediaInformation(source);
        final info = await probe.getMediaInformation();
        sourceHasAudio = info?.getStreams().any((stream) => stream.getType() == 'audio') ?? false;
      } catch (_) {
        sourceHasAudio = false;
      }

      final imageLayers = _layers.where((layer) =>
          layer.isImage && !layer.hidden && layer.imagePath != null &&
          layer.end * totalDuration > trimStart &&
          layer.start * totalDuration < trimEnd).toList();
      final textLayers = _layers.where((layer) =>
          !layer.isImage && !layer.isMesh && !layer.isNull && !layer.isSolid && !layer.isShape && !layer.isAdjustment && !layer.hidden &&
          layer.text.trim().isNotEmpty &&
          layer.end * totalDuration > trimStart &&
          layer.start * totalDuration < trimEnd).toList();

      final command = StringBuffer();
      command.write('-ss ${trimStart.toStringAsFixed(3)} -i ${_ffArg(source)} ');
      for (final layer in imageLayers) {
        command.write('-loop 1 -i ${_ffArg(layer.imagePath!)} ');
      }
      for (final track in _audioTracks) {
        command.write('-i ${_ffArg(track.path)} ');
      }

      final videoFilters = <String>[];
      final effect = _exportEffectFilter();
      if (effect.isNotEmpty) videoFilters.add(effect);
      videoFilters.add(
        'eq=brightness=${_brightness.toStringAsFixed(3)}:contrast=${_contrast.toStringAsFixed(3)}:saturation=${_saturation.toStringAsFixed(3)}',
      );

      final graph = <String>[];
      graph.add('[0:v]${videoFilters.join(',')}[v0]');
      var currentVideo = 'v0';
      var outputNumber = 0;
      final videoSize = _vc?.value.size ?? const Size(1280, 720);
      final scale = videoSize.width / math.max(1, _stageSize.width);

      for (int i = 0; i < imageLayers.length; i++) {
        final layer = imageLayers[i];
        final inputIndex = i + 1;
        final imageLabel = 'image$i';
        final nextLabel = 'v${++outputNumber}';
        final imageWidth = (190 * layer.scale * scale).round().clamp(24, 4096);
        final x = (layer.pos.dx * scale).round();
        final y = (layer.pos.dy * scale).round();
        final start = (layer.start * totalDuration - trimStart).clamp(0.0, clipDuration);
        final end = (layer.end * totalDuration - trimStart).clamp(0.0, clipDuration);
        if (end <= start) continue;
        final photoFilters = <String>['scale=$imageWidth:-1'];
        final layerEffect = _exportLayerFilter(layer);
        if (layerEffect != null && layerEffect.isNotEmpty) {
          photoFilters.add(layerEffect);
        }
        for(final clip in layer.mangaEffects){
          final clipFilter=_exportMangaClipFilter(clip,totalDuration,trimStart,clipDuration);
          if(clipFilter!=null&&clipFilter.isNotEmpty)photoFilters.add(clipFilter);
        }
        if (layer.rot.abs() > .001) {
          photoFilters.add('rotate=' + layer.rot.toStringAsFixed(4) + ':ow=rotw(iw):oh=roth(ih):c=none');
        }
        photoFilters
          ..add('format=rgba')
          ..add('colorchannelmixer=aa=' + layer.opacity.clamp(0.0, 1.0).toDouble().toStringAsFixed(3));
        graph.add('[' + inputIndex.toString() + ':v]' + photoFilters.join(',') + '[' + imageLabel + ']');
        final effectName = fxLibrary[layer.fx].$1;
        final shakeX = effectName == 'Shake'
            ? '+sin(t*' + (32 * layer.fxSpeed).toStringAsFixed(2) + ')*' + (10 * layer.fxStrength).toStringAsFixed(2)
            : '';
        final shakeY = effectName == 'Shake'
            ? '+cos(t*' + (27 * layer.fxSpeed).toStringAsFixed(2) + ')*' + (7 * layer.fxStrength).toStringAsFixed(2)
            : '';
        graph.add(
          '[' + currentVideo + '][' + imageLabel + ']overlay=x=\'' + x.toString() + shakeX +
          '\':y=\'' + y.toString() + shakeY + '\':enable=\'between(t,' + start.toString() + ',' + end.toString() + ')\'[' + nextLabel + ']',
        );
        currentVideo = nextLabel;
      }

      for (final layer in textLayers) {
        final nextLabel = 'v${++outputNumber}';
        final start = (layer.start * totalDuration - trimStart).clamp(0.0, clipDuration);
        final end = (layer.end * totalDuration - trimStart).clamp(0.0, clipDuration);
        if (end <= start) continue;
        final x = (layer.pos.dx * scale).round();
        final y = (layer.pos.dy * scale).round();
        final fontSize = (layer.fontSize * scale).round().clamp(10, 260);
        final colorHex = layer.color.value.toRadixString(16).padLeft(8, '0').substring(2);
        final text = _filterText(layer.text);
        final textAlpha = layer.opacity.clamp(0.0, 1.0).toDouble();
        final textFx = fxLibrary[layer.fx].$1;
        final textXTerms = <String>[];
        final textYTerms = <String>[];
        if (textFx == 'Shake') {
          textXTerms.add('sin(t*' + (32 * layer.fxSpeed).toStringAsFixed(2) + ')*' + (10 * layer.fxStrength).toStringAsFixed(2));
          textYTerms.add('cos(t*' + (27 * layer.fxSpeed).toStringAsFixed(2) + ')*' + (7 * layer.fxStrength).toStringAsFixed(2));
        }
        for (final clip in layer.mangaEffects) {
          final clipStart = (clip.start * totalDuration - trimStart).clamp(0.0, clipDuration);
          final clipEnd = (clip.end * totalDuration - trimStart).clamp(0.0, clipDuration);
          if (clipEnd <= clipStart) continue;
          final active = 'between(t,' + clipStart.toStringAsFixed(3) + ',' + clipEnd.toStringAsFixed(3) + ')';
          final strength = _mangaClipStrengthExpression(clip, totalDuration, trimStart);
          switch (clip.name.toLowerCase()) {
            case 'shake':
            case 'drift':
            case 'twitch':
              final frequency = clip.name.toLowerCase() == 'twitch' ? 48 : 9;
              textXTerms.add('if(' + active + ',sin(t*' + frequency.toString() + ')*' + '(12*' + strength + ')' + ',0)');
              textYTerms.add('if(' + active + ',cos(t*' + frequency.toString() + ')*' + '(8*' + strength + ')' + ',0)');
              break;
            case 'pulse':
            case 'bounce':
              textYTerms.add('if(' + active + ',sin(t*11)*' + '(9*' + strength + ')' + ',0)');
              break;
            case 'impact':
              textYTerms.add('if(' + active + ',if(lt(mod(t-' + clipStart.toStringAsFixed(3) + ',0.5),0.08),-' + '(7*' + strength + ')' + ',0),0)');
              break;
          }
        }
        final textX = textXTerms.isEmpty ? x.toString() : "'" + x.toString() + '+' + textXTerms.join('+') + "'";
        final textY = textYTerms.isEmpty ? y.toString() : "'" + y.toString() + '+' + textYTerms.join('+') + "'";
        final alpha = textFx == 'Flash'
            ? ':alpha=\'if(lt(mod(t,0.5),0.08),1,' + textAlpha.toStringAsFixed(3) + ')\''
            : '';
        graph.add(
          '[' + currentVideo + ']drawtext=text=\'' + text +
          '\':fontcolor=0x' + colorHex + '@' + textAlpha.toStringAsFixed(3) +
          ':fontsize=' + fontSize.toString() + ':x=' + textX + ':y=' + textY +
          ':borderw=2:bordercolor=black@0.45' + alpha +
          ':enable=\'between(t,' + start.toString() + ',' + end.toString() + ')\'[' + nextLabel + ']',
        );
        currentVideo = nextLabel;
      }

      final audioInputStart = 1 + imageLayers.length;
      final audioLabels = <String>[];
      if (sourceHasAudio) {
        graph.add('[0:a]volume=${_vol.toStringAsFixed(3)}[baseaudio]');
        audioLabels.add('[baseaudio]');
      }
      for (int i = 0; i < _audioTracks.length; i++) {
        final track = _audioTracks[i];
        if (track.hidden) continue;
        final inputIndex = audioInputStart + i;
        final start = (track.start * totalDuration - trimStart).clamp(0.0, clipDuration);
        final end = (track.end * totalDuration - trimStart).clamp(0.0, clipDuration);
        if (end <= start) continue;
        final delay = (start * 1000).round();
        final length = (end - start).toStringAsFixed(3);
        final label = 'audio$i';
        graph.add('[$inputIndex:a]atrim=duration=$length,asetpts=PTS-STARTPTS,adelay=$delay|$delay,volume=${track.volume.toStringAsFixed(3)}[$label]');
        audioLabels.add('[$label]');
      }

      graph.add('[$currentVideo]null[vout]');
      if (audioLabels.length > 1) {
        graph.add('${audioLabels.join()}amix=inputs=${audioLabels.length}:duration=longest:dropout_transition=2[aout]');
      } else if (audioLabels.length == 1) {
        graph.add('${audioLabels.single}anull[aout]');
      }

      command.write('-t ${clipDuration.toStringAsFixed(3)} ');
      command.write('-filter_complex "${graph.join(';')}" ');
      command.write('-map "[vout]" ');
      if (audioLabels.isNotEmpty) {
        command.write('-map "[aout]" -c:a aac -b:a 192k ');
      } else {
        command.write('-an ');
      }
      command.write('-c:v h264_videotoolbox -allow_sw 1 -b:v 6M -pix_fmt yuv420p -movflags +faststart ${_ffArg(outputPath)}');

      // Try the platform hardware encoder first, then fall back to the
      // bundled software encoder. Some iOS devices/build variants do not
      // expose VideoToolbox through the packaged FFmpeg build.
      var session = await FFmpegKit.execute(command.toString());
      var returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode) || !File(outputPath).existsSync()) {
        final firstLogs = await session.getLogs();
        final firstDetails = firstLogs.map((log) => log.getMessage()).join('\n');
        try {
          final partial = File(outputPath);
          if (await partial.exists()) await partial.delete();
        } catch (_) {}
        final hardwareCommand = command.toString();
        final softwareCommand = hardwareCommand
            .replaceFirst('-c:v h264_videotoolbox -allow_sw 1 -b:v 6M',
                '-c:v libx264 -preset ultrafast -b:v 6M');
        session = await FFmpegKit.execute(softwareCommand);
        returnCode = await session.getReturnCode();
        if (!ReturnCode.isSuccess(returnCode) || !File(outputPath).existsSync()) {
          final logs = await session.getLogs();
          final details = logs.map((log) => log.getMessage()).join('\n');
          final usefulDetails = details.trim().isNotEmpty ? details : firstDetails;
          final tail = usefulDetails.split('\n').where((line) => line.trim().isNotEmpty).toList();
          throw Exception(tail.isEmpty
              ? 'FFmpeg export failed with both hardware and software encoders.'
              : tail.skip(math.max(0, tail.length - 18)).join('\n'));
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final savedExports = <Map<String, dynamic>>[];
      final oldExports = prefs.getString('editshift.exports');
      if (oldExports != null) {
        try {
          savedExports.addAll((jsonDecode(oldExports) as List)
              .map((item) => Map<String, dynamic>.from(item as Map)));
        } catch (_) {}
      }
      savedExports.insert(0, {
        'path': outputPath,
        'name': 'EditShift export ${DateTime.now().toLocal().toString().substring(0, 16)}',
        'created': DateTime.now().toIso8601String(),
      });
      await prefs.setString('editshift.exports', jsonEncode(savedExports.take(100).toList()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to your EditShift Library')),
        );
      }
      await SharePlus.instance.share(
        ShareParams(
          title: 'EditShift export',
          text: 'Exported with EditShift',
          files: [XFile(outputPath)],
        ),
      );
    } catch (error) {
      if (mounted) {
        final message = error.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${message.length > 220 ? message.substring(0, 220) : message}'),
            duration: const Duration(seconds: 7),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  Widget _layerView(int i) {
    final l = _layers[i];
    final sel = _sel == i;
    if ((l.hidden && !l.isController) || (_vc != null && (_t < l.start || _t > l.end))) {
      return const SizedBox.shrink();
    }
    final al = FractionalOffset(l.pivot.dx, l.pivot.dy);
    Widget child;
    if (l.isCamera) {
      child = Container(width: 118, height: 72, decoration: BoxDecoration(color: const Color(0x222F9BDB), border: Border.all(color: const Color(0xFF79C8FF), width: 1.6), borderRadius: BorderRadius.circular(10)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.videocam_rounded, color: Color(0xFF79C8FF), size: 27), Text('CAMERA', style: TextStyle(color: Color(0xFF79C8FF), fontSize: 10, fontWeight: FontWeight.w900))]));
    } else if (l.isNull) {
      child = Container(width: 150, height: 96, decoration: BoxDecoration(color: const Color(0x2220E36F), border: Border.all(color: const Color(0xFF20E36F), width: 1.5), borderRadius: BorderRadius.circular(12)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.control_camera_rounded, color: Color(0xFF20E36F), size: 30), SizedBox(height: 5), Text('NULL OBJECT', style: TextStyle(color: Color(0xFF20E36F), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4)), Text('Parent controller', style: TextStyle(color: Colors.white54, fontSize: 9))]));
    } else if (l.isAdjustment) {
      child = Container(width: 172, height: 58, decoration: BoxDecoration(color: const Color(0x2220E36F), border: Border.all(color: const Color(0xFF20E36F)), borderRadius: BorderRadius.circular(8)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.tune_rounded, color: Color(0xFF20E36F)), SizedBox(width: 8), Text('ADJUSTMENT LAYER', style: TextStyle(color: Color(0xFF20E36F), fontWeight: FontWeight.w900, fontSize: 10))]));
    } else if (l.isSolid || l.isShape) {
      child = Container(
        width: l.isSolid ? _stageSize.width : 144,
        height: l.isSolid ? _stageSize.height : 144,
        decoration: BoxDecoration(
          color: l.color,
          shape: l.isShape ? BoxShape.circle : BoxShape.rectangle,
          border: sel ? Border.all(color: const Color(0xFF26D977), width: 1.5) : null,
        ),
      );
    } else if (l.isMesh) {
      child = SizedBox(
        width: 120, height: 120,
        child: Stack(clipBehavior: Clip.none, children: [
          CustomPaint(size: const Size(120, 120), painter: MeshPainter(l.mesh, l.color)),
          if (sel)
            for (int k = 0; k < 9; k++)
              Positioned(
                left: l.mesh[k].dx * 120 - 10, top: l.mesh[k].dy * 120 - 10,
                child: GestureDetector(
                  onPanUpdate: (d) => setState(() => l.mesh[k] += Offset(d.delta.dx / 120, d.delta.dy / 120)),
                  child: Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white,
                        border: Border.all(color: Colors.blue, width: 2)),
                  ),
                ),
              ),
        ]),
      );
    } else if (l.isImage && l.imagePath != null) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(l.imagePath!),
          width: 190,
          height: 190,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white70, size: 56),
        ),
      );
    } else {
      child = Padding(
        padding: const EdgeInsets.all(6),
        child: Text(l.text,
            style: TextStyle(
              fontSize: l.fontSize, color: l.color,
              fontWeight: l.bold ? FontWeight.w700 : FontWeight.w400,
              fontStyle: l.italic ? FontStyle.italic : FontStyle.normal,
              shadows: l.shadow ? const [Shadow(blurRadius: 8, offset: Offset(2, 3), color: Colors.black87)] : null,
            )),
      );
    }
    l.applyEffect(_ms);
    child = applyFx(
      l.fx,
      child,
      strength: l.fxStrength,
      speed: l.fxSpeed,
      time: _ms / 1000,
    );
    final projectSeconds = math.max(.001, _videoDuration);
    for (final clip in l.mangaEffects) {
      final clipStart = clip.start * projectSeconds;
      final clipEnd = clip.end * projectSeconds;
      final currentSeconds = _ms / 1000;
      if (currentSeconds < clipStart || currentSeconds > clipEnd) continue;
      final mappedName = switch (clip.name.toLowerCase()) {
        'pulse' || 'bounce' => 'Zoom Pulse',
        'bend' || 'oscillate' || 'wobble' || 'wind' || 'liquify' => 'Wave Warp',
        'swing' => 'Spin',
        'impact' => 'Flash',
        'drift' => 'Shake',
        'twitch' => 'Glitch',
        _ => clip.name,
      };
      final clipFx = fxLibrary.indexWhere(
        (effect) => effect.$1.toLowerCase() == mappedName.toLowerCase(),
      );
      if (clipFx >= 0) {
        child = applyFx(
          clipFx,
          child,
          strength: clip.strengthAt(currentSeconds / projectSeconds),
          speed: 1,
          time: _ms / 1000,
        );
      }
    }
    if (sel && _pivotMode) {
      child = Stack(children: [
        child,
        Positioned.fill(
          child: LayoutBuilder(builder: (pivotContext, constraints) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (d) => setState(() {
              l.pivot = Offset(
                (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0).toDouble(),
                (d.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0).toDouble(),
              );
            }),
            child: Align(
              alignment: Alignment(l.pivot.dx * 2 - 1, l.pivot.dy * 2 - 1),
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(color: const Color(0xFF20E36F), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.open_with, size: 13, color: Colors.white),
              ),
            ),
          )),
        ),
      ]);
    }
    var visualPosition = l.pos;
    var visualScale = l.scale;
    var visualRotation = l.rot;
    var visualOpacity = l.opacity;
    var parentIndex = l.parentIndex;
    final visitedParents = <int>{i};
    while (parentIndex != null && parentIndex >= 0 && parentIndex < _layers.length && visitedParents.add(parentIndex)) {
      final parent = _layers[parentIndex];
      final scaled = Offset(visualPosition.dx * parent.scale, visualPosition.dy * parent.scale);
      final angle = parent.rot;
      visualPosition = parent.pos + Offset(scaled.dx * math.cos(angle) - scaled.dy * math.sin(angle), scaled.dx * math.sin(angle) + scaled.dy * math.cos(angle));
      visualScale *= parent.scale;
      visualRotation += parent.rot;
      visualOpacity *= parent.opacity;
      child = applyFx(
        parent.fx,
        child,
        strength: parent.fxStrength,
        speed: parent.fxSpeed,
        time: _ms / 1000,
      );
      parentIndex = parent.parentIndex;
    }
    return Positioned(
      left: visualPosition.dx, top: visualPosition.dy,
      child: GestureDetector(
        onTap: () => setState(() => _sel = i),
        onDoubleTap: () => setState(() { _sel = i; _pivotMode = !_pivotMode; }),
        onPanUpdate: (d) => _ed(l, () { _sel = i; l.pos += d.delta; }),
        child: Opacity(
          opacity: visualOpacity.clamp(0, 1).toDouble(),
          child: Transform(
            alignment: al,
            transform: Matrix4.identity()
              ..setEntry(1, 0, l.bend)
              ..rotateZ(visualRotation)
              ..multiply(Matrix4.diagonal3Values(
                  visualScale * (l.flipX ? -1 : 1), visualScale * (l.flipY ? -1 : 1), 1)),
            child: child,
          ),
        ),
      ),
    );
  }


  Widget _stage() {
    final vc = _vc;
    return LayoutBuilder(builder: (context, constraints) {
      _stageSize = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        onTap: () => setState(() => _sel = null),
        child: Container(
          color: _projectBackground,
          child: ClipRect(
            child: Transform.scale(scale: _previewZoom, child: Stack(fit: StackFit.expand, children: [
              if (vc != null && !_videoHidden)
                if (_previewFull)
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: vc.value.size.width,
                        height: vc.value.size.height,
                        child: applyFx(
                          _videoFx,
                          ColorFiltered(
                            colorFilter: ColorFilter.matrix(_adjustmentMatrix()),
                            child: VideoPlayer(vc),
                          ),
                          strength: _videoFxStrength,
                          speed: _videoFxSpeed,
                          time: _ms / 1000,
                        ),
                      ),
                    ),
                  )
                else
                  Center(
                    child: AspectRatio(
                      aspectRatio: vc.value.aspectRatio,
                      child: applyFx(
                        _videoFx,
                        ColorFiltered(
                          colorFilter: ColorFilter.matrix(_adjustmentMatrix()),
                          child: VideoPlayer(vc),
                        ),
                        strength: _videoFxStrength,
                        speed: _videoFxSpeed,
                        time: _ms / 1000,
                      ),
                    ),
                  )
              else if (_layers.isEmpty)
                const Center(child: Text('PREVIEW', style: TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 2.2, fontWeight: FontWeight.w700))),
              for (int i = 0; i < _layers.length; i++) _layerView(i),
              Positioned(top: 7, right: 7, child: Material(color: const Color(0xCC111820), borderRadius: BorderRadius.circular(10), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2), child: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(tooltip: 'Zoom out', visualDensity: VisualDensity.compact, constraints: const BoxConstraints.tightFor(width: 30, height: 30), padding: EdgeInsets.zero, onPressed: () => setState(() => _previewZoom = (_previewZoom - .1).clamp(.5, 2.5).toDouble()), icon: const Icon(Icons.remove, size: 16)),
                GestureDetector(onTap: () => setState(() => _previewZoom = 1), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('${(_previewZoom * 100).round()}%', style: const TextStyle(fontSize: 9, color: Colors.white70)))),
                IconButton(tooltip: 'Zoom in', visualDensity: VisualDensity.compact, constraints: const BoxConstraints.tightFor(width: 30, height: 30), padding: EdgeInsets.zero, onPressed: () => setState(() => _previewZoom = (_previewZoom + .1).clamp(.5, 2.5).toDouble()), icon: const Icon(Icons.add, size: 16)),
                Container(width: 1, height: 18, color: Colors.white24),
                IconButton(tooltip: 'Add keyframe', visualDensity: VisualDensity.compact, constraints: const BoxConstraints.tightFor(width: 30, height: 30), padding: EdgeInsets.zero, onPressed: _sel == null ? null : _addKeyframeNow, icon: const Icon(Icons.diamond_outlined, size: 16, color: Color(0xFF79C8FF))),
                IconButton(tooltip: 'Delete selected layer', visualDensity: VisualDensity.compact, constraints: const BoxConstraints.tightFor(width: 30, height: 30), padding: EdgeInsets.zero, onPressed: _sel == null ? null : _deleteSelected, icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent)),
              ])))),
              if (_showGrid)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: GridPaper(
                      color: Color(0x22FFFFFF),
                      interval: 40,
                      divisions: 2,
                      subdivisions: 2,
                    ),
                  ),
                ),
            ])),
          ),
        ),
      );
    });
  }

  void _seekFrames(int frameDelta) {
    final controller = _vc;
    if (controller == null) return;
    final frameMs = (1000 / 30).round();
    final next = (_ms + frameDelta * frameMs).clamp(0, controller.value.duration.inMilliseconds).toInt();
    _pauseAudio();
    controller.seekTo(Duration(milliseconds: next));
  }

  void _addBookmark() {
    if (_bookmarks.any((time) => (time - _ms).abs() < 90)) return;
    setState(() {
      _bookmarks.add(_ms);
      _bookmarks.sort();
    });
  }

  Widget _controls() {
    Widget control(IconData icon, String tooltip, VoidCallback? action, {Color color = Colors.white70}) =>
        IconButton(
          tooltip: tooltip,
          onPressed: action,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 36, height: 44),
          icon: Icon(icon, size: 20, color: color),
        );
    return Container(
      height: 48,
      color: const Color(0xFF08090B),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        control(Icons.grid_view_rounded, 'Toggle grid', () => setState(() => _showGrid = !_showGrid), color: _showGrid ? const Color(0xFF20E36F) : Colors.white70),
        TextButton(
          onPressed: () => setState(() => _previewFull = !_previewFull),
          style: TextButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 7), minimumSize: const Size(42, 36)),
          child: Text(_previewFull ? 'Fit' : 'Full', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        control(Icons.bookmark_border_rounded, 'Add bookmark', _addBookmark),
        const Spacer(),
        control(Icons.skip_previous_rounded, 'Previous frame', _vc == null ? null : () => _seekFrames(-1)),
        control(_vc?.value.isPlaying == true ? Icons.pause_rounded : Icons.play_arrow_rounded, 'Play or pause', _vc == null ? null : _togglePlayback, color: const Color(0xFF20E36F)),
        control(Icons.skip_next_rounded, 'Next frame', _vc == null ? null : () => _seekFrames(1)),
        const Spacer(),
        control(Icons.layers_rounded, 'Layer properties', _openInspectorSheet),
        control(Icons.undo_rounded, 'Undo', _undoStack.isEmpty ? null : _undo),
        control(Icons.redo_rounded, 'Redo', _redoStack.isEmpty ? null : _redo),
      ]),
    );
  }

  Widget _timelineTrack({
    required String title,
    required IconData icon,
    required Color accent,
    required RangeValues values,
    required double max,
    required ValueChanged<RangeValues> onChanged,
    bool selected = false,
    bool visible = true,
    VoidCallback? onVisibilityToggle,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onMore,
    List<int> keyframeTimes = const [],
    ValueChanged<int>? onKeyframeTap,
    void Function(int oldTime, int newTime)? onKeyframeMove,
  }) {
    final safeMax = max <= 0 ? 1.0 : max;
    final low = values.start.clamp(0.0, safeMax).toDouble();
    final high = values.end.clamp(low, safeMax).toDouble();
    return Container(
      height: 43,
      color: selected ? const Color(0xFF171D1B) : const Color(0xFF08090B),
      child: Row(children: [
        SizedBox(
          width: 42,
          child: IconButton(
            tooltip: visible ? 'Hide layer' : 'Show layer',
            visualDensity: VisualDensity.compact,
            onPressed: onVisibilityToggle,
            icon: Icon(
              visible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              size: 18,
              color: visible ? Colors.white70 : Colors.white24,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            final width = box.maxWidth;
            final left = (low / safeMax * width).clamp(0.0, width).toDouble();
            final right = (high / safeMax * width).clamp(left, width).toDouble();
            final clipWidth = math.max(18.0, right - left).toDouble();
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              onLongPress: onLongPress,
              onHorizontalDragUpdate: (d) {
                final target = ((d.localPosition.dx / width).clamp(0.0, 1.0) * safeMax);
                final span = high - low;
                final nextStart = (target - span / 2).clamp(0.0, safeMax - span).toDouble();
                onChanged(RangeValues(nextStart, nextStart + span));
              },
              child: Stack(clipBehavior: Clip.hardEdge, children: [
                Positioned.fill(child: Center(child: Container(height: 1, color: Colors.white12))),
                Positioned(
                  left: (_t.clamp(0.0, 1.0) * width).clamp(0.0, width - 1).toDouble(),
                  top: 0, bottom: 0, width: 1,
                  child: Container(color: const Color(0xFF20E36F)),
                ),
                Positioned(
                  left: left, top: 5, width: clipWidth, height: 33,
                  child: GestureDetector(
                    onTap: onTap,
                    onPanUpdate: (d) {
                      final delta = d.delta.dx / width * safeMax;
                      final span = high - low;
                      final nextStart = (low + delta).clamp(0.0, safeMax - span).toDouble();
                      onChanged(RangeValues(nextStart, nextStart + span));
                    },
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(visible ? .84 : .24),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: selected ? const Color(0xFFD5EDFF) : accent.withOpacity(.8),
                          width: selected ? 1.4 : .7,
                        ),
                      ),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                for (final keyTime in keyframeTimes)
                  Positioned(
                    left: ((keyTime / 1000 / _videoDuration.clamp(.001, double.infinity)) * width - 5)
                        .clamp(0.0, width - 10).toDouble(),
                    top: 16, width: 10, height: 10,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onKeyframeTap == null ? null : () => onKeyframeTap(keyTime),
                      onHorizontalDragStart: onKeyframeMove == null ? null : (_) => _pushUndo(),
                      onHorizontalDragUpdate: onKeyframeMove == null
                          ? null
                          : (d) => onKeyframeMove(
                                keyTime,
                                (keyTime + d.delta.dx / width * _videoDuration * 1000).round(),
                              ),
                      child: Transform.rotate(
                        angle: math.pi / 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFFFE66D) : Colors.white,
                            border: Border.all(color: const Color(0xFF101215), width: 1.1),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: (left - 3).clamp(0.0, width - 7).toDouble(),
                  top: 3, width: 8, height: 37,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanUpdate: (d) {
                      final delta = d.delta.dx / width * safeMax;
                      onChanged(RangeValues((low + delta).clamp(0.0, high - .01).toDouble(), high));
                    },
                    child: Center(child: Container(width: 3, height: 22, color: Colors.white)),
                  ),
                ),
                Positioned(
                  left: (right - 4).clamp(0.0, width - 7).toDouble(),
                  top: 3, width: 8, height: 37,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanUpdate: (d) {
                      final delta = d.delta.dx / width * safeMax;
                      onChanged(RangeValues(low, (high + delta).clamp(low + .01, safeMax).toDouble()));
                    },
                    child: Center(child: Container(width: 3, height: 22, color: Colors.white)),
                  ),
                ),
              ]),
            );
          }),
        ),
        SizedBox(
          width: 36,
          child: IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Layer options',
            onPressed: onMore,
            icon: const Icon(Icons.drag_handle_rounded, size: 20, color: Colors.white60),
          ),
        ),
      ]),
    );
  }

  Widget _timeline() {
    final duration = _videoDuration;
    final selected = _sel != null && _sel! < _layers.length ? _sel! : null;
    final rulerPainter = _TimelineRulerPainter(
      duration: duration,
      currentSeconds: _ms / 1000,
      bookmarks: _bookmarks,
    );
    return Container(
      color: const Color(0xFF050607),
      child: Column(children: [
        SizedBox(
          height: 34,
          child: Row(children: [
            IconButton(
              tooltip: 'Zoom timeline out',
              visualDensity: VisualDensity.compact,
              onPressed: _timelineZoom <= 1
                  ? null
                  : () => setState(() => _timelineZoom = (_timelineZoom / 1.25).clamp(1.0, 8.0).toDouble()),
              icon: const Icon(Icons.remove, size: 17, color: Colors.white70),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                ),
                child: Slider(
                  min: 1,
                  max: 8,
                  divisions: 28,
                  value: _timelineZoom.clamp(1.0, 8.0).toDouble(),
                  onChanged: (value) => setState(() => _timelineZoom = value),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Zoom timeline in',
              visualDensity: VisualDensity.compact,
              onPressed: _timelineZoom >= 8
                  ? null
                  : () => setState(() => _timelineZoom = (_timelineZoom * 1.25).clamp(1.0, 8.0).toDouble()),
              icon: const Icon(Icons.add, size: 17, color: Colors.white70),
            ),
            TextButton(
              onPressed: () => setState(() => _timelineZoom = 1),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF79C8FF),
                padding: const EdgeInsets.symmetric(horizontal: 7),
                minimumSize: const Size(38, 30),
              ),
              child: const Text('FIT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
            ),
            SizedBox(
              width: 38,
              child: Text(
                '${_timelineZoom.toStringAsFixed(1)}x',
                style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, viewport) {
            final contentWidth = viewport.maxWidth * _timelineZoom;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: contentWidth,
                child: Column(children: [
                          SizedBox(
          height: 31,
          child: LayoutBuilder(builder: (context, box) {
            final markerLeft = (_t * box.maxWidth - 38).clamp(0.0, math.max(0.0, box.maxWidth - 76)).toDouble();
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _scrubTimeline(d.localPosition.dx, box.maxWidth),
              onHorizontalDragStart: (d) {
                final targetMs = (d.localPosition.dx / box.maxWidth * duration * 1000).round();
                int? nearest;
                var nearestDistance = double.infinity;
                for (final marker in _bookmarks) {
                  final distance = (marker - targetMs).abs().toDouble();
                  if (distance < nearestDistance) {
                    nearestDistance = distance;
                    nearest = marker;
                  }
                }
                final threshold = (duration * 1000 / box.maxWidth * 22).round();
                _draggingBookmarkTime = nearest != null && nearestDistance <= threshold ? nearest : null;
              },
              onHorizontalDragUpdate: (d) {
                final marker = _draggingBookmarkTime;
                if (marker == null) {
                  _scrubTimeline(d.localPosition.dx, box.maxWidth);
                  return;
                }
                final next = (d.localPosition.dx / box.maxWidth * duration * 1000)
                    .round().clamp(0, (duration * 1000).round()).toInt();
                setState(() {
                  final index = _bookmarks.indexOf(marker);
                  if (index >= 0) _bookmarks[index] = next;
                  _bookmarks.sort();
                  _draggingBookmarkTime = next;
                });
              },
              onHorizontalDragEnd: (_) => _draggingBookmarkTime = null,
              child: Stack(children: [
                Positioned.fill(child: CustomPaint(painter: rulerPainter)),
                Positioned(
                  left: markerLeft, top: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF20E36F), borderRadius: BorderRadius.circular(12)),
                    child: Text(_fmt(Duration(milliseconds: _ms)), style: const TextStyle(color: Color(0xFF04140A), fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                ),
              ]),
            );
          }),
        ),
                          Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              if (_vc != null)
                _timelineTrack(
                  title: 'Video 1',
                  icon: Icons.movie_rounded,
                  accent: const Color(0xFF65B8F4),
                  values: RangeValues(
                    (_trimStart / duration).clamp(0.0, 1.0).toDouble(),
                    (_trimEnd / duration).clamp(0.0, 1.0).toDouble(),
                  ),
                  max: 1,
                  visible: !_videoHidden,
                  onVisibilityToggle: () => setState(() => _videoHidden = !_videoHidden),
                  onMore: _showVideoOptions,
                  onChanged: (range) {
                    setState(() {
                      _trimStart = range.start * duration;
                      _trimEnd = range.end * duration;
                    });
                    if (_vc!.value.position < _time(_trimStart) || _vc!.value.position > _time(_trimEnd)) {
                      _vc!.seekTo(_time(_trimStart));
                    }
                  },
                ),
              for (int i = _layers.length - 1; i >= 0; i--)
                ...[
                _timelineTrack(
                  title: _layers[i].text,
                  icon: _layers[i].isCamera
                      ? Icons.videocam_rounded
                      : _layers[i].isNull
                          ? Icons.control_camera_rounded
                          : _layers[i].isAdjustment
                          ? Icons.tune_rounded
                          : _layers[i].isSolid
                              ? Icons.square_rounded
                              : _layers[i].isShape
                                  ? Icons.category_rounded
                                  : _layers[i].isMesh
                                      ? Icons.grid_4x4_rounded
                                      : _layers[i].isImage
                                          ? Icons.image_rounded
                                          : Icons.title_rounded,
                  accent: _layers[i].isCamera
                      ? const Color(0xFF79C8FF)
                      : _layers[i].isNull
                          ? const Color(0xFF26D977)
                          : _layers[i].isAdjustment
                          ? const Color(0xFFFFB74D)
                          : _layers[i].isSolid
                              ? const Color(0xFF36A8FF)
                              : _layers[i].isShape
                                  ? const Color(0xFFB78BFF)
                                  : _layers[i].isImage
                                      ? const Color(0xFF24B6B0)
                                      : const Color(0xFF278B58),
                  values: RangeValues(_layers[i].start, _layers[i].end),
                  max: 1,
                  selected: selected == i || _multiSelection.contains(i),
                  visible: !_layers[i].hidden,
                  onVisibilityToggle: () => setState(() => _layers[i].hidden = !_layers[i].hidden),
                  keyframeTimes: _layers[i].kfs.map((keyframe) => keyframe.t).toList(),
                  onKeyframeTap: (time) {
                    _vc?.seekTo(Duration(milliseconds: time));
                    setState(() => _sel = i);
                  },
                  onKeyframeMove: (oldTime, newTime) => _moveLayerKeyframe(i, oldTime, newTime),
                  onTap: () {
                    if (_multiSelectMode) {
                      _toggleMultiSelect(i);
                    } else {
                      setState(() => _sel = i);
                      if (MediaQuery.of(context).size.width < 760) {
                        _tab = tabs.indexWhere((tab) => tab.$1 == 'Transform');
                        _openInspectorSheet();
                      }
                    }
                  },
                  onLongPress: () => _toggleMultiSelect(i),
                  onMore: () => _showLayerActions(i),
                  onChanged: (range) => _ed(_layers[i], () {
                    _layers[i].start = range.start;
                    _layers[i].end = range.end;
                  }),
                ),
                if (_layers[i].fx != 0 || _layers[i].effectKfs.isNotEmpty)
                  _timelineTrack(
                    title: '   ↳ Effect · ${fxLibrary[_layers[i].fx].$1}',
                    icon: Icons.auto_awesome_rounded,
                    accent: const Color(0xFFB78BFF),
                    values: RangeValues(_layers[i].start, _layers[i].end),
                    max: 1,
                    selected: selected == i,
                    visible: !_layers[i].hidden,
                    keyframeTimes: _layers[i].effectKfs.map((key) => key.t).toList(),
                    onTap: () { setState(() => _sel = i); _tab = tabs.indexWhere((tab) => tab.$1 == 'Effects'); _openInspectorSheet(); },
                    onKeyframeTap: (time) { _vc?.seekTo(Duration(milliseconds: time)); setState(() => _sel = i); _tab = tabs.indexWhere((tab) => tab.$1 == 'Effects'); _openInspectorSheet(); },
                    onKeyframeMove: (oldTime, newTime) => _moveEffectKeyframe(i, oldTime, newTime),
                    onChanged: (_) {},
                  ),
                ],
              for (int i = 0; i < _audioTracks.length; i++)
                _timelineTrack(
                  title: _audioTracks[i].title,
                  icon: Icons.graphic_eq_rounded,
                  accent: const Color(0xFF20DCA0),
                  values: RangeValues(_audioTracks[i].start, _audioTracks[i].end),
                  max: 1,
                  visible: !_audioTracks[i].hidden,
                  onVisibilityToggle: () => setState(() => _audioTracks[i].hidden = !_audioTracks[i].hidden),
                  onTap: () => setState(() => _tab = tabs.indexWhere((tab) => tab.$1 == 'Audio')),
                  onMore: () => _showAudioOptions(_audioTracks[i]),
                  onChanged: (range) => setState(() {
                    _audioTracks[i].start = range.start;
                    _audioTracks[i].end = range.end;
                  }),
                ),
              if (_vc == null && _layers.isEmpty && _audioTracks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: Text('Import media or add a layer to begin', style: TextStyle(color: Colors.white38, fontSize: 11))),
                ),
            ],
          ),
        ),
                ]),
              ),
            );
          }),
        ),
      ]),
    );
  }

  void _scrubTimeline(double dx, double width) {
    if (width <= 0) return;
    final targetMs = (dx / width * _videoDuration * 1000).round();
    final target = Duration(milliseconds: targetMs.clamp(0, (_videoDuration * 1000).round()).toInt());
    _pauseAudio();
    _lastAudioSyncBucket = -1;
    _vc?.seekTo(target);
    for (final layer in _layers) {
      layer.apply(target.inMilliseconds);
    }
    if (mounted) setState(() {});
  }

  Widget _tabBar() => SizedBox(
        height: 62,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          itemBuilder: (_, i) => InkWell(
            onTap: () {
              setState(() => _tab = i);
              _inspectorSheetSetState?.call(() {});
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 74,
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                      color: _tab == i ? const Color(0xFF20E36F) : Colors.transparent, width: 3))),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(tabs[i].$2, color: _tab == i ? const Color(0xFF20E36F) : Colors.white54),
                Text(tabs[i].$1, style: const TextStyle(fontSize: 11)),
              ]),
            ),
          ),
        ),
      );

  Widget _note(String t) => Padding(padding: const EdgeInsets.all(12), child: Text(t));

  Widget _curvePreset(String label, Offset first, Offset second, Layer layer) =>
      OutlinedButton(
        onPressed: () => _ed(layer, () {
          layer.curveHandle1 = first;
          layer.curveHandle2 = second;
          layer.curveCyclic = false;
        }),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          visualDensity: VisualDensity.compact,
          side: BorderSide(color: Colors.white.withOpacity(.16)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 10)),
      );

  List<Widget> _body(Layer? l) {
    final name = tabs[_tab].$1;

    if (name == 'Adjust') {
      return [
        const Text('COLOR & LIGHT', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w900, color: Color(0xFF20E36F))),
        const SizedBox(height: 8),
        _globalS('Brightness', _brightness, -1, 1, (v) => setState(() => _brightness = v)),
        _globalS('Contrast', _contrast, 0, 2, (v) => setState(() => _contrast = v)),
        _globalS('Saturation', _saturation, 0, 2, (v) => setState(() => _saturation = v)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => setState(() {
              _brightness = 0;
              _contrast = 1;
              _saturation = 1;
            }),
            icon: const Icon(Icons.restart_alt_rounded, size: 16),
            label: const Text('Reset adjustments'),
          ),
        ),
        const Text('Adjustments are applied to the video preview and exported render.',
            style: TextStyle(fontSize: 10, color: Colors.white38)),
      ];
    }

    if (name == 'Effects') {
      final current = l?.fx ?? _videoFx;
      final currentName = fxLibrary[current].$1;
      return [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF202735),
          ),
          child: Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF20E36F), size: 22),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('EFFECT STUDIO', style: TextStyle(fontSize: 9, letterSpacing: 1.6, color: Colors.white70, fontWeight: FontWeight.w800)),
              Text(currentName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            ])),
            const Icon(Icons.graphic_eq_rounded, color: Colors.white70),
          ]),
        ),
        const SizedBox(height: 12),
        const Text('BROWSE EFFECTS', style: TextStyle(fontSize: 9, letterSpacing: 1.1, color: Colors.white38, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [for (final category in ['All', 'Motion', 'Distortion', 'Generators', 'Contour', 'Dynamics', 'Color', 'Light']) ChoiceChip(label: Text(category), selected: _fxCategory == category, onSelected: (_) => setState(() => _fxCategory = category))]),
        const SizedBox(height: 8),
        TextField(onChanged: (value) => setState(() => _fxSearch = value.toLowerCase()), decoration: const InputDecoration(isDense: true, prefixIcon: Icon(Icons.search_rounded), hintText: 'Search effects', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        Wrap(spacing: 9, runSpacing: 9, children: [
          for (int i = 0; i < fxLibrary.length; i++)
            if (_effectMatches(i))
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                if (l == null) {
                  setState(() => _videoFx = i);
                } else {
                  _ed(l, () => l.fx = i);
                }
                _inspectorSheetSetState?.call(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 108,
                height: 112,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: current == i ? const Color(0xFF354052) : const Color(0xFF202735),
                  border: Border.all(
                    color: current == i ? const Color(0xFF20E36F) : Colors.white.withOpacity(.06),
                    width: current == i ? 1.5 : 1,
                  ),
                  boxShadow: current == i
                      ? [BoxShadow(color: const Color(0xFF20E36F).withOpacity(.22), blurRadius: 14)]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: _EffectThumbnail(effectIndex: i),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      fxLibrary[i].$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        const Text('EFFECT SETTINGS', style: TextStyle(fontSize: 9, letterSpacing: 1.3, color: Colors.white38, fontWeight: FontWeight.w800)),
        if (l == null) ...[
          _globalS('Intensity', _videoFxStrength, 0, 2, (v) => setState(() => _videoFxStrength = v)),
          _globalS('Speed', _videoFxSpeed, .2, 3, (v) => setState(() => _videoFxSpeed = v), suffix: '×'),
        ] else ...[
          Row(children: [
            const Expanded(child: Text('EFFECT KEYFRAMES', style: TextStyle(fontSize: 9, letterSpacing: 1.1, color: Colors.white54, fontWeight: FontWeight.w800))),
            TextButton.icon(onPressed: () => _addEffectKeyframe(l), icon: const Icon(Icons.diamond_outlined, size: 15), label: const Text('Add at playhead')),
            IconButton(tooltip: 'Remove effect keyframe at playhead', onPressed: () => _removeEffectKeyframe(l), icon: const Icon(Icons.remove_circle_outline, size: 18)),
          ]),
          Text('${l.effectKfs.length} effect keyframe${l.effectKfs.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 10, color: Colors.white38)),
          _s(l, currentName == 'Wave Warp' ? 'Wave Height' : 'Intensity',
              l.fxStrength, 0, 2, (v) => l.fxStrength = v),
          _s(l, currentName == 'Wave Warp' ? 'Wave Speed' : 'Speed',
              l.fxSpeed, .2, 3, (v) => l.fxSpeed = v),
          if (currentName == 'Bend')
            _s(l, 'Bend', l.bend, -0.8, 0.8, (v) => l.bend = v),
          if (currentName == 'Wave Warp')
            _note('Wave Warp displaces horizontal image bands over time. Height controls the wave amplitude; Speed controls its motion.'),
        ],
      ];
    }

    if (name == 'Audio') {
      return [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF202735),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('MAIN CLIP VOLUME', style: TextStyle(fontSize: 9, letterSpacing: 1.4, color: Colors.white60, fontWeight: FontWeight.w800)),
            Row(children: [
              Icon(_vol == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: const Color(0xFF62C9FF)),
              Expanded(child: Slider(value: _vol, onChanged: (v) {
                setState(() => _vol = v);
                _vc?.setVolume(v);
              })),
              Text('${(_vol * 100).round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        const Text('QUICK SOUND EFFECTS', style: TextStyle(fontSize: 9, letterSpacing: 1.2, color: Colors.white38, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(spacing: 7, runSpacing: 7, children: [
          ActionChip(
            avatar: const Icon(Icons.bubble_chart_rounded, size: 15),
            label: const Text('Pop'),
            onPressed: () => _addSoundEffect('Pop'),
          ),
          ActionChip(
            avatar: const Icon(Icons.air_rounded, size: 15),
            label: const Text('Whoosh'),
            onPressed: () => _addSoundEffect('Whoosh'),
          ),
          ActionChip(
            avatar: const Icon(Icons.touch_app_rounded, size: 15),
            label: const Text('Click'),
            onPressed: () => _addSoundEffect('Click'),
          ),
          ActionChip(
            avatar: const Icon(Icons.trending_up_rounded, size: 15),
            label: const Text('Riser'),
            onPressed: () => _addSoundEffect('Riser'),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Expanded(child: Text('AUDIO LIBRARY', style: TextStyle(fontSize: 9, letterSpacing: 1.2, color: Colors.white38, fontWeight: FontWeight.w800))),
          FilledButton.icon(
            onPressed: _addAudio,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add audio'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7E9D),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ]),
        if (_audioTracks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('Add music, ambience or sound effects to build an audio track.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 11))),
          ),
        for (final track in _audioTracks)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: const Color(0xFF1A2032),
              border: Border.all(color: const Color(0xFF62C9FF).withOpacity(.22)),
            ),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.graphic_eq_rounded, color: Color(0xFF62C9FF), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _deleteAudio(track),
                  icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 18),
                ),
              ]),
              Row(children: [
                const Text('Track volume', style: TextStyle(fontSize: 10, color: Colors.white60)),
                Expanded(child: Slider(value: track.volume, onChanged: (v) {
                  setState(() => track.volume = v);
                  track.player.setVolume(v);
                })),
                Text('${(track.volume * 100).round()}%', style: const TextStyle(fontSize: 10)),
              ]),
            ]),
          ),
        const SizedBox(height: 8),
        const Text('Audio clips appear on their own timeline track. Their start and end points can be trimmed there.',
            style: TextStyle(color: Colors.white38, fontSize: 10)),
      ];
    }

    if (l == null) {
      return [_note('Select a layer in the timeline to edit its position, timing, captions or opacity.')];
    }

    switch (name) {
      case 'Transform':
        return [
          Row(children: [
            Expanded(child: TextFormField(
              key: ValueKey('transform-x-${l.pos.dx.toStringAsFixed(2)}'),
              initialValue: l.pos.dx.toStringAsFixed(1),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'X', isDense: true, border: OutlineInputBorder()),
              onFieldSubmitted: (value) {
                final parsed = double.tryParse(value);
                if (parsed != null) _ed(l, () => l.pos = Offset(parsed, l.pos.dy));
              },
            )),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(
              key: ValueKey('transform-y-${l.pos.dy.toStringAsFixed(2)}'),
              initialValue: l.pos.dy.toStringAsFixed(1),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Y', isDense: true, border: OutlineInputBorder()),
              onFieldSubmitted: (value) {
                final parsed = double.tryParse(value);
                if (parsed != null) _ed(l, () => l.pos = Offset(l.pos.dx, parsed));
              },
            )),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(
              key: ValueKey('transform-z-${l.rot.toStringAsFixed(3)}'),
              initialValue: (l.rot * 180 / math.pi).toStringAsFixed(1),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Z°', isDense: true, border: OutlineInputBorder()),
              onFieldSubmitted: (value) {
                final parsed = double.tryParse(value);
                if (parsed != null) _ed(l, () => l.rot = parsed * math.pi / 180);
              },
            )),
          ]),
          const SizedBox(height: 12),
          _s(l, 'Position X', l.pos.dx, 0, 600, (v) => l.pos = Offset(v, l.pos.dy)),
          _s(l, 'Position Y', l.pos.dy, 0, 400, (v) => l.pos = Offset(l.pos.dx, v)),
          _s(l, 'Scale', l.scale, .1, 4, (v) => l.scale = v),
          _s(l, 'Rotate', l.rot * 180 / math.pi, -180, 180, (v) => l.rot = v * math.pi / 180),
          _s(l, 'Skew', l.bend, -.8, .8, (v) => l.bend = v),
          _s(l, 'Pivot X', l.pivot.dx, 0, 1, (v) => l.pivot = Offset(v, l.pivot.dy)),
          _s(l, 'Pivot Y', l.pivot.dy, 0, 1, (v) => l.pivot = Offset(l.pivot.dx, v)),
          if (l.isCamera) ...[
            _note('Layers parented to this camera inherit its position, rotation and zoom.'),
            _s(l, 'Camera zoom', l.scale, .2, 4, (v) => l.scale = v),
            _s(l, 'Camera rotation', l.rot, -math.pi, math.pi, (v) => l.rot = v),
          ],
          if (l.isController) _note('Parent other layers to this controller with the Parent button.'),
          if (!l.isController && _layers.any((candidate) => candidate.isController))
            DropdownButtonFormField<int?>(
              value: l.parentIndex,
              decoration: const InputDecoration(labelText: 'Parent layer', border: OutlineInputBorder()),
              items: [const DropdownMenuItem<int?>(value: null, child: Text('No parent')), for (int i = 0; i < _layers.length; i++) if (_layers[i].isController && i != _sel && !_wouldCreateParentCycle(_sel!, i)) DropdownMenuItem<int?>(value: i, child: Text(_layers[i].text))],
              onChanged: (value) => _ed(l, () => l.parentIndex = value),
            ),
          Wrap(spacing: 8, children: [
            FilterChip(label: const Text('Flip horizontal'), selected: l.flipX,
                onSelected: (v) => _ed(l, () => l.flipX = v)),
            FilterChip(label: const Text('Flip vertical'), selected: l.flipY,
                onSelected: (v) => _ed(l, () => l.flipY = v)),
          ]),
        ];
      case 'Color':
        return [
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final color in [Colors.white, Colors.black, Colors.red, Colors.orange, Colors.yellow,
              Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.pink])
              GestureDetector(
                onTap: () => _ed(l, () => l.color = color),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: l.color == color ? Colors.white : Colors.black26, width: l.color == color ? 3 : 1),
                  ),
                ),
              ),
          ]),
          if (l.isMesh) _note('On a mesh layer this sets the center color.'),
          if (l.isImage) _note('Use Adjust to change the overall video look, or Effects to style this photo.'),
        ];
      case 'Mesh':
        if (!l.isMesh) return [_note('Select a mesh layer. Add one with the Mesh button.')];
        return [
          _note('Drag the white points on the preview to warp the mesh.'),
          Wrap(spacing: 8, children: [
            ActionChip(label: const Text('Reset'), onPressed: () => _ed(l, () => l.mesh = defaultMesh())),
            ActionChip(
              label: const Text('Wave'),
              onPressed: () => _ed(l, () => l.mesh = [
                for (int r = 0; r < 3; r++)
                  for (int col = 0; col < 3; col++)
                    Offset(col / 2, r / 2 + (col == 1 ? (r == 0 ? .1 : -.1) : 0))
              ]),
            ),
            ActionChip(
              label: const Text('Pinch'),
              onPressed: () => _ed(l, () => l.mesh = [
                for (final point in l.mesh)
                  Offset(.5 + (point.dx - .5) * .7, .5 + (point.dy - .5) * .7)
              ]),
            ),
          ]),
        ];
      case 'Text':
        if (l.isMesh || l.isImage) return [_note('Select a caption layer to edit its text.')];
        return [
          TextFormField(
            key: ValueKey(l),
            initialValue: l.text,
            decoration: const InputDecoration(labelText: 'Caption text'),
            onChanged: (v) => _ed(l, () => l.text = v),
          ),
          _s(l, 'Font size', l.fontSize, 12, 120, (v) => l.fontSize = v),
          Wrap(spacing: 8, children: [
            FilterChip(label: const Text('Bold'), selected: l.bold,
                onSelected: (v) => _ed(l, () => l.bold = v)),
            FilterChip(label: const Text('Italic'), selected: l.italic,
                onSelected: (v) => _ed(l, () => l.italic = v)),
          ]),
        ];
      case 'Opacity':
        return [
          _s(l, 'Opacity', l.opacity, 0, 1, (v) => l.opacity = v),
          if (!l.isImage && !l.isMesh)
            SwitchListTile(
              title: const Text('Text shadow'),
              value: l.shadow,
              onChanged: (v) => _ed(l, () => l.shadow = v),
            ),
        ];
      case 'Keyframes':
        return [
          _note('Add keyframes at different moments to animate position, scale, rotation and opacity.'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
              icon: const Icon(Icons.diamond),
              label: const Text('Add keyframe here'),
              onPressed: () => _ed(l, () => l.upsert(_ms)),
            ),
            OutlinedButton.icon(onPressed: _removeKeyframeAtPlayhead, icon: const Icon(Icons.remove_circle_outline, size: 16), label: const Text('Remove at playhead')),
            OutlinedButton(
              onPressed: () => _ed(l, () => l.kfs.clear()),
              child: const Text('Clear all'),
            ),
          ]),
          const SizedBox(height: 8),
          const SizedBox(height: 14),
          Row(children: [
            const Text('CURVE EDITOR', style: TextStyle(fontSize: 10, color: Color(0xFF79C8FF), fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const Spacer(),
            const Text('Drag the handles', style: TextStyle(fontSize: 9, color: Colors.white54)),
          ]),
          const SizedBox(height: 8),
          _BezierCurveEditor(
            first: l.curveHandle1,
            second: l.curveHandle2,
            cyclic: l.curveCyclic,
            onChanged: (first, second) => _ed(l, () {
              l.curveHandle1 = first;
              l.curveHandle2 = second;
            }),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 5, runSpacing: 5, children: [
            _curvePreset('Linear', const Offset(0, 0), const Offset(1, 1), l),
            _curvePreset('Ease', const Offset(.42, 0), const Offset(.58, 1), l),
            _curvePreset('Ease in', const Offset(.42, 0), const Offset(1, 1), l),
            _curvePreset('Ease out', const Offset(0, 0), const Offset(.58, 1), l),
            _curvePreset('Back', const Offset(.34, -.18), const Offset(.72, 1.18), l),
            _curvePreset('Bounce', const Offset(.2, 1.2), const Offset(.8, .8), l),
          ActionChip(label: const Text('Cyclic'), avatar: const Icon(Icons.waves_rounded, size: 14), onPressed: () => _ed(l, () => l.curveCyclic = true)),
          ]),
          Wrap(spacing: 6, children: [
            for (final keyframe in l.kfs)
              ActionChip(
                avatar: const Icon(Icons.diamond, size: 14),
                label: Text(_fmt(Duration(milliseconds: keyframe.t))),
                onPressed: () => _vc?.seekTo(Duration(milliseconds: keyframe.t)),
              ),
          ]),
        ];
      case 'Timing':
        return [
          const Text('Clip visibility on the timeline'),
          RangeSlider(
            values: RangeValues(l.start, l.end),
            min: 0,
            max: 1,
            onChanged: (range) => _ed(l, () {
              l.start = range.start;
              l.end = range.end;
            }),
          ),
          Text('${(l.start * 100).round()}% — ${(l.end * 100).round()}%',
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ];
      default:
        final index = _sel!;
        return [
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Duplicate'),
              onPressed: () => _add(l.copy()),
            ),
            OutlinedButton.icon(
              icon: Icon(l.hidden ? Icons.visibility_off : Icons.visibility),
              label: Text(l.hidden ? 'Show' : 'Hide'),
              onPressed: () => _ed(l, () => l.hidden = !l.hidden),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.arrow_upward),
              label: const Text('Forward'),
              onPressed: index == _layers.length - 1 ? null : () {
                _pushUndo();
                setState(() {
                  _layers.insert(index + 1, _layers.removeAt(index));
                  _sel = index + 1;
                });
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.arrow_downward),
              label: const Text('Back'),
              onPressed: index == 0 ? null : () {
                _pushUndo();
                setState(() {
                  _layers.insert(index - 1, _layers.removeAt(index));
                  _sel = index - 1;
                });
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete layer'),
              onPressed: _deleteSelected,
            ),
          ]),
        ];
    }
  }


  void _moveLayerKeyframe(int layerIndex, int oldTime, int newTime) {
    if (layerIndex < 0 || layerIndex >= _layers.length) return;
    final layer = _layers[layerIndex];
    final keyIndex = layer.kfs.indexWhere((key) => (key.t - oldTime).abs() < 36);
    if (keyIndex < 0) return;
    final limit = ((_vc?.value.duration.inMilliseconds ?? (_videoDuration * 1000).round())).toInt();
    setState(() {
      layer.kfs[keyIndex].t = newTime.clamp(0, math.max(1, limit)).toInt();
      layer.kfs.sort((a, b) => a.t.compareTo(b.t));
    });
  }

  void _moveEffectKeyframe(int layerIndex, int oldTime, int newTime) {
    if (layerIndex < 0 || layerIndex >= _layers.length) return;
    final keys = _layers[layerIndex].effectKfs;
    final index = keys.indexWhere((key) => (key.t - oldTime).abs() < 36);
    if (index < 0) return;
    final limit = (_vc?.value.duration.inMilliseconds ?? (_videoDuration * 1000).round()).toInt();
    setState(() {
      keys[index].t = newTime.clamp(0, math.max(1, limit)).toInt();
      keys.sort((a, b) => a.t.compareTo(b.t));
    });
  }

  Future<void> _openProjectSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF111214),
      builder: (sheetContext) => StatefulBuilder(builder: (context, sheetSetState) {
        void update(VoidCallback action) {
          setState(action);
          sheetSetState(() {});
          _saveProject();
        }
        final ratios = <String, List<int>>{
          '16:9': [1920, 1080], '9:16': [1080, 1920], '1:1': [1080, 1080],
          '4:5': [1080, 1350], '4:3': [1440, 1080], 'Custom': [_projectWidth, _projectHeight],
        };
        return Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(sheetContext).viewInsets.bottom + 22),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Expanded(child: Text('PROJECT SETTINGS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2))), IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close))]),
            const SizedBox(height: 12),
            const Text('ASPECT RATIO', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(spacing: 7, runSpacing: 7, children: [for (final ratio in ratios.keys) ChoiceChip(label: Text(ratio), selected: _projectAspect == ratio, onSelected: (_) => update(() { _projectAspect = ratio; if (ratio != 'Custom') { _projectWidth = ratios[ratio]![0]; _projectHeight = ratios[ratio]![1]; } }))]),
            const SizedBox(height: 14),
            Row(children: [Expanded(child: TextFormField(initialValue: '$_projectWidth', keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Width', border: OutlineInputBorder()), onFieldSubmitted: (v) { final n = int.tryParse(v); if (n != null && n > 0) update(() { _projectWidth = n.clamp(16, 8192).toInt(); _projectAspect = 'Custom'; }); })), const SizedBox(width: 10), Expanded(child: TextFormField(initialValue: '$_projectHeight', keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Height', border: OutlineInputBorder()), onFieldSubmitted: (v) { final n = int.tryParse(v); if (n != null && n > 0) update(() { _projectHeight = n.clamp(16, 8192).toInt(); _projectAspect = 'Custom'; }); }))]),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(value: _projectFps, decoration: const InputDecoration(labelText: 'Frame rate', border: OutlineInputBorder()), items: [24, 25, 30, 48, 50, 60].whereType<int>().map((fps) => DropdownMenuItem(value: fps, child: Text('$fps FPS'))).toList(), onChanged: (v) { if (v != null) update(() => _projectFps = v); }),
            const SizedBox(height: 14),
            const Text('BACKGROUND', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(spacing: 10, children: [for (final color in [Colors.black, const Color(0xFF202020), Colors.white, const Color(0xFF101B32), const Color(0xFF263238)]) GestureDetector(onTap: () => update(() => _projectBackground = color), child: Container(width: 34, height: 34, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: _projectBackground == color ? const Color(0xFF20E36F) : Colors.white30, width: _projectBackground == color ? 3 : 1))))]),
            const SizedBox(height: 12),
            Text('Canvas: $_projectWidth × $_projectHeight · $_projectFps FPS', style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 8),
            const Text('These settings are saved with the project. Existing source-video exports still use the source clip dimensions until the export pipeline is updated.', style: TextStyle(color: Colors.white38, fontSize: 10)),
          ])),
        );
      }),
    );
  }

  Future<void> _openInspectorSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF111214),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (sheetContext) => StatefulBuilder(builder: (context, sheetSetState) {
        _inspectorSheetSetState = sheetSetState;
        return SizedBox(
          height: MediaQuery.of(sheetContext).size.height * .78,
          child: _panel(),
        );
      }),
    );
    _inspectorSheetSetState = null;
  }

  Future<void> _showLayerActions(int index) async {
    if (index < 0 || index >= _layers.length) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF151719),
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.tune_rounded), title: const Text('Edit properties'), onTap: () => Navigator.pop(sheetContext, 'edit')),
          ListTile(leading: const Icon(Icons.copy_rounded), title: const Text('Duplicate layer'), onTap: () => Navigator.pop(sheetContext, 'duplicate')),
          ListTile(leading: const Icon(Icons.keyboard_arrow_up_rounded), title: const Text('Move layer up'), onTap: () => Navigator.pop(sheetContext, 'up')),
          ListTile(leading: const Icon(Icons.keyboard_arrow_down_rounded), title: const Text('Move layer down'), onTap: () => Navigator.pop(sheetContext, 'down')),
          ListTile(leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), title: const Text('Delete layer'), onTap: () => Navigator.pop(sheetContext, 'delete')),
        ]),
      ),
    );
    if (!mounted || action == null || index >= _layers.length) return;
    setState(() => _sel = index);
    switch (action) {
      case 'edit':
        _openInspectorSheet();
        break;
      case 'duplicate':
        _add(_layers[index].copy());
        break;
      case 'up':
        if (index < _layers.length - 1) {
          _pushUndo();
          setState(() {
            _layers.insert(index + 1, _layers.removeAt(index));
            _sel = index + 1;
          });
        }
        break;
      case 'down':
        if (index > 0) {
          _pushUndo();
          setState(() {
            _layers.insert(index - 1, _layers.removeAt(index));
            _sel = index - 1;
          });
        }
        break;
      case 'delete':
        _deleteSelected();
        break;
    }
  }

  Future<void> _showVideoOptions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF151719),
      builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.tune_rounded), title: const Text('Video settings'), onTap: () => Navigator.pop(sheetContext, 'settings')),
        ListTile(leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), title: const Text('Remove video'), onTap: () => Navigator.pop(sheetContext, 'remove')),
      ])),
    );
    if (action == 'settings') {
      _tab = tabs.indexWhere((tab) => tab.$1 == 'Adjust');
      _openInspectorSheet();
    } else if (action == 'remove') {
      _removeVideo();
    }
  }

  Future<void> _showAudioOptions(AudioTrack track) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF151719),
      builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.volume_up_rounded), title: const Text('Audio settings'), onTap: () => Navigator.pop(sheetContext, 'settings')),
        ListTile(leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), title: const Text('Remove audio'), onTap: () => Navigator.pop(sheetContext, 'remove')),
      ])),
    );
    if (action == 'settings') {
      setState(() => _tab = tabs.indexWhere((tab) => tab.$1 == 'Audio'));
      _openInspectorSheet();
    } else if (action == 'remove') {
      _deleteAudio(track);
    }
  }

  Future<void> _openMediaMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF151719),
      builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.video_library_rounded), title: const Text('Video'), subtitle: const Text('Import a video clip'), onTap: () => Navigator.pop(sheetContext, 'video')),
        ListTile(leading: const Icon(Icons.image_rounded), title: const Text('Photo or image'), onTap: () => Navigator.pop(sheetContext, 'photo')),
        ListTile(leading: const Icon(Icons.music_note_rounded), title: const Text('Audio'), onTap: () => Navigator.pop(sheetContext, 'audio')),
        ListTile(leading: const Icon(Icons.videocam_rounded), title: const Text('Camera layer'), subtitle: const Text('Camera controller for parented layers'), onTap: () => Navigator.pop(sheetContext, 'camera')),
        ListTile(leading: const Icon(Icons.control_camera_rounded), title: const Text('Null object'), subtitle: const Text('Group controller for parenting'), onTap: () => Navigator.pop(sheetContext, 'null')),
      ])),
    );
    if (choice == 'video') await _pickVideo();
    if (choice == 'photo') await _addPhoto();
    if (choice == 'audio') await _addAudio();
    if (choice == 'camera') _addCamera();
    if (choice == 'null') _addNull();
  }

  void _addSolidLayer() => _add(Layer.solid(Offset.zero));
  void _addShapeLayer() => _add(Layer.shape(const Offset(70, 60)));

  void _addAdjustmentLayer() {
    _add(Layer.adjustment(const Offset(80, 70)));
    setState(() => _tab = tabs.indexWhere((tab) => tab.$1 == 'Adjust'));
    _openInspectorSheet();
  }

  bool _effectMatches(int index) {
    final name = fxLibrary[index].$1.toLowerCase();
    if (_fxSearch.isNotEmpty && !name.contains(_fxSearch)) return false;
    if (_fxCategory == 'All') return true;
    final terms = switch (_fxCategory) {
      'Motion' => ['shake', 'scale assist', 'zoom pulse', 'spin', 'swing', 'wobble', 'drift', 'twitch'],
      'Distortion' => ['bend', 'glitch', 'rgb split', 'pixelate', 'chromatic'],
      'Generators' => ['film grain', 'flash', 'glow'],
      'Contour' => ['vignette', 'shadow', 'sketch', 'comic'],
      'Dynamics' => ['shake', 'zoom pulse', 'spin', 'flash', 'glitch'],
      'Color' => ['gray', 'mono', 'noir', 'sepia', 'vintage', 'warm', 'cool', 'negative', 'invert', 'bright', 'dark', 'contrast', 'vivid', 'saturation', 'desaturate', 'golden', 'arctic', 'rose', 'violet', 'emerald', 'crimson', 'amber', 'cinematic', 'teal', 'dusty', 'pastel', 'neon', 'sunset', 'midnight', 'retro', 'polaroid', 'dreamscape', 'horror', 'washed', 'color pop'],
      'Light' => ['glow', 'frost', 'brighten', 'flash', 'blur'],
      _ => <String>[],
    };
    return terms.any(name.contains);
  }

  Widget _panel() {
    final validSelection = _sel != null && _sel! >= 0 && _sel! < _layers.length;
    final layer = validSelection ? _layers[_sel!] : null;
    return Container(
      decoration: const BoxDecoration(
        color: const Color(0xFF0D101B),
        border: Border(left: BorderSide(color: Colors.white10)),
      ),
      child: Column(children: [
        _tabBar(),
        const Divider(height: 1, color: Colors.white10),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
            children: [
              if (_multiSelectMode)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF202735),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF20E36F).withOpacity(.45)),
                  ),
                  child: Row(children: [
                    Expanded(child: Text('${_multiSelection.length} layers selected', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                    TextButton(onPressed: _clearMultiSelect, child: const Text('Cancel')),
                    FilledButton(onPressed: _groupSelectedLayers, child: const Text('Group')),
                  ]),
                ),
              if (layer != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFF202735),
                  ),
                  child: Row(children: [
                    const Icon(Icons.layers_rounded, color: Color(0xFF20E36F), size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      layer.isImage ? 'Photo overlay' : layer.isMesh ? 'Mesh layer' : layer.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    )),
                    Text('LAYER ${_sel! + 1}', style: const TextStyle(fontSize: 8, color: Colors.white60, letterSpacing: 1)),
                  ]),
                ),
              ..._body(layer),
            ],
          ),
        ),
      ]),
    );
  }


  Widget _tool(IconData icon, String label, VoidCallback onTap) => SizedBox(
    width: 70,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 76,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 25, color: Colors.white),
          const SizedBox(height: 5),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
    ),
  );

  Widget _toolbar() => Container(
    height: 78,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: const BoxDecoration(
      color: Color(0xFF070809),
      border: Border(top: BorderSide(color: Color(0xFF242629))),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _tool(Icons.folder_open_rounded, 'Media', _openMediaMenu),
        _tool(Icons.text_fields_rounded, 'Text', _addText),
        _tool(Icons.texture_rounded, 'Solid', _addSolidLayer),
        _tool(Icons.layers_rounded, 'Adjustment', _addAdjustmentLayer),
        _tool(Icons.control_camera_rounded, 'Null', () => _add(Layer.nullObject(const Offset(100, 70)))),
        _tool(Icons.category_rounded, 'Shape', _addShapeLayer),
        _tool(Icons.open_with_rounded, 'Transform', () => _openEditorTab('Transform')),
        _tool(Icons.auto_awesome_rounded, 'Effects', () => _openEditorTab('Effects')),
        _tool(Icons.account_tree_rounded, 'Parent', _parentSelectedLayer),
        _tool(Icons.add_link_rounded, 'Create Parent', _createParentForSelectedLayers),
        _tool(Icons.group_work_rounded, 'Group', _groupSelectedLayers),
      ]),
    ),
  );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        toolbarHeight: 44,
        backgroundColor: const Color(0xFF08090B),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 14,
        title: Text(
          widget.projectName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: .1),
        ),
        actions: [
          IconButton(
            tooltip: 'MangaCut Animation Studio',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MangaCutEditor(
                projectId: widget.projectId,
                projectName: widget.projectName,
                layerNames: _layers.map((layer) => layer.text).toList(),
                onApplyImage: (target, imagePath) {
                  if (!mounted) return;
                  final index = _layers.indexWhere((layer) => layer.text == target);
                  if (index >= 0 && _layers[index].isImage) {
                    _pushUndo();
                    setState(() {
                      _layers[index].imagePath = imagePath;
                      _sel = index;
                    });
                  } else {
                    final position = index >= 0 ? _layers[index].pos : const Offset(80, 80);
                    final imageLayer = Layer.image(imagePath, position);
                    if (index >= 0) {
                      imageLayer.parentIndex = _layers[index].isController
                          ? index
                          : _layers[index].parentIndex;
                    }
                    _add(imageLayer);
                  }
                  _saveProject();
                },
                onApplyEffects: (clips) {
                  if (!mounted) return;
                  setState(() {
                    final byTarget = <String,List<MangaCutEffectClip>>{};
                    for (final clip in clips) {
                      byTarget.putIfAbsent(clip.target,()=>[]).add(clip);
                    }
                    for (final entry in byTarget.entries) {
                      final index = _layers.indexWhere((layer) => layer.text == entry.key);
                      if (index < 0) continue;
                      final targetClips = entry.value;
                      _layers[index].mangaEffects = targetClips.map((clip)=>MangaCutEffectClip(clip.id,clip.name,clip.target,clip.start,clip.end,strength:clip.strength,keys:List<int>.of(clip.keys),strengthKeys:Map<double,double>.of(clip.strengthKeys))).toList();
                    }
                  });
                  _saveProject();
                },
              ),
            )),
            icon: const Icon(Icons.animation_rounded, size: 20),
          ),
          IconButton(tooltip: 'Project settings', onPressed: _openProjectSettings, icon: const Icon(Icons.settings_rounded, size: 20)),
          if (_pivotMode)
            const Center(child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text('PIVOT', style: TextStyle(color: Color(0xFF20E36F), fontSize: 9, fontWeight: FontWeight.w900)),
            )),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _exporting ? null : _exportVideo,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF20E36F),
                foregroundColor: const Color(0xFF04140A),
                minimumSize: const Size(64, 31),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
              child: _exporting
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF04140A)))
                  : const Text('Export', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, box) {
          if (box.maxWidth >= 760) {
            return Row(children: [
              Expanded(
                flex: 3,
                child: Column(children: [
                  Expanded(flex: 5, child: _stage()),
                  _controls(),
                  Expanded(flex: 5, child: _timeline()),
                  _toolbar(),
                ]),
              ),
              SizedBox(width: 320, child: _panel()),
            ]);
          }
          return Column(children: [
            Expanded(flex: 50, child: _stage()),
            _controls(),
            Expanded(flex: 42, child: _timeline()),
            _toolbar(),
          ]);
        }),
      ),
    );
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _saveProject();
    _previewStopwatch.stop();
    _playbackTicker?.dispose();
    _vc?.dispose();
    for (final track in _audioTracks) {
      track.player.dispose();
    }
    super.dispose();
  }
}