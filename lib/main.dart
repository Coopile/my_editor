import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
];
const _m = {
  'Gray': [0.21, 0.72, 0.07, 0, 0, 0.21, 0.72, 0.07, 0, 0, 0.21, 0.72, 0.07, 0, 0, 0, 0, 0, 1, 0],
  'Sepia': [0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272, 0.534, 0.131, 0, 0, 0, 0, 0, 1, 0],
  'Invert': [-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0],
  'Bright': [1, 0, 0, 0, 45, 0, 1, 0, 0, 45, 0, 0, 1, 0, 45, 0, 0, 0, 1, 0],
  'Contrast': [1.5, 0, 0, 0, -64, 0, 1.5, 0, 0, -64, 0, 0, 1.5, 0, -64, 0, 0, 0, 1, 0],
};

Widget applyFx(int i, Widget w) {
  final n = fxLibrary[i].$1;
  if (n == 'None' || n == 'Bend') return w;
  if (n.toLowerCase().contains('blur') || n == 'Soft Focus') {
    final sigma = n == 'Motion Blur' ? 7.0 : n == 'Gaussian Blur' ? 5.0 : 3.0;
    return ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma), child: w);
  }
  final key = switch (n) {
    'Grayscale' || 'Mono' || 'Noir' => 'Gray',
    'Vintage' || 'Sepia' || 'Warm Film' || 'Golden Hour' || 'Polaroid' => 'Sepia',
    'Negative' || 'Invert' => 'Invert',
    'Brighten' => 'Bright',
    'High Contrast' || 'Deep Contrast' => 'Contrast',
    _ => '',
  };
  final matrix = key.isNotEmpty ? _m[key]!.map((e) => e.toDouble()).toList() : _presetMatrix(i);
  return ColorFiltered(colorFilter: ColorFilter.matrix(matrix), child: w);
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
  String text;
  Offset pos;
  double scale = 1, rot = 0, opacity = 1, fontSize = 30, start = 0, end = 1, bend = 0;
  Offset pivot = const Offset(.5, .5);
  int fx = 0;
  Color color = Colors.white;
  bool bold = true, italic = false, flipX = false, flipY = false, shadow = false, hidden = false;
  List<Offset> mesh = defaultMesh();
  List<KF> kfs = [];
  Layer.text(this.text, this.pos) : isMesh = false;
  Layer.mesh(this.pos) : isMesh = true, text = 'Mesh';

  Layer copy() => (isMesh ? Layer.mesh(pos + const Offset(20, 20)) : Layer.text(text, pos + const Offset(20, 20)))
    ..scale = scale ..rot = rot ..opacity = opacity ..fontSize = fontSize ..start = start ..end = end ..bend = bend
    ..pivot = pivot ..fx = fx ..color = color ..bold = bold ..italic = italic
    ..flipX = flipX ..flipY = flipY ..shadow = shadow ..mesh = List.of(mesh);

  void upsert(int ms) {
    kfs.removeWhere((k) => (k.t - ms).abs() < 60);
    kfs.add(KF(ms, pos, scale, rot, opacity));
    kfs.sort((a, b) => a.t - b.t);
  }

  void apply(int ms) {
    if (kfs.isEmpty) return;
    var a = kfs.first, b = kfs.last;
    if (ms <= a.t) { b = a; }
    else if (ms >= b.t) { a = b; }
    else {
      for (int i = 0; i < kfs.length - 1; i++) {
        if (ms >= kfs[i].t && ms <= kfs[i + 1].t) { a = kfs[i]; b = kfs[i + 1]; break; }
      }
    }
    final f = a.t == b.t ? 0.0 : (ms - a.t) / (b.t - a.t);
    pos = Offset.lerp(a.pos, b.pos, f)!;
    scale = ui.lerpDouble(a.scale, b.scale, f)!;
    rot = ui.lerpDouble(a.rot, b.rot, f)!;
    opacity = ui.lerpDouble(a.opacity, b.opacity, f)!;
  }
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
  ('Transform', Icons.open_with), ('Color', Icons.palette), ('Effects', Icons.auto_awesome),
  ('Mesh', Icons.grid_on), ('Text', Icons.text_fields), ('Opacity', Icons.opacity),
  ('Keyframes', Icons.diamond_outlined), ('Timing', Icons.timelapse),
  ('Audio', Icons.volume_up), ('Layer', Icons.layers),
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
  int? _sel;
  int _videoFx = 0, _tab = 0;
  bool _pivotMode = false;
  double _vol = 1;

  int get _ms => _vc?.value.position.inMilliseconds ?? 0;
  double get _t {
    final d = _vc?.value.duration.inMilliseconds ?? 0;
    return d == 0 ? 0 : _ms / d;
  }

  void _ed(Layer l, VoidCallback f) => setState(() {
        f();
        if (l.kfs.isNotEmpty) l.upsert(_ms);
      });

  Future<void> _pickVideo() async {
    final f = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (f == null) return;
    await _vc?.dispose();
    final c = VideoPlayerController.file(File(f.path));
    await c.initialize();
    c.setLooping(true);
    c.addListener(() {
      for (final l in _layers) { l.apply(c.value.position.inMilliseconds); }
      setState(() {});
    });
    setState(() => _vc = c);
  }

  Future<void> _addText() async {
    final ctrl = TextEditingController(text: 'Hello');
    final t = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add text'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Add'))],
      ),
    );
    if (t != null && t.isNotEmpty) _add(Layer.text(t, const Offset(60, 60)));
  }

  void _add(Layer l) => setState(() {
        _layers.add(l);
        _sel = _layers.length - 1;
      });

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
    child = applyFx(l.fx, child);
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
    return GestureDetector(
      onTap: () => setState(() => _sel = null),
      child: Container(
        color: Colors.black,
        child: ClipRect(
          child: Stack(fit: StackFit.expand, children: [
            if (vc != null)
              Center(child: AspectRatio(aspectRatio: vc.value.aspectRatio,
                  child: applyFx(_videoFx, VideoPlayer(vc))))
            else
              const Center(child: Text('Tap Add to import a video', style: TextStyle(color: Colors.white70))),
            for (int i = 0; i < _layers.length; i++) _layerView(i),
          ]),
        ),
      ),
    );
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