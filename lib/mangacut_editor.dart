import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MangaCutEditor extends StatefulWidget {
  final String projectId;
  final String projectName;
  final List<String> layerNames;
  const MangaCutEditor({super.key, required this.projectId, required this.projectName, required this.layerNames});

  @override
  State<MangaCutEditor> createState() => _MangaCutEditorState();
}

class _RigBone {
  String id, name, parent;
  Offset a, b;
  double rotation;
  List<int> keys;
  _RigBone(this.id, this.name, this.a, this.b, {this.parent = '', this.rotation = 0, List<int>? keys}) : keys = keys ?? [];
  Map<String,dynamic> toJson() => {'id':id,'name':name,'parent':parent,'a':[a.dx,a.dy],'b':[b.dx,b.dy],'rotation':rotation,'keys':keys};
  factory _RigBone.fromJson(Map<String,dynamic> j) => _RigBone(j['id'],j['name'],Offset((j['a'][0] as num).toDouble(),(j['a'][1] as num).toDouble()),Offset((j['b'][0] as num).toDouble(),(j['b'][1] as num).toDouble()),parent:j['parent'] ?? '',rotation:(j['rotation'] as num?)?.toDouble() ?? 0,keys:(j['keys'] as List? ?? []).cast<int>());
}

class _EffectClip {
  String id, name, target;
  double start, end, strength;
  List<int> keys;
  _EffectClip(this.id,this.name,this.target,this.start,this.end,{this.strength=1,List<int>? keys}) : keys=keys ?? [];
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'target':target,'start':start,'end':end,'strength':strength,'keys':keys};
  factory _EffectClip.fromJson(Map<String,dynamic> j)=>_EffectClip(j['id'],j['name'],j['target'],(j['start'] as num).toDouble(),(j['end'] as num).toDouble(),strength:(j['strength'] as num?)?.toDouble() ?? 1,keys:(j['keys'] as List? ?? []).cast<int>());
}

class _MangaCutEditorState extends State<MangaCutEditor> {
  static const _bg=Color(0xFF101116), _panel=Color(0xFF1A1C24), _accent=Color(0xFF8A68FF);
  final List<_RigBone> _bones=[];
  final List<_EffectClip> _effects=[];
  final List<List<Offset>> _maskStrokes=[];
  final List<List<Offset>> _liquifyStrokes=[];
  int _tab=0, _selectedBone=-1, _selectedEffect=-1, _time=0;
  int _duration=6000;
  double _brush=28, _strength=.55;
  String _target='';
  bool _playing=false, _maskErase=false;
  int _dragBoneEnd=0;
  String get _storageKey=>'mangacut.workspace.${widget.projectId}';

