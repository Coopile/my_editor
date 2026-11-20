import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

const _bg = Color(0xFF0B1018);
const _panel = Color(0xFF151E2A);
const _violet = Color(0xFF79C8FF);
const _cyan = Color(0xFF79C8FF);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _showAppearanceSettings() async {
    const choices = <Color>[
      Color(0xFF79C8FF), Color(0xFF9DCAFF), Color(0xFF9BE7D5),
      Color(0xFFC4A7FF), Color(0xFFFFB6C8), Color(0xFFFFC77D),
    ];
    final selected = await showModalBottomSheet<Color>(
      context: context,
      backgroundColor: _panel,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Theme color', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Choose the accent used by EditShift controls.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 18),
            Wrap(spacing: 14, runSpacing: 14, children: [
              for (final color in choices)
                GestureDetector(
                  onTap: () => Navigator.pop(sheetContext, color),
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle,
                      border: Border.all(color: editShiftAccent.value == color ? Colors.white : Colors.white24, width: editShiftAccent.value == color ? 3 : 1),
                    ),
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );
    if (selected == null) return;
    editShiftAccent.value = selected;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('editshift.accent', selected.value);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('editshift.projects');
    if (raw != null) {
      try {
        _projects = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        var migrated = false;
        for (var i = 0; i < _projects.length; i++) {
          if (_projects[i]['id'] == null) {
            _projects[i]['id'] = 'legacy_project_$i';
            migrated = true;
          }
        }
        if (migrated) await _save();
      } catch (_) {
        _projects = [];
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('editshift.projects', jsonEncode(_projects));
  }

  Future<void> _createProject() async {
    final controller = TextEditingController(text: 'Untitled project');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _panel,
        title: const Text('Create a project', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Project name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final project = {
      'id': 'project_${DateTime.now().microsecondsSinceEpoch}',
      'name': name,
      'updated': DateTime.now().toIso8601String(),
    };
    setState(() => _projects.insert(0, project));
    await _save();
    _open(project);
  }

  Future<void> _delete(Map<String, dynamic> project) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _panel,
        title: const Text('Delete project?', style: TextStyle(color: Colors.white)),
        content: Text('“${project['name']}” will be removed from your EditShift project list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => _projects.remove(project));
    await _save();
  }

  void _open(Map<String, dynamic> project) {
    final id = (project['id'] ?? project['name']).toString();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Editor(
        projectName: project['name'] as String,
        projectId: id,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 18),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: _violet,
                            boxShadow: [BoxShadow(color: _violet.withOpacity(.28), blurRadius: 24)],
                          ),
                          child: const Icon(Icons.movie_creation_rounded, color: Colors.white, size: 27),
                        ),
                        const SizedBox(width: 13),
                        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('EditShift', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -.7)),
                          Text('MAKE EVERY FRAME MOVE.', style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 2.2, fontWeight: FontWeight.w700)),
                        ]),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Appearance',
                          onPressed: _showAppearanceSettings,
                          icon: const Icon(Icons.palette_outlined, color: Colors.white70, size: 22),
                        ),
                        IconButton(onPressed: _createProject, icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 27), tooltip: 'New project'),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                    child: Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: const Color(0xFF182638),
                        border: Border.all(color: Colors.white.withOpacity(.08)),
                      ),
                      child: LayoutBuilder(builder: (context, c) => Row(
                        children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('YOUR NEXT\nBIG EDIT STARTS HERE', style: TextStyle(color: Colors.white, fontSize: 27, height: 1.08, fontWeight: FontWeight.w900, letterSpacing: -.8)),
                            const SizedBox(height: 10),
                            const Text('Cut, animate, bend reality.', style: TextStyle(color: Colors.white60, fontSize: 13)),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: _violet, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15)),
                              onPressed: _createProject,
                              icon: const Icon(Icons.add),
                              label: const Text('Create project'),
                            ),
                          ])),
                          if (c.maxWidth > 420) const SizedBox(width: 20),
                          if (c.maxWidth > 420) Container(
                            width: 150, height: 128,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: Colors.white.withOpacity(.06)),
                            child: const Stack(alignment: Alignment.center, children: [
                              Icon(Icons.play_circle_fill_rounded, color: _cyan, size: 68),
                              Positioned(right: 16, top: 12, child: Icon(Icons.auto_awesome, color: _violet, size: 24)),
                              Positioned(left: 18, bottom: 14, child: Icon(Icons.graphic_eq, color: Colors.white54, size: 27)),
                            ]),
                          ),
                        ],
                      )),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
                    child: Row(children: [
                      const Text('Your projects', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 9),
                      Text('${_projects.length}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      const Spacer(),
                      TextButton.icon(onPressed: _createProject, icon: const Icon(Icons.add, size: 17), label: const Text('New project')),
                    ]),
                  ),
                ),
                if (_loading)
                  const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())))
                else if (_projects.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withOpacity(.06))),
                        child: const Column(children: [
                          Icon(Icons.video_library_outlined, color: Colors.white38, size: 42),
                          SizedBox(height: 12),
                          Text('No projects yet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                          SizedBox(height: 5),
                          Text('Create your first project to start editing.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ]),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(28, 4, 28, 40),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 260, mainAxisExtent: 190, crossAxisSpacing: 15, mainAxisSpacing: 15),
                      delegate: SliverChildBuilderDelegate((context, i) {
                        final p = _projects[i];
                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _open(p),
                          child: Container(
                            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(.07))),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Expanded(child: Container(
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                                  color: const Color(0xFF20364B),
                                ),
                                child: const Center(child: Icon(Icons.play_circle_outline_rounded, color: Colors.white70, size: 45)),
                              )),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(13, 10, 7, 9),
                                child: Row(children: [
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(p['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 3),
                                    const Text('EditShift project', style: TextStyle(color: Colors.white38, fontSize: 10)),
                                  ])),
                                  PopupMenuButton<String>(
                                    color: _panel,
                                    icon: const Icon(Icons.more_horiz, color: Colors.white60),
                                    onSelected: (v) { if (v == 'delete') _delete(p); },
                                    itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.redAccent, size: 18), SizedBox(width: 8), Text('Delete project')]))],
                                  ),
                                ]),
                              ),
                            ]),
                          ),
                        );
                      }, childCount: _projects.length),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
