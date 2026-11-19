import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'home_screen.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090A12),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5CF6), brightness: Brightness.dark),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    ));

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
  ('Shake', Icons.vibration),
  ('Zoom Pulse', Icons.zoom_in),
  ('Spin', Icons.rotate_right),
  ('Glitch', Icons.broken_image),
  ('RGB Split', Icons.filter_b_and_w),
  ('Flash', Icons.flash_on),
  ('Glow', Icons.wb_sunny),
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
  final amount = strength.clamp(0.0, 2.0);
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
                    .clamp(0.0, .65),
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
                  colors: [Colors.transparent, Colors.black.withOpacity(.82 * amount.clamp(0.0, 1.0))],
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
          Matrix4.identity()..scale(0.16 + (1 - amount.clamp(0.0, 1.0)) * .12),
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

class _GrainPainter extends CustomPainter {
  final double time;
  final double strength;
  _GrainPainter({required this.time, required this.strength});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(time.floor() + 17);
    final paint = Paint()..strokeWidth = 1;
    final count = (size.width * size.height / 180 * strength).round().clamp(0, 2200);
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

class Layer {
  final bool isMesh;
  final bool isImage;
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

  Layer.text(this.text, this.pos) : isMesh = false, isImage = false;
  Layer.mesh(this.pos) : isMesh = true, isImage = false, text = 'Mesh';
  Layer.image(this.imagePath, this.pos) : isMesh = false, isImage = true, text = 'Photo';

  Layer _copyAt(Offset position) {
    final clone = isMesh
        ? Layer.mesh(position)
        : isImage
            ? Layer.image(imagePath, position)
            : Layer.text(text, position);
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
      ..mesh = List.of(mesh)
      ..kfs = kfs.map((k) => KF(k.t, k.pos, k.scale, k.rot, k.opacity)).toList();
    return clone;
  }

  Layer copy() => _copyAt(pos + const Offset(20, 20));
  Layer snapshot() => _copyAt(pos);

  void upsert(int ms) {
    kfs.removeWhere((k) => (k.t - ms).abs() < 60);
    kfs.add(KF(ms, pos, scale, rot, opacity));
    kfs.sort((a, b) => a.t - b.t);
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
    final f = a.t == b.t ? 0.0 : (ms - a.t) / (b.t - a.t);
    pos = Offset.lerp(a.pos, b.pos, f)!;
    scale = ui.lerpDouble(a.scale, b.scale, f)!;
    rot = ui.lerpDouble(a.rot, b.rot, f)!;
    opacity = ui.lerpDouble(a.opacity, b.opacity, f)!;
  }
}

class AudioTrack {
  final String path;
  final String title;
  final AudioPlayer player;
  double volume;
  double start = 0;
  double end = 1;
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
  const Editor({super.key, this.projectName = 'Untitled project'});
  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  VideoPlayerController? _vc;
  final List<Layer> _layers = [];
  final List<AudioTrack> _audioTracks = [];
  final List<List<Layer>> _undoStack = [];
  final List<List<Layer>> _redoStack = [];
  int? _sel;
  int _videoFx = 0, _tab = 0;
  bool _pivotMode = false, _exporting = false;
  double _vol = 1;
  double _trimStart = 0, _trimEnd = 0;
  double _videoFxStrength = 1, _videoFxSpeed = 1;
  double _brightness = 0, _contrast = 1, _saturation = 1;
  String? _videoPath;
  Size _stageSize = const Size(360, 230);