  @override
  void initState(){super.initState();_target=widget.layerNames.isEmpty?'Layer 1':widget.layerNames.first;_load();}
  Future<void> _load() async {
    final p=await SharedPreferences.getInstance(); final raw=p.getString(_storageKey); if(raw==null)return;
    try { final j=jsonDecode(raw) as Map<String,dynamic>; if(!mounted)return; setState((){
      _bones..clear()..addAll((j['bones'] as List? ?? []).map((v)=>_RigBone.fromJson(Map<String,dynamic>.from(v))));
      _effects..clear()..addAll((j['effects'] as List? ?? []).map((v)=>_EffectClip.fromJson(Map<String,dynamic>.from(v))));
      _time=(j['time'] as num?)?.toInt() ?? 0;
    }); } catch(_){}
  }
  Future<void> _save() async { final p=await SharedPreferences.getInstance(); await p.setString(_storageKey,jsonEncode({'bones':_bones.map((b)=>b.toJson()).toList(),'effects':_effects.map((e)=>e.toJson()).toList(),'time':_time,'duration':_duration})); }
  void _changed(){setState((){});_save();}
  void _addBone(){
    final n=_bones.length+1; final x=.28+(n%3)*.16, y=.28+(n%4)*.11;
    _bones.add(_RigBone('bone_${DateTime.now().microsecondsSinceEpoch}','Bone $n',Offset(x,y),Offset(x+.12,y+.14),parent:_selectedBone>=0?_bones[_selectedBone].id:''));
    _selectedBone=_bones.length-1;_changed();
  }
  void _deleteBone(){if(_selectedBone<0||_selectedBone>=_bones.length)return;final id=_bones[_selectedBone].id;_bones.removeAt(_selectedBone);for(final b in _bones){if(b.parent==id)b.parent='';}_selectedBone=-1;_changed();}
  void _addEffect(String name){final e=_EffectClip('fx_${DateTime.now().microsecondsSinceEpoch}',name,_target,(_time/_duration).clamp(0.0,1.0),1);_effects.add(e);_selectedEffect=_effects.length-1;_changed();}
  void _addKey(){if(_selectedBone>=0){final b=_bones[_selectedBone];if(!b.keys.contains(_time))b.keys.add(_time);b.keys.sort();}if(_selectedEffect>=0){final e=_effects[_selectedEffect];if(!e.keys.contains(_time))e.keys.add(_time);e.keys.sort();}_changed();}
  void _timelineTap(Offset p,double width){setState(()=>_time=(p.dx/width*_duration).round().clamp(0,_duration));}
  @override
  Widget build(BuildContext context){
    return Scaffold(backgroundColor:_bg,appBar:AppBar(backgroundColor:_bg,title:const Text('MangaCut Animation Studio',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800)),actions:[IconButton(onPressed:_save,icon:const Icon(Icons.save_outlined),tooltip:'Save workspace')]),
      body:SafeArea(child:Column(children:[
        _topTabs(),
        Expanded(child:Row(children:[
          Expanded(flex:7,child:Column(children:[Expanded(child:_canvas()),_timeline()])),
          if(MediaQuery.of(context).size.width>700) SizedBox(width:280,child:_inspector()),
        ])),
        if(MediaQuery.of(context).size.width<=700) SizedBox(height:245,child:_inspector()),
      ]))));
  }
  Widget _topTabs()=>Container(color:_panel,height:52,child:ListView(scrollDirection:Axis.horizontal,children:[
    _tabButton('Rigging',Icons.account_tree,0),_tabButton('Mask',Icons.gesture,1),_tabButton('Liquify',Icons.blur_on,2),_tabButton('Animation',Icons.timeline,3),_tabButton('Effects',Icons.auto_awesome,4),
  ]));
  Widget _tabButton(String name,IconData icon,int index)=>Padding(padding:const EdgeInsets.symmetric(horizontal:5,vertical:6),child:ChoiceChip(selected:_tab==index,label:Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:16),const SizedBox(width:6),Text(name)]),onSelected:(_)=>setState(()=>_tab=index),selectedColor:_accent,backgroundColor:const Color(0xFF282A34)));
  Widget _canvas()=>Container(color:const Color(0xFF08090D),child:LayoutBuilder(builder:(context,c)=>GestureDetector(
    onTapDown:(d){
      if(_tab==0&&_bones.isNotEmpty){
        final p=Offset(d.localPosition.dx/c.maxWidth,d.localPosition.dy/c.maxHeight);
        var best=-1;var distance=double.infinity;
        for(var i=0;i<_bones.length;i++){final b=_bones[i];final da=(b.a-p).distance,db=(b.b-p).distance;final dd=math.min(da,db);if(dd<distance){distance=dd;best=i;_dragBoneEnd=da<db?0:1;}}
        if(best>=0)setState(()=>_selectedBone=best);
      }
    },
    onPanStart:(d){if(_tab==1||_tab==2){final p=Offset(d.localPosition.dx/c.maxWidth,d.localPosition.dy/c.maxHeight);setState(()=>((_tab==1)?_maskStrokes:_liquifyStrokes).add([p]));}else if(_tab==0&&_selectedBone>=0&&_selectedBone<_bones.length){final p=Offset(d.localPosition.dx/c.maxWidth,d.localPosition.dy/c.maxHeight);final b=_bones[_selectedBone];_dragBoneEnd=(b.a-p).distance<(b.b-p).distance?0:1;}},
    onPanUpdate:(d){if(_tab==1||_tab==2){final p=Offset((d.localPosition.dx/c.maxWidth).clamp(0.0,1.0),(d.localPosition.dy/c.maxHeight).clamp(0.0,1.0));setState(()=>((_tab==1)?_maskStrokes:_liquifyStrokes).last.add(p));}else if(_tab==0&&_selectedBone>=0&&_selectedBone<_bones.length){final p=Offset((d.localPosition.dx/c.maxWidth).clamp(0.0,1.0),(d.localPosition.dy/c.maxHeight).clamp(0.0,1.0));setState(()=>_dragBoneEnd==0?_bones[_selectedBone].a=p:_bones[_selectedBone].b=p);}},
    child:CustomPaint(size:Size.infinite,painter:_RigPainter(_bones,_selectedBone,_maskStrokes,_liquifyStrokes,_tab,_brush,_strength)),
  )));
  Widget _timeline()=>Container(height:145,color:_panel,padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[const Text('TIMELINE',style:TextStyle(fontSize:10,fontWeight:FontWeight.w900,letterSpacing:1)),const Spacer(),Text('${(_time/1000).toStringAsFixed(2)}s',style:const TextStyle(color:Colors.white60,fontSize:11)),IconButton(onPressed:_addKey,icon:const Icon(Icons.add_box_outlined,size:19),tooltip:'Add keyframe'),IconButton(onPressed:()=>setState(()=>_playing=!_playing),icon:Icon(_playing?Icons.pause:Icons.play_arrow,size:20))]),
    Expanded(child:LayoutBuilder(builder:(context,c)=>GestureDetector(onTapDown:(d)=>_timelineTap(d.localPosition,c.maxWidth),onHorizontalDragUpdate:(d)=>_timelineTap(d.localPosition,c.maxWidth),child:CustomPaint(size:Size.infinite,painter:_StudioTimelinePainter(_bones,_effects,_time,_duration))))),
  ]));
  Widget _inspector()=>Container(color:_panel,padding:const EdgeInsets.all(12),child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[const Expanded(child:Text('WORKSPACE TOOLS',style:TextStyle(fontWeight:FontWeight.w900,fontSize:11,letterSpacing:1))),IconButton(onPressed:_save,icon:const Icon(Icons.save,size:18))]),
    if(_tab==0)...[
      Row(children:[const Text('SKELETON',style:TextStyle(color:Colors.white60,fontSize:10)),const Spacer(),IconButton(onPressed:_addBone,icon:const Icon(Icons.add_circle,color:_accent)),IconButton(onPressed:_deleteBone,icon:const Icon(Icons.delete_outline,color:Colors.redAccent))]),
      for(int i=0;i<_bones.length;i++)ListTile(dense:true,selected:_selectedBone==i,leading:const Icon(Icons.account_tree,size:17),title:TextField(controller:TextEditingController(text:_bones[i].name),style:const TextStyle(fontSize:12),decoration:const InputDecoration(border:InputBorder.none,isDense:true),onSubmitted:(v){_bones[i].name=v;_changed();}),subtitle:Text(_bones[i].parent.isEmpty?'Root bone':'Child bone',style:const TextStyle(fontSize:9,color:Colors.white38)),onTap:()=>setState(()=>_selectedBone=i),trailing:IconButton(icon:const Icon(Icons.close,size:16),onPressed:()=>setState((){_selectedBone=i;_deleteBone();}))),
      if(_selectedBone>=0&&_selectedBone<_bones.length)DropdownButtonFormField<String>(value:_bones[_selectedBone].parent.isEmpty?null:_bones[_selectedBone].parent,decoration:const InputDecoration(labelText:'Parent bone'),items:[const DropdownMenuItem(value:'',child:Text('No parent')),for(final b in _bones.where((b)=>b.id!=_bones[_selectedBone].id))DropdownMenuItem(value:b.id,child:Text(b.name))],onChanged:(v){_bones[_selectedBone].parent=v??'';_changed();}),
    ] else if(_tab==1)...[
      const Text('Paint a mask directly on the canvas. Mask strokes are stored per workspace.',style:TextStyle(fontSize:11,color:Colors.white60)),SwitchListTile(value:_maskErase,onChanged:(v)=>setState(()=>_maskErase=v),title:const Text('Erase mask',style:TextStyle(fontSize:12))),_slider('Brush size',_brush,4,100,(v)=>setState(()=>_brush=v)),TextButton.icon(onPressed:()=>setState(()=>_maskStrokes.clear()),icon:const Icon(Icons.delete_outline),label:const Text('Clear mask')),
    ] else if(_tab==2)...[
      const Text('Liquify brush · drag on the canvas to deform the preview mesh.',style:TextStyle(fontSize:11,color:Colors.white60)),_slider('Brush size',_brush,8,120,(v)=>setState(()=>_brush=v)),_slider('Strength',_strength,.05,1,(v)=>setState(()=>_strength=v)),TextButton.icon(onPressed:()=>setState(()=>_liquifyStrokes.clear()),icon:const Icon(Icons.refresh),label:const Text('Reset liquify')),
    ] else if(_tab==3)...[
      const Text('Select a bone, move its joints on the canvas, then add keyframes on the timeline.',style:TextStyle(fontSize:11,color:Colors.white60)),if(_selectedBone>=0&&_selectedBone<_bones.length)_slider('Rotation',_bones[_selectedBone].rotation,-math.pi,math.pi,(v){_bones[_selectedBone].rotation=v;_changed();}),FilledButton.icon(onPressed:_addKey,icon:const Icon(Icons.key),label:const Text('Keyframe selected')),
    ] else ...[
      const Text('Add an effect clip and choose which layer receives it.',style:TextStyle(fontSize:11,color:Colors.white60)),
      DropdownButtonFormField<String>(value:_target,decoration:const InputDecoration(labelText:'Target layer'),items:[for(final n in (widget.layerNames.isEmpty?['Layer 1']:widget.layerNames))DropdownMenuItem(value:n,child:Text(n,overflow:TextOverflow.ellipsis))],onChanged:(v)=>setState(()=>_target=v??_target)),
      Wrap(spacing:6,children:[for(final name in ['Shake','Pulse','Bounce','Oscillate','Spin','Swing','Wobble','Impact','Drift','Twitch','Liquify','Wind'])ActionChip(label:Text(name),onPressed:()=>_addEffect(name))]),
      for(int i=0;i<_effects.length;i++)ListTile(dense:true,selected:_selectedEffect==i,title:Text(_effects[i].name,style:const TextStyle(fontSize:12)),subtitle:Text('Target: ${_effects[i].target}',style:const TextStyle(fontSize:9)),onTap:()=>setState(()=>_selectedEffect=i),trailing:IconButton(onPressed:(){_effects.removeAt(i);_selectedEffect=-1;_changed();},icon:const Icon(Icons.delete_outline,size:17))),
      if(_selectedEffect>=0&&_selectedEffect<_effects.length)_slider('Effect strength',_effects[_selectedEffect].strength,0,2,(v){_effects[_selectedEffect].strength=v;_changed();}),
    ],
  ])));
  Widget _slider(String title,double value,double min,double max,ValueChanged<double> change)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('$title  ${value.toStringAsFixed(2)}',style:const TextStyle(fontSize:11,color:Colors.white70)),Slider(value:value.clamp(min,max),min:min,max:max,onChanged:change,activeColor:_accent)]);
}

