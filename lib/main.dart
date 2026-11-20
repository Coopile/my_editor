import 'dart:io';
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
  final bool isNull;
  int? parentIndex;
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

  Layer.text(this.text, this.pos) : isMesh = false, isImage = false, isNull = false;
  Layer.mesh(this.pos) : isMesh = true, isImage = false, isNull = false, text = 'Mesh';
  Layer.image(this.imagePath, this.pos) : isMesh = false, isImage = true, isNull = false, text = 'Photo';
  Layer.nullObject(this.pos) : isMesh = false, isImage = false, isNull = true, text = 'Null';

  Layer _copyAt(Offset position) {
    final clone = isNull ? Layer.nullObject(position) : isMesh ? Layer.mesh(position) : isImage ? Layer.image(imagePath, position) : Layer.text(text, position);
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
      ..parentIndex = parentIndex
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
  String _fxCategory = 'All', _fxSearch = '';
  bool _pivotMode = false, _exporting = false;
  double _vol = 1;
  int _lastAudioSyncBucket = -1;
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
      await _pauseAudio();
    } else {
      if (controller.value.position >= _time(_trimEnd)) {
        await controller.seekTo(_time(_trimStart));
      }
      await controller.setVolume(_vol);
      _lastAudioSyncBucket = -1;
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
      if (controller.value.isPlaying) {
        final bucket = position.inMilliseconds ~/ 200;
        if (bucket != _lastAudioSyncBucket) {
          _lastAudioSyncBucket = bucket;
          _syncAudio();
        }
      }
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
    final track = AudioTrack(path: picked.path!, title: picked.name)
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
    final directory = await getTemporaryDirectory();
    final safeName = kind.toLowerCase().replaceAll(' ', '_');
    final path = '${directory.path}/editshift_${safeName}_${DateTime.now().microsecondsSinceEpoch}.wav';
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

  void _deleteSelected() {
    final index = _sel;
    if (index == null || index < 0 || index >= _layers.length) return;
    _pushUndo();
    setState(() {
      _layers.removeAt(index);
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
      case 'Shake':
        final drift = (.025 * amount).toStringAsFixed(4);
        return "crop=iw*0.92:ih*0.92:x='(iw-ow)/2+sin(t*${32 * speed})*iw*$drift':y='(ih-oh)/2+cos(t*${27 * speed})*ih*$drift',scale=trunc(iw/0.92/2)*2:trunc(ih/0.92/2)*2";
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
      final outputDir = await getApplicationDocumentsDirectory();
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
          !layer.isImage && !layer.isMesh && !layer.hidden &&
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
        final textX = textFx == 'Shake'
            ? '\'' + x.toString() + '+sin(t*' + (32 * layer.fxSpeed).toStringAsFixed(2) +
                ')*' + (10 * layer.fxStrength).toStringAsFixed(2) + '\''
            : x.toString();
        final textY = textFx == 'Shake'
            ? '\'' + y.toString() + '+cos(t*' + (27 * layer.fxSpeed).toStringAsFixed(2) +
                ')*' + (7 * layer.fxStrength).toStringAsFixed(2) + '\''
            : y.toString();
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
    if (l.hidden || (_vc != null && (_t < l.start || _t > l.end))) {
      return const SizedBox.shrink();
    }
    final al = FractionalOffset(l.pivot.dx, l.pivot.dy);
    Widget child;
    if (l.isNull) {
      child = Container(width: 150, height: 96, decoration: BoxDecoration(color: const Color(0x2236DCC4), border: Border.all(color: const Color(0xFF36DCC4), width: 1.5), borderRadius: BorderRadius.circular(12)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.control_camera_rounded, color: Color(0xFF36DCC4), size: 30), SizedBox(height: 5), Text('NULL OBJECT', style: TextStyle(color: Color(0xFF36DCC4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4)), Text('Parent controller', style: TextStyle(color: Colors.white54, fontSize: 9))]));
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
                (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0).toDouble(),
                (d.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0).toDouble(),
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
          opacity: l.opacity.clamp(0, 1).toDouble(),
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
        onPressed: vc == null ? null : _togglePlayback,
      ),
      Expanded(
        child: Slider(
          value: pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble(),
          max: dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1,
          onChanged: vc == null ? null : (v) {
            _pauseAudio();
            _lastAudioSyncBucket = -1;
            vc.seekTo(Duration(milliseconds: v.toInt()));
          },
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
        Expanded(child: Slider(value: v.clamp(mn, mx).toDouble(), min: mn, max: mx, onChanged: (x) => _ed(l, () => f(x)))),
      ]);

  Widget _globalS(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String suffix = '',
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 82, child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: Slider(
              value: value.clamp(min, max).toDouble(),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '${value.toStringAsFixed(1)}$suffix',
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ),
        ]),
      );

  Widget _timelineTrack({
    required String title,
    required IconData icon,
    required Color accent,
    required RangeValues values,
    required double max,
    required ValueChanged<RangeValues> onChanged,
    bool selected = false,
    VoidCallback? onTap,
    VoidCallback? onDelete,
  }) {
    final low = values.start.clamp(0.0, max).toDouble();
    final high = values.end.clamp(low, max).toDouble();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 2),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF282044) : const Color(0xFF171A2B),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? accent.withOpacity(.85) : Colors.white.withOpacity(.055),
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Column(children: [
          Row(children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(colors: [accent, accent.withOpacity(.35)]),
              ),
              child: Icon(icon, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            if (selected)
              const Text('SELECTED', style: TextStyle(color: Color(0xFF43D9D2), fontSize: 8, fontWeight: FontWeight.w800)),
            if (onDelete != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 28, height: 26),
                onPressed: onDelete,
                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white54),
              ),
          ]),
          SizedBox(
            height: 25,
            child: RangeSlider(
              values: RangeValues(low, high),
              min: 0,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _timeline() {
    final duration = _videoDuration;
    final selected = _sel != null && _sel! < _layers.length ? _sel! : null;
    return Container(
      height: 250,
      margin: const EdgeInsets.fromLTRB(8, 5, 8, 5),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C2037), Color(0xFF101321), Color(0xFF211633)],
        ),
        border: Border.all(color: Colors.white.withOpacity(.08)),
        boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(.08), blurRadius: 18)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.movie_filter_rounded, color: Color(0xFF43D9D2), size: 17),
          const SizedBox(width: 7),
          const Text('EDIT TIMELINE', style: TextStyle(fontSize: 10, letterSpacing: 1.7, fontWeight: FontWeight.w900)),
          const SizedBox(width: 7),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: const Color(0x2236DCC4), borderRadius: BorderRadius.circular(6)), child: const Text('MULTI-LAYER', style: TextStyle(color: Color(0xFF36DCC4), fontSize: 8, fontWeight: FontWeight.w900))),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Undo',
            onPressed: _undoStack.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo_rounded, size: 18),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Redo',
            onPressed: _redoStack.isEmpty ? null : _redo,
            icon: const Icon(Icons.redo_rounded, size: 18),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Split selected clip at playhead',
            onPressed: selected == null ? null : _splitSelected,
            icon: const Icon(Icons.content_cut_rounded, size: 17),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Delete selected layer',
            onPressed: selected == null ? null : _deleteSelected,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
          ),
        ]),
        if (_vc != null)
          Row(children: [
            Text(_fmt(_vc!.value.position), style: const TextStyle(fontSize: 9, color: Color(0xFF43D9D2))),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
                child: Slider(
                  value: _ms.clamp(0, _vc!.value.duration.inMilliseconds).toDouble(),
                  max: math.max(1, _vc!.value.duration.inMilliseconds).toDouble(),
                  onChanged: (v) {
                    _pauseAudio();
                    _lastAudioSyncBucket = -1;
                    _vc?.seekTo(Duration(milliseconds: v.round()));
                  },
                ),
              ),
            ),
            Text(_fmt(_vc!.value.duration), style: const TextStyle(fontSize: 9, color: Colors.white54)),
          ]),
        Expanded(
          child: ListView(
            children: [
              if (_vc != null)
                _timelineTrack(
                  title: 'Main video · trim clip',
                  icon: Icons.videocam_rounded,
                  accent: const Color(0xFF43D9D2),
                  values: RangeValues(
                    _trimStart.clamp(0.0, duration).toDouble(),
                    _trimEnd.clamp(_trimStart, duration).toDouble(),
                  ),
                  max: duration,
                  onDelete: _removeVideo,
                  onChanged: (range) {
                    setState(() {
                      _trimStart = range.start;
                      _trimEnd = range.end;
                    });
                    if (_vc!.value.position < _time(_trimStart) ||
                        _vc!.value.position > _time(_trimEnd)) {
                      _vc!.seekTo(_time(_trimStart));
                    }
                  },
                ),
              for (int i = 0; i < _layers.length; i++)
                _timelineTrack(
                  title: _layers[i].isNull ? 'Null object' : _layers[i].isMesh
                      ? 'Mesh overlay'
                      : _layers[i].isImage
                          ? 'Photo overlay'
                          : _layers[i].text,
                  icon: _layers[i].isNull ? Icons.control_camera_rounded : _layers[i].isMesh
                      ? Icons.grid_on
                      : _layers[i].isImage
                          ? Icons.image_rounded
                          : Icons.subtitles_rounded,
                  accent: _layers[i].isNull ? const Color(0xFF36DCC4) : _layers[i].isImage
                      ? const Color(0xFFEC8BCB)
                      : _layers[i].isMesh
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFFFFB45C),
                  values: RangeValues(_layers[i].start, _layers[i].end),
                  max: 1,
                  selected: selected == i,
                  onTap: () => setState(() => _sel = i),
                  onChanged: (range) => _ed(_layers[i], () {
                    _layers[i].start = range.start;
                    _layers[i].end = range.end;
                  }),
                ),
              for (final track in _audioTracks)
                _timelineTrack(
                  title: 'Audio · ${track.title}',
                  icon: Icons.graphic_eq_rounded,
                  accent: const Color(0xFF62C9FF),
                  values: RangeValues(track.start, track.end),
                  max: 1,
                  onChanged: (range) => setState(() {
                    track.start = range.start;
                    track.end = range.end;
                  }),
                  onTap: () => setState(() => _tab = tabs.indexWhere((tab) => tab.$1 == 'Audio')),
                  onDelete: () => _deleteAudio(track),
                ),
              if (_vc == null && _layers.isEmpty && _audioTracks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text('Your clips, photos, captions and audio will appear here',
                        style: TextStyle(fontSize: 10, color: Colors.white38)),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }

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

    if (name == 'Adjust') {
      return [
        const Text('COLOR & LIGHT', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w900, color: Color(0xFF43D9D2))),
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
            gradient: const LinearGradient(
              colors: [Color(0xFF33245F), Color(0xFF14333F)],
            ),
          ),
          child: Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF43D9D2), size: 22),
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
              onTap: () => setState(() {
                if (l == null) {
                  _videoFx = i;
                } else {
                  _pushUndo();
                  l.fx = i;
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 94,
                height: 76,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: current == i
                        ? [const Color(0xFF8B5CF6), const Color(0xFF266F83)]
                        : [const Color(0xFF24283E), const Color(0xFF171A2B)],
                  ),
                  border: Border.all(
                    color: current == i ? const Color(0xFFBFA8FF) : Colors.white.withOpacity(.06),
                    width: current == i ? 1.5 : 1,
                  ),
                  boxShadow: current == i
                      ? [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(.22), blurRadius: 14)]
                      : null,
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Icon(fxLibrary[i].$2, size: 19, color: current == i ? Colors.white : const Color(0xFF9D8FC8)),
                  Text(fxLibrary[i].$1, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        const Text('EFFECT SETTINGS', style: TextStyle(fontSize: 9, letterSpacing: 1.3, color: Colors.white38, fontWeight: FontWeight.w800)),
        if (l == null) ...[
          _globalS('Intensity', _videoFxStrength, 0, 2, (v) => setState(() => _videoFxStrength = v)),
          _globalS('Speed', _videoFxSpeed, .2, 3, (v) => setState(() => _videoFxSpeed = v), suffix: '×'),
        ] else ...[
          _s(l, 'Intensity', l.fxStrength, 0, 2, (v) => l.fxStrength = v),
          _s(l, 'Speed', l.fxSpeed, .2, 3, (v) => l.fxSpeed = v),
          if (currentName == 'Bend')
            _s(l, 'Bend', l.bend, -0.8, 0.8, (v) => l.bend = v),
        ],
      ];
    }

    if (name == 'Audio') {
      return [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [Color(0xFF193A4E), Color(0xFF1C2440)]),
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
          _s(l, 'Position X', l.pos.dx, 0, 600, (v) => l.pos = Offset(v, l.pos.dy)),
          _s(l, 'Position Y', l.pos.dy, 0, 400, (v) => l.pos = Offset(l.pos.dx, v)),
          _s(l, 'Size', l.scale, .3, 3, (v) => l.scale = v),
          _s(l, 'Rotate', l.rot, -math.pi, math.pi, (v) => l.rot = v),
          _s(l, 'Pivot X', l.pivot.dx, 0, 1, (v) => l.pivot = Offset(v, l.pivot.dy)),
          _s(l, 'Pivot Y', l.pivot.dy, 0, 1, (v) => l.pivot = Offset(l.pivot.dx, v)),
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
            OutlinedButton(
              onPressed: () => _ed(l, () => l.kfs.clear()),
              child: const Text('Clear all'),
            ),
          ]),
          const SizedBox(height: 8),
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

  bool _effectMatches(int index) {
    final name = fxLibrary[index].$1.toLowerCase();
    if (_fxSearch.isNotEmpty && !name.contains(_fxSearch)) return false;
    if (_fxCategory == 'All') return true;
    final terms = switch (_fxCategory) {
      'Motion' => ['shake', 'zoom pulse', 'spin', 'swing', 'wobble', 'drift', 'twitch'],
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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF15182A), Color(0xFF0D101B)],
        ),
        border: Border(left: BorderSide(color: Colors.white10)),
      ),
      child: Column(children: [
        _tabBar(),
        const Divider(height: 1, color: Colors.white10),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
            children: [
              if (layer != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(colors: [Color(0xFF30234F), Color(0xFF173744)]),
                  ),
                  child: Row(children: [
                    const Icon(Icons.layers_rounded, color: Color(0xFF43D9D2), size: 18),
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

  Widget _tool(IconData icon, String label, VoidCallback onTap) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 38,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF34265F), Color(0xFF1D4050)],
                ),
              ),
              child: Icon(icon, size: 19, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  Widget _toolbar() => Container(
        padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
        decoration: const BoxDecoration(
          color: Color(0xFF0D101B),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Expanded(child: _tool(Icons.video_library_rounded, 'Video', _pickVideo)),
          Expanded(child: _tool(Icons.add_photo_alternate_rounded, 'Photo', _addPhoto)),
          Expanded(child: _tool(Icons.title_rounded, 'Caption', _addText)),
          Expanded(child: _tool(Icons.graphic_eq_rounded, 'Audio', _addAudio)),
          Expanded(child: _tool(Icons.grid_on_rounded, 'Mesh', () => _add(Layer.mesh(const Offset(80, 40))))),
          Expanded(child: _tool(Icons.control_camera_rounded, 'Null', () => _add(Layer.nullObject(const Offset(100, 70))))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF101321),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1B2030), Color(0xFF141B2A), Color(0xFF102D32)],
            ),
          ),
        ),
        title: Text(
          widget.projectName,
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -.4, fontSize: 17),
        ),
        actions: [
          if (_pivotMode)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: Text('PIVOT MODE', style: TextStyle(color: Color(0xFF43D9D2), fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _exporting ? null : _exportVideo,
              icon: _exporting
                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.ios_share_rounded, size: 16),
              label: Text(_exporting ? 'Rendering' : 'Export'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
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
                  Expanded(child: _stage()),
                  _controls(),
                  _timeline(),
                  _toolbar(),
                ]),
              ),
              SizedBox(width: 340, child: _panel()),
            ]);
          }
          return Column(children: [
            Expanded(flex: 5, child: _stage()),
            _controls(),
            _timeline(),
            Expanded(flex: 4, child: _panel()),
            _toolbar(),
          ]);
        }),
      ),
    );
  }

  @override
  void dispose() {
    _vc?.dispose();
    for (final track in _audioTracks) {
      track.player.dispose();
    }
    super.dispose();
  }
}