  int get _ms => _vc?.value.position.inMilliseconds ?? 0;
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
      _sel = _layers.isEmpty ? null : (_sel ?? 0).clamp(0, _layers.length - 1);
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
      _sel = _layers.isEmpty ? null : (_sel ?? 0).clamp(0, _layers.length - 1);
    });
  }

  void _ed(Layer l, VoidCallback f) {
    _pushUndo();
    setState(() {
      f();
      if (l.kfs.isNotEmpty) l.upsert(_ms);
    });
  }

  Future<void> _pauseAudio() async {
    for (final track in _audioTracks) {
      await track.player.pause();
    }
  }

  Future<void> _syncAudio() async {
    final now = _ms / 1000;
    for (final track in _audioTracks) {
      final startMs = (track.start * _videoDuration * 1000).round();
      final endMs = (track.end * _videoDuration * 1000).round();
      if (now * 1000 >= startMs && now * 1000 < endMs) {
        final offset = Duration(milliseconds: (_ms - startMs).clamp(0, 1 << 30));
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
      await _pauseAudio();
    } else {
      if (controller.value.position >= _time(_trimEnd)) {
        await controller.seekTo(_time(_trimStart));
      }
      await controller.setVolume(_vol);
      await controller.play();
      await _syncAudio();
    }
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    await _vc?.dispose();
    _videoPath = picked.path;
    final controller = VideoPlayerController.file(File(picked.path));
    await controller.initialize();
    await controller.setLooping(false);
    _trimStart = 0;
    _trimEnd = controller.value.duration.inMilliseconds / 1000;
    controller.addListener(() {
      final position = controller.value.position;
      for (final layer in _layers) {
        layer.apply(position.inMilliseconds);
      }
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
    _add(Layer.image(picked.path, const Offset(52, 52)));
  }

  Future<void> _addAudio() async {
    final picked = await FilePicker.pickFile(type: FileType.audio);
    if (picked == null || picked.path == null) return;
    final track = AudioTrack(path: picked.path!, title: picked.name);
    await track.player.setSourceDeviceFile(track.path);
    if (!mounted) {
      await track.player.dispose();
      return;
    }
    setState(() => _audioTracks.add(track));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added audio: \${track.title}')),
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

  void _deleteSelected() {
    final index = _sel;
    if (index == null || index < 0 || index >= _layers.length) return;
    _pushUndo();
    setState(() {
      _layers.removeAt(index);
      _sel = _layers.isEmpty ? null : math.min(index, _layers.length - 1);
      _pivotMode = false;
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
      '"\${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

  String _filterText(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll(':', r'\:')
      .replaceAll("'", r"\'")
      .replaceAll(',', r'\,')
      .replaceAll('%', r'\%')
      .replaceAll('[', r'\[')
      .replaceAll(']', r'\]');

  String _exportEffectFilter() {
    final name = fxLibrary[_videoFx].$1;
    final amount = _videoFxStrength.clamp(0.0, 2.0);
    final speed = _videoFxSpeed.clamp(.1, 3.0);
    switch (name) {
      case 'Shake':
        final drift = (.025 * amount).toStringAsFixed(4);
        return "crop=iw*0.92:ih*0.92:x='(iw-ow)/2+sin(t*\${32 * speed})*iw*$drift':y='(ih-oh)/2+cos(t*\${27 * speed})*ih*$drift',scale=trunc(iw/0.92/2)*2:trunc(ih/0.92/2)*2";
      case 'Zoom Pulse':
        return "scale=iw*(1+0.045*sin(t*\${6 * speed})):ih*(1+0.045*sin(t*\${6 * speed})):eval=frame,crop=iw/1.045:ih/1.045";
      case 'Spin':
        return "rotate='0.025*sin(t*\${2.4 * speed})':c=black@0";
      case 'Glitch':
      case 'RGB Split':
        return "rgbashift=rh='sin(t*\${42 * speed})*\${(5 * amount).toStringAsFixed(2)}':bh='-sin(t*\${37 * speed})*\${(5 * amount).toStringAsFixed(2)}'";
      case 'Flash':
        return "eq=brightness='if(lt(mod(t,\${(0.5 / speed).toStringAsFixed(3)}),0.08),\${(0.65 * amount).toStringAsFixed(3)},0)'";
      case 'Glow':
        return "gblur=sigma=\${(2.5 * amount).toStringAsFixed(2)}";
      case 'Vignette':
        return "vignette=PI/4";
      case 'Film Grain':
        return "noise=alls=\${(18 * amount).round()}:allf=t+u";
      case 'Pixelate':
        return "scale=iw/16:ih/16:flags=neighbor,scale=iw*16:ih*16:flags=neighbor";
      case 'Soft Blur':
      case 'Dream Blur':
      case 'Gaussian Blur':
      case 'Motion Blur':
      case 'Soft Focus':
        return "gblur=sigma=\${(2.5 * amount).toStringAsFixed(2)}";
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
        return 'eq=contrast=\${contrast.toStringAsFixed(2)}:saturation=\${saturation.toStringAsFixed(2)}';
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
      final trimStart = _trimStart.clamp(0.0, totalDuration);
      final trimEnd = _trimEnd.clamp(trimStart + .05, totalDuration);
      final clipDuration = trimEnd - trimStart;
      final outputDir = await getApplicationDocumentsDirectory();
      final outputPath =
          '\${outputDir.path}/EditShift_\${DateTime.now().millisecondsSinceEpoch}.mp4';

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
          !layer.isImage && !layer.isMesh && !layer.hidden &&
          layer.text.trim().isNotEmpty &&
          layer.end * totalDuration > trimStart &&
          layer.start * totalDuration < trimEnd).toList();

      final command = StringBuffer();
      command.write('-ss \${trimStart.toStringAsFixed(3)} -i \${_ffArg(source)} ');
      for (final layer in imageLayers) {
        command.write('-loop 1 -i \${_ffArg(layer.imagePath!)} ');
      }
      for (final track in _audioTracks) {
        command.write('-i \${_ffArg(track.path)} ');
      }

      final videoFilters = <String>[];
      final effect = _exportEffectFilter();
      if (effect.isNotEmpty) videoFilters.add(effect);
      videoFilters.add(
        'eq=brightness=\${_brightness.toStringAsFixed(3)}:contrast=\${_contrast.toStringAsFixed(3)}:saturation=\${_saturation.toStringAsFixed(3)}',
      );

      final graph = <String>[];
      graph.add('[0:v]\${videoFilters.join(',')}[v0]');
      var currentVideo = 'v0';
      var outputNumber = 0;
      final videoSize = _vc?.value.size ?? const Size(1280, 720);
      final scale = videoSize.width / math.max(1, _stageSize.width);

      for (int i = 0; i < imageLayers.length; i++) {
        final layer = imageLayers[i];
        final inputIndex = i + 1;
        final imageLabel = 'image$i';
        final nextLabel = 'v\${++outputNumber}';
        final imageWidth = (190 * layer.scale * scale).round().clamp(24, 4096);
        final x = (layer.pos.dx * scale).round();
        final y = (layer.pos.dy * scale).round();
        final start = (layer.start * totalDuration - trimStart).clamp(0.0, clipDuration);
        final end = (layer.end * totalDuration - trimStart).clamp(0.0, clipDuration);
        if (end <= start) continue;
        graph.add('[$inputIndex:v]scale=$imageWidth:-1[$imageLabel]');
        graph.add('[$currentVideo][$imageLabel]overlay=x=$x:y=$y:enable=\'between(t,$start,$end)\'[$nextLabel]');
        currentVideo = nextLabel;
      }

      for (final layer in textLayers) {
        final nextLabel = 'v\${++outputNumber}';
        final start = (layer.start * totalDuration - trimStart).clamp(0.0, clipDuration);
        final end = (layer.end * totalDuration - trimStart).clamp(0.0, clipDuration);
        if (end <= start) continue;
        final x = (layer.pos.dx * scale).round();
        final y = (layer.pos.dy * scale).round();
        final fontSize = (layer.fontSize * scale).round().clamp(10, 260);
        final colorHex = layer.color.value.toRadixString(16).padLeft(8, '0').substring(2);
        final text = _filterText(layer.text);
        graph.add(
          '[$currentVideo]drawtext=text=\'$text\':fontcolor=0x$colorHex:fontsize=$fontSize:x=$x:y=$y:borderw=2:bordercolor=black@0.45:enable=\'between(t,$start,$end)\'[$nextLabel]',
        );
        currentVideo = nextLabel;
      }

      final audioInputStart = 1 + imageLayers.length;
      final audioLabels = <String>[];
      if (sourceHasAudio) {
        graph.add('[0:a]volume=\${_vol.toStringAsFixed(3)}[baseaudio]');
        audioLabels.add('[baseaudio]');
      }
      for (int i = 0; i < _audioTracks.length; i++) {
        final track = _audioTracks[i];
        final inputIndex = audioInputStart + i;
        final start = (track.start * totalDuration - trimStart).clamp(0.0, clipDuration);
        final end = (track.end * totalDuration - trimStart).clamp(0.0, clipDuration);
        if (end <= start) continue;
        final delay = (start * 1000).round();
        final length = (end - start).toStringAsFixed(3);
        final label = 'audio$i';
        graph.add('[$inputIndex:a]atrim=duration=$length,asetpts=PTS-STARTPTS,adelay=$delay|$delay,volume=\${track.volume.toStringAsFixed(3)}[$label]');
        audioLabels.add('[$label]');
      }

      graph.add('[$currentVideo]null[vout]');
      if (audioLabels.length > 1) {
        graph.add('\${audioLabels.join()}amix=inputs=\${audioLabels.length}:duration=longest:dropout_transition=2[aout]');
      } else if (audioLabels.length == 1) {
        graph.add('\${audioLabels.single}anull[aout]');
      }

      command.write('-t \${clipDuration.toStringAsFixed(3)} ');
      command.write('-filter_complex "\${graph.join(';')}" ');
      command.write('-map "[vout]" ');
      if (audioLabels.isNotEmpty) {
        command.write('-map "[aout]" -c:a aac -b:a 192k ');
      } else {
        command.write('-an ');
      }
      command.write('-c:v mpeg4 -q:v 2 -pix_fmt yuv420p -movflags +faststart \${_ffArg(outputPath)}');

      final session = await FFmpegKit.execute(command.toString());
      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode) || !File(outputPath).existsSync()) {
        final logs = await session.getLogs();
        final details = logs.map((log) => log.getMessage()).join('\n');
        throw Exception(details.isEmpty ? 'FFmpeg export failed.' : details);
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
            content: Text('Export failed: \${message.length > 220 ? message.substring(0, 220) : message}'),
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
    if (l.hidden || (_vc != null && (_t < l.start || _t > l.end))) {
      return const SizedBox.shrink();
    }
    final al = FractionalOffset(l.pivot.dx, l.pivot.dy);
    Widget child;
    if (l.isMesh) {
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
    child = applyFx(
      l.fx,
      child,
      strength: l.fxStrength,
      speed: l.fxSpeed,
      time: _ms / 1000,
    );
    if (sel && _pivotMode) {
      child = Stack(children: [
        child,
        Positioned.fill(
          child: LayoutBuilder(builder: (pivotContext, constraints) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (d) => setState(() {
              l.pivot = Offset(
                (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0),
                (d.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0),
              );
            }),
            child: Align(
              alignment: Alignment(l.pivot.dx * 2 - 1, l.pivot.dy * 2 - 1),
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(color: const Color(0xFF8B5CF6), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.open_with, size: 13, color: Colors.white),
              ),
            ),
          )),
        ),
      ]);
    }
    return Positioned(
      left: l.pos.dx, top: l.pos.dy,
      child: GestureDetector(
        onTap: () => setState(() => _sel = i),
        onDoubleTap: () => setState(() { _sel = i; _pivotMode = !_pivotMode; }),
        onPanUpdate: (d) => _ed(l, () { _sel = i; l.pos += d.delta; }),
        child: Opacity(
          opacity: l.opacity.clamp(0, 1),
          child: Transform(
            alignment: al,
            transform: Matrix4.identity()
              ..setEntry(1, 0, l.bend)
              ..rotateZ(l.rot)
              ..multiply(Matrix4.diagonal3Values(
                  l.scale * (l.flipX ? -1 : 1), l.scale * (l.flipY ? -1 : 1), 1)),
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF090B18), Color(0xFF101528), Color(0xFF15112C)],
            ),
          ),
          child: ClipRect(
            child: Stack(fit: StackFit.expand, children: [
              if (vc != null)
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
              else
                const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.movie_creation_outlined, size: 54, color: Color(0xFF8B5CF6)),
                    SizedBox(height: 12),
                    Text('Import a clip to start your edit', style: TextStyle(color: Colors.white70)),
                  ]),
                ),
              for (int i = 0; i < _layers.length; i++) _layerView(i),
            ]),
          ),
        ),
      );
    });
  }

  Widget _controls() {
    final vc = _vc;
    final pos = vc?.value.position ?? Duration.zero;
    final dur = vc?.value.duration ?? Duration.zero;
    return Row(children: [
      IconButton(
        iconSize: 36,
        icon: Icon(vc?.value.isPlaying == true ? Icons.pause_circle : Icons.play_circle),
        onPressed: vc == null ? null : () => vc.value.isPlaying ? vc.pause() : vc.play(),
      ),
      Expanded(
        child: Slider(
          value: pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble(),
          max: dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1,
          onChanged: vc == null ? null : (v) => vc.seekTo(Duration(milliseconds: v.toInt())),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Text('${_fmt(pos)} / ${_fmt(dur)}', style: const TextStyle(fontSize: 12)),
      ),
    ]);
  }

  Widget _track(String label, Color color, double s, double e, {bool sel = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(flex: (s * 1000).round() + 1, child: const SizedBox()),
          Expanded(
            flex: ((e - s) * 1000).round() + 1,
            child: Container(
              height: 28, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6),
                  border: sel ? Border.all(color: Colors.blue, width: 2) : null),
              child: Text(label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.clip),
            ),
          ),
          Expanded(flex: ((1 - e) * 1000).round() + 1, child: const SizedBox()),
        ]),
      );

  Widget _s(Layer l, String t, double v, double mn, double mx, void Function(double) f) =>
      Row(children: [
        SizedBox(width: 72, child: Text(t, style: const TextStyle(fontSize: 13))),
        Expanded(child: Slider(value: v.clamp(mn, mx), min: mn, max: mx, onChanged: (x) => _ed(l, () => f(x)))),
      ]);

  Widget _tabBar() => SizedBox(
        height: 62,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          itemBuilder: (_, i) => InkWell(
            onTap: () => setState(() => _tab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 74,
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                      color: _tab == i ? const Color(0xFF8B5CF6) : Colors.transparent, width: 3))),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(tabs[i].$2, color: _tab == i ? const Color(0xFFB69CFF) : Colors.white54),
                Text(tabs[i].$1, style: const TextStyle(fontSize: 11)),
              ]),
            ),
          ),
        ),
      );

  Widget _note(String t) => Padding(padding: const EdgeInsets.all(12), child: Text(t));

  List<Widget> _body(Layer? l) {
    final name = tabs[_tab].$1;
    if (name == 'Effects') {
      final cur = l?.fx ?? _videoFx;
      return [
        Text('Applies to: ${l == null ? 'video' : 'selected layer'}'),
        if (l != null && fxLibrary[cur].$1 == 'Bend')
          _s(l, 'Bend amount', l.bend, -0.8, 0.8, (v) => l.bend = v),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (int i = 0; i < fxLibrary.length; i++)
            InkWell(
              onTap: () => setState(() { if (l == null) { _videoFx = i; } else { l.fx = i; } }),
              child: Container(
                width: 68, height: 64,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cur == i ? Colors.blue : Colors.black26, width: cur == i ? 2 : 1)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(fxLibrary[i].$2), Text(fxLibrary[i].$1, style: const TextStyle(fontSize: 11)),
                ]),
              ),
            ),
        ]),
      ];
    }
    if (name == 'Audio') {
      return [
        Row(children: [
          const Text('Volume'),
          Expanded(child: Slider(value: _vol, onChanged: (v) { setState(() => _vol = v); _vc?.setVolume(v); })),
          IconButton(
            icon: Icon(_vol == 0 ? Icons.volume_off : Icons.volume_up),
            onPressed: () { setState(() => _vol = _vol == 0 ? 1 : 0); _vc?.setVolume(_vol); },
          ),
        ]),
      ];
    }
    if (l == null) return [_note('Select a layer (or add text or a mesh) to use this tab.')];
    switch (name) {
      case 'Transform':
        return [
          _s(l, 'Position X', l.pos.dx, 0, 600, (v) => l.pos = Offset(v, l.pos.dy)),
          _s(l, 'Position Y', l.pos.dy, 0, 400, (v) => l.pos = Offset(l.pos.dx, v)),
          _s(l, 'Size', l.scale, .3, 3, (v) => l.scale = v),
          _s(l, 'Rotate', l.rot, -math.pi, math.pi, (v) => l.rot = v),
          _s(l, 'Pivot X', l.pivot.dx, 0, 1, (v) => l.pivot = Offset(v, l.pivot.dy)),
          _s(l, 'Pivot Y', l.pivot.dy, 0, 1, (v) => l.pivot = Offset(l.pivot.dx, v)),
          Wrap(spacing: 8, children: [
            FilterChip(label: const Text('Flip horizontal'), selected: l.flipX, onSelected: (v) => setState(() => l.flipX = v)),
            FilterChip(label: const Text('Flip vertical'), selected: l.flipY, onSelected: (v) => setState(() => l.flipY = v)),
          ]),
        ];
      case 'Color':
        return [
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final c in [Colors.white, Colors.black, Colors.red, Colors.orange, Colors.yellow,
              Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.pink])
              GestureDetector(
                onTap: () => setState(() => l.color = c),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle,
                      border: Border.all(color: l.color == c ? Colors.blue : Colors.black26, width: l.color == c ? 3 : 1)),
                ),
              ),
          ]),
          if (l.isMesh) _note('On a mesh layer this sets the center color.'),
        ];
      case 'Mesh':
        if (!l.isMesh) return [_note('Select a mesh layer. Add one with the Mesh button.')];
        return [
          _note('Drag the white points on the preview to warp the mesh.'),
          Wrap(spacing: 8, children: [
            ActionChip(label: const Text('Reset'), onPressed: () => setState(() => l.mesh = defaultMesh())),
            ActionChip(
              label: const Text('Wave'),
              onPressed: () => setState(() => l.mesh = [
                    for (int r = 0; r < 3; r++)
                      for (int c = 0; c < 3; c++) Offset(c / 2, r / 2 + (c == 1 ? (r == 0 ? .1 : -.1) : 0))
                  ]),
            ),
            ActionChip(
              label: const Text('Pinch'),
              onPressed: () => setState(() => l.mesh = [
                    for (final p in l.mesh) Offset(.5 + (p.dx - .5) * .7, .5 + (p.dy - .5) * .7)
                  ]),
            ),
          ]),
        ];
      case 'Text':
        if (l.isMesh) return [_note('Select a text layer.')];
        return [
          TextFormField(
            key: ValueKey(l), initialValue: l.text,
            decoration: const InputDecoration(labelText: 'Text'),
            onChanged: (v) => setState(() => l.text = v),
          ),
          _s(l, 'Font size', l.fontSize, 12, 120, (v) => l.fontSize = v),
          Wrap(spacing: 8, children: [
            FilterChip(label: const Text('Bold'), selected: l.bold, onSelected: (v) => setState(() => l.bold = v)),
            FilterChip(label: const Text('Italic'), selected: l.italic, onSelected: (v) => setState(() => l.italic = v)),
          ]),
        ];
      case 'Opacity':
        return [
          _s(l, 'Opacity', l.opacity, 0, 1, (v) => l.opacity = v),
          SwitchListTile(title: const Text('Shadow (text)'), value: l.shadow, onChanged: (v) => setState(() => l.shadow = v)),
        ];
      case 'Keyframes':
        return [
          _note('Add a keyframe at the current time, move the playhead, change position, size, rotation or opacity, and it animates between them.'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(icon: const Icon(Icons.diamond), label: const Text('Add keyframe here'),
                onPressed: () => setState(() => l.upsert(_ms))),
            OutlinedButton(onPressed: () => setState(() => l.kfs.clear()), child: const Text('Clear all')),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 6, children: [
            for (final k in l.kfs)
              ActionChip(
                avatar: const Icon(Icons.diamond, size: 14),
                label: Text(_fmt(Duration(milliseconds: k.t))),
                onPressed: () => _vc?.seekTo(Duration(milliseconds: k.t)),
              ),
          ]),
        ];
      case 'Timing':
        return [
          const Text('When this layer is visible'),
          RangeSlider(
            values: RangeValues(l.start, l.end),
            onChanged: (v) => setState(() { l.start = v.start; l.end = v.end; }),
          ),
        ];
      default:
        final i = _sel!;
        return [
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(icon: const Icon(Icons.copy), label: const Text('Duplicate'),
                onPressed: () => _add(l.copy())),
            OutlinedButton.icon(
                icon: Icon(l.hidden ? Icons.visibility_off : Icons.visibility),
                label: Text(l.hidden ? 'Show' : 'Hide'),
                onPressed: () => setState(() => l.hidden = !l.hidden)),
            OutlinedButton.icon(icon: const Icon(Icons.arrow_upward), label: const Text('Forward'),
                onPressed: i == _layers.length - 1 ? null : () => setState(() {
                      _layers.insert(i + 1, _layers.removeAt(i)); _sel = i + 1; })),
            OutlinedButton.icon(icon: const Icon(Icons.arrow_downward), label: const Text('Back'),
                onPressed: i == 0 ? null : () => setState(() {
                      _layers.insert(i - 1, _layers.removeAt(i)); _sel = i - 1; })),
            OutlinedButton.icon(icon: const Icon(Icons.delete_outline), label: const Text('Delete'),
                onPressed: () => setState(() { _layers.removeAt(i); _sel = null; })),
          ]),
        ];
    }
  }

  Widget _panel() {
    final l = _sel == null ? null : _layers[_sel!];
    return Container(
      color: const Color(0xFF111321),
      child: Column(children: [
      _tabBar(),
      const Divider(height: 1, color: Colors.white10),
      Expanded(
        child: ListView(padding: const EdgeInsets.all(12), children: [
          if (_vc != null) _track('Video', Colors.blue.shade100, 0, 1),
          for (int i = 0; i < _layers.length; i++)
            GestureDetector(
              onTap: () => setState(() => _sel = i),
              child: _track(_layers[i].isMesh ? 'Mesh' : 'Text: ${_layers[i].text}',
                  _layers[i].isMesh ? Colors.green.shade100 : Colors.orange.shade100,
                  _layers[i].start, _layers[i].end, sel: _sel == i),
            ),
          const SizedBox(height: 10),
          ..._body(l),
        ]),
      ),
    ]));
  }

  Widget _tool(IconData icon, String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon), Text(label, style: const TextStyle(fontSize: 11)),
          ]),
        ),
      );

  Widget _toolbar() => Container(
        decoration: const BoxDecoration(color: Color(0xFF111321), border: Border(top: BorderSide(color: Colors.white10))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _tool(Icons.add, 'Add', _pickVideo),
          _tool(Icons.title, 'Text', _addText),
          _tool(Icons.grid_on, 'Mesh', () => _add(Layer.mesh(const Offset(80, 40)))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0F1B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.projectName, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -.3)),
        actions: [
          if (_pivotMode) const Padding(padding: EdgeInsets.only(right: 8), child: Center(child: Text('PIVOT MODE · drag the purple handle', style: TextStyle(color: Color(0xFF43D9D2), fontSize: 11)))),
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Export coming soon'))),
            child: const Text('Export'),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, box) {
          if (box.maxWidth >= 700) {
            return Row(children: [
              Expanded(flex: 3, child: Column(children: [
                Expanded(child: _stage()), _controls(), _toolbar(),
              ])),
              SizedBox(width: 360, child: _panel()),
            ]);
          }
          return Column(children: [
            SizedBox(height: 230, width: double.infinity, child: _stage()),
            _controls(),
            Expanded(child: _panel()),
            _toolbar(),
          ]);
        }),
      ),
    );
  }

  @override
  void dispose() {
    _vc?.dispose();
    super.dispose();
  }
}