class _RigPainter extends CustomPainter {
  final List<_RigBone> bones; final int selected,tab; final List<List<Offset>> masks,liquify; final double brush,strength;
  _RigPainter(this.bones,this.selected,this.masks,this.liquify,this.tab,this.brush,this.strength);
  @override void paint(Canvas c,Size s){
    final bg=Paint()..color=const Color(0xFF171A22);c.drawRect(Offset.zero&s,bg);
    final grid=Paint()..color=Colors.white.withOpacity(.045)..strokeWidth=1;
    for(double x=0;x<s.width;x+=24)c.drawLine(Offset(x,0),Offset(x,s.height),grid);
    for(double y=0;y<s.height;y+=24)c.drawLine(Offset(0,y),Offset(s.width,y),grid);
    final center=Offset(s.width*.5,s.height*.5);
    c.drawOval(Rect.fromCenter(center:center,width:s.width*.28,height:s.height*.48),Paint()..color=const Color(0xFF29364A));
    c.drawCircle(center.translate(0,-s.height*.31),s.width*.065,Paint()..color=const Color(0xFF52647B));
    for(final stroke in masks){final p=Paint()..color=Colors.white.withOpacity(.8)..strokeWidth=brush..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;for(int i=1;i<stroke.length;i++)c.drawLine(Offset(stroke[i-1].dx*s.width,stroke[i-1].dy*s.height),Offset(stroke[i].dx*s.width,stroke[i].dy*s.height),p);}
    for(final stroke in liquify){final p=Paint()..color=const Color(0xFFB78BFF).withOpacity(.8)..strokeWidth=2..style=PaintingStyle.stroke;for(int i=1;i<stroke.length;i++)c.drawLine(Offset(stroke[i-1].dx*s.width,stroke[i-1].dy*s.height),Offset(stroke[i].dx*s.width,stroke[i].dy*s.height),p);}
    for(int i=0;i<bones.length;i++){final b=bones[i],a=Offset(b.a.dx*s.width,b.a.dy*s.height),z=Offset(b.b.dx*s.width,b.b.dy*s.height);final p=Paint()..color=(i==selected?const Color(0xFFFFD76A):const Color(0xFF71D8FF))..strokeWidth=(i==selected?5.0:3.0)..strokeCap=StrokeCap.round;c.drawLine(a,z,p);c.drawCircle(a,6,Paint()..color=Colors.white);c.drawCircle(z,7,Paint()..color=p.color);}
    if(tab==2){final p=Paint()..color=const Color(0xFFB78BFF).withOpacity(.12)..style=PaintingStyle.stroke..strokeWidth=1;for(int x=0;x<8;x++)for(int y=0;y<6;y++){final dx=s.width*x/7,dy=s.height*y/5;c.drawCircle(Offset(dx,dy),2,p);}}
  }
  @override bool shouldRepaint(covariant _RigPainter old)=>true;
}
class _StudioTimelinePainter extends CustomPainter{
  final List<_RigBone> bones;final List<_EffectClip> effects;final int time,duration;
  _StudioTimelinePainter(this.bones,this.effects,this.time,this.duration);
  @override void paint(Canvas c,Size s){
    final row=math.max(22.0,s.height/(bones.length+effects.length+1));final line=Paint()..color=Colors.white12;
    for(int i=0;i<bones.length+effects.length+1;i++)c.drawLine(Offset(0,row*i),Offset(s.width,row*i),line);
    var r=0;for(final b in bones){final y=row*(r+.5);c.drawTextMarker(Offset(4,y-6),b.name,Colors.white70);for(final k in b.keys){final x=k/duration*s.width;c.drawCircle(Offset(x,y),4,Paint()..color=const Color(0xFFFFD76A));}r++;}
    for(final e in effects){final y=row*(r+.5),x=e.start*s.width,w=(e.end-e.start)*s.width;c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y-8,w.clamp(0.0,s.width),16),const Radius.circular(3)),Paint()..color=const Color(0xFF7655E8));for(final k in e.keys)c.drawCircle(Offset(k/duration*s.width,y),3,Paint()..color=Colors.white);r++;}
    final x=time/duration*s.width;c.drawLine(Offset(x,0),Offset(x,s.height),Paint()..color=Colors.white..strokeWidth=2);
  }
  @override bool shouldRepaint(covariant _StudioTimelinePainter old)=>true;
}
extension on Canvas{void drawTextMarker(Offset p,String text,Color color){final tp=TextPainter(text:TextSpan(text:text,style:TextStyle(color:color,fontSize:9)),textDirection:TextDirection.ltr)..layout(maxWidth:110);tp.paint(this,p);}}
