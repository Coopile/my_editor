import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class MangaCutEditor extends StatefulWidget {
  final String projectId;
  final String projectName;
  final List<String> layerNames;
  final ValueChanged<List<MangaCutEffectClip>>? onApplyEffects;
  final void Function(String target,String imagePath)? onApplyImage;
  const MangaCutEditor({super.key, required this.projectId, required this.projectName, required this.layerNames, this.onApplyEffects, this.onApplyImage});

  @override
  State<MangaCutEditor> createState() => _MangaCutEditorState();
}

class _RigBone {
  String id, name, parent;
  Offset a, b;
  double rotation;
  List<int> keys;
  final Map<int,double> rotationKeys;
  final Map<int,String> easingKeys;
  final Map<int,double> overshootKeys;
  _RigBone(this.id, this.name, this.a, this.b, {this.parent = '', this.rotation = 0, List<int>? keys, Map<int,double>? rotationKeys, Map<int,String>? easingKeys, Map<int,double>? overshootKeys}) : keys = keys ?? [], rotationKeys = rotationKeys ?? {}, easingKeys = easingKeys ?? {}, overshootKeys = overshootKeys ?? {};
  Map<String,dynamic> toJson() => {'id':id,'name':name,'parent':parent,'a':[a.dx,a.dy],'b':[b.dx,b.dy],'rotation':rotation,'keys':keys,'rotationKeys':rotationKeys.map((k,v)=>MapEntry(k.toString(),v)),'easingKeys':easingKeys.map((k,v)=>MapEntry(k.toString(),v)),'overshootKeys':overshootKeys.map((k,v)=>MapEntry(k.toString(),v))};
  factory _RigBone.fromJson(Map<String,dynamic> j) => _RigBone(j['id'],j['name'],Offset((j['a'][0] as num).toDouble(),(j['a'][1] as num).toDouble()),Offset((j['b'][0] as num).toDouble(),(j['b'][1] as num).toDouble()),parent:j['parent'] ?? '',rotation:(j['rotation'] as num?)?.toDouble() ?? 0,keys:(j['keys'] as List? ?? []).cast<int>(),rotationKeys:(j['rotationKeys'] as Map? ?? {}).map((k,v)=>MapEntry(int.parse(k.toString()),(v as num).toDouble())),easingKeys:(j['easingKeys'] as Map? ?? {}).map((k,v)=>MapEntry(int.parse(k.toString()),v.toString())),overshootKeys:(j['overshootKeys'] as Map? ?? {}).map((k,v)=>MapEntry(int.parse(k.toString()),(v as num).toDouble())));
}

class MangaCutEffectClip {
  String id, name, target;
  double start, end, strength;
  List<int> keys;
  MangaCutEffectClip(this.id,this.name,this.target,this.start,this.end,{this.strength=1,List<int>? keys}) : keys=keys ?? [];
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'target':target,'start':start,'end':end,'strength':strength,'keys':keys};
  factory MangaCutEffectClip.fromJson(Map<String,dynamic> j)=>MangaCutEffectClip(j['id'],j['name'],j['target'],(j['start'] as num).toDouble(),(j['end'] as num).toDouble(),strength:(j['strength'] as num?)?.toDouble() ?? 1,keys:(j['keys'] as List? ?? []).cast<int>());
}

class _MangaCutEditorState extends State<MangaCutEditor> {
  static const _bg=Color(0xFF101116), _panel=Color(0xFF1A1C24), _accent=Color(0xFF8A68FF);
  final List<_RigBone> _bones=[];
  final List<MangaCutEffectClip> _effects=[];
  final List<List<Offset>> _maskStrokes=[];
  final List<List<Offset>> _liquifyStrokes=[];
  ui.Image? _sourceImage;
  String? _sourceImagePath;
  int _tab=0, _selectedBone=-1, _selectedEffect=-1, _time=0;
  int _duration=6000;
  double _brush=28, _strength=.55;
  String _target='';
  bool _playing=false, _maskErase=false;
  Timer? _playTimer;
  int _dragBoneEnd=0;
  String _timelineDragKind='';
  int _timelineDragIndex=-1;
  int _timelineDragKey=-1;
  double _timelineDragOffset=0;
  String get _storageKey=>'mangacut.workspace.${widget.projectId}';

  @override
  void initState(){super.initState();_target=widget.layerNames.isEmpty?'Layer 1':widget.layerNames.first;_load();}
  Future<void> _load() async {
    final p=await SharedPreferences.getInstance(); final raw=p.getString(_storageKey); if(raw==null)return;
    try { final j=jsonDecode(raw) as Map<String,dynamic>; if(!mounted)return; setState((){
      _bones..clear()..addAll((j['bones'] as List? ?? []).map((v)=>_RigBone.fromJson(Map<String,dynamic>.from(v))));
      _effects..clear()..addAll((j['effects'] as List? ?? []).map((v)=>MangaCutEffectClip.fromJson(Map<String,dynamic>.from(v))));
      _time=(j['time'] as num?)?.toInt() ?? 0;
      _sourceImagePath=j['sourceImagePath'] as String?;
      _maskStrokes..clear()..addAll((j['maskStrokes'] as List? ?? []).map((stroke)=>(stroke as List).map((p)=>Offset((p[0] as num).toDouble(),(p[1] as num).toDouble())).toList()));
      _liquifyStrokes..clear()..addAll((j['liquifyStrokes'] as List? ?? []).map((stroke)=>(stroke as List).map((p)=>Offset((p[0] as num).toDouble(),(p[1] as num).toDouble())).toList()));
    }); if(_sourceImagePath!=null){try{final bytes=await File(_sourceImagePath!).readAsBytes();final decoded=await _decodeImage(bytes);if(mounted)setState(()=>_sourceImage=decoded);}catch(_){}} } catch(_){}
  }
  Future<ui.Image> _decodeImage(Uint8List bytes) async { final codec=await ui.instantiateImageCodec(bytes); final frame=await codec.getNextFrame(); return frame.image; }
  Future<void> _pickSourceImage() async { final picked=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:95); if(picked==null)return; final docs=await getApplicationDocumentsDirectory(); final ext=picked.path.contains('.')?picked.path.substring(picked.path.lastIndexOf('.')):'.png'; final saved=await File(picked.path).copy('${docs.path}/manga_${widget.projectId}$ext'); final bytes=await saved.readAsBytes(); final decoded=await _decodeImage(bytes); if(!mounted)return; setState((){_sourceImage=decoded;_sourceImagePath=saved.path;_maskStrokes.clear();_liquifyStrokes.clear();}); await _save(); }
  Future<void> _inpaintMaskedArea() async {
    final image=_sourceImage;
    if(image==null||_maskStrokes.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Import an image and paint the area to repair first.')));
      return;
    }
    final data=await image.toByteData(format:ui.ImageByteFormat.rawRgba);
    if(data==null)return;
    final width=image.width,height=image.height,count=width*height;
    final pixels=Uint8List.fromList(data.buffer.asUint8List());
    final mask=Uint8List(count),known=Uint8List(count);
    final radius=math.max(1.0,_brush*math.min(width,height)/500.0);
    void markDisk(double cx,double cy){
      final left=math.max(0,(cx-radius).floor()).toInt(),right=math.min(width-1,(cx+radius).ceil()).toInt();
      final top=math.max(0,(cy-radius).floor()).toInt(),bottom=math.min(height-1,(cy+radius).ceil()).toInt();
      for(var y=top;y<=bottom;y++)for(var x=left;x<=right;x++){
        final dx=x-cx,dy=y-cy;
        if(dx*dx+dy*dy<=radius*radius)mask[y*width+x]=1;
      }
    }
    for(final stroke in _maskStrokes){
      if(stroke.length==1){markDisk(stroke.first.dx*width,stroke.first.dy*height);continue;}
      for(var i=1;i<stroke.length;i++){
        final a=stroke[i-1],b=stroke[i];
        final ax=a.dx*width,ay=a.dy*height,bx=b.dx*width,by=b.dy*height;
        final distance=math.sqrt((bx-ax)*(bx-ax)+(by-ay)*(by-ay));
        final steps=math.max(1,(distance/(radius*.4)).ceil()).toInt();
        for(var step=0;step<=steps;step++){
          final t=step/steps;markDisk(ax+(bx-ax)*t,ay+(by-ay)*t);
        }
      }
    }
    for(var i=0;i<count;i++)known[i]=mask[i]==0?1:0;
    final queue=<int>[];
    for(var y=0;y<height;y++)for(var x=0;x<width;x++){
      final index=y*width+x;
      if(known[index]==0)continue;
      if((x>0&&mask[index-1]==1)||(x+1<width&&mask[index+1]==1)||(y>0&&mask[index-width]==1)||(y+1<height&&mask[index+width]==1))queue.add(index);
    }
    var head=0;
    while(head<queue.length){
      final index=queue[head++],x=index%width,y=index~/width;
      void fillNeighbor(int target){
        if(mask[target]==0||known[target]==1)return;
        final tx=target%width,ty=target~/width;
        var r=0,g=0,b=0,a=0,n=0;
        void addKnown(int neighbor){
          if(known[neighbor]==0)return;
          final offset=neighbor*4;
          r+=pixels[offset];g+=pixels[offset+1];b+=pixels[offset+2];a+=pixels[offset+3];n++;
        }
        if(tx>0)addKnown(target-1);
        if(tx+1<width)addKnown(target+1);
        if(ty>0)addKnown(target-width);
        if(ty+1<height)addKnown(target+width);
        if(n==0)return;
        final offset=target*4;
        pixels[offset]=(r/n).round();pixels[offset+1]=(g/n).round();pixels[offset+2]=(b/n).round();pixels[offset+3]=(a/n).round();
        known[target]=1;
        queue.add(target);
      }
      if(x>0)fillNeighbor(index-1);
      if(x+1<width)fillNeighbor(index+1);
      if(y>0)fillNeighbor(index-width);
      if(y+1<height)fillNeighbor(index+width);
    }
    final completer=Completer<ui.Image>();
    ui.decodeImageFromPixels(pixels,width,height,ui.PixelFormat.rgba8888,completer.complete);
    final repaired=await completer.future;
    final png=await repaired.toByteData(format:ui.ImageByteFormat.png);
    if(png!=null&&_sourceImagePath!=null)await File(_sourceImagePath!).writeAsBytes(png.buffer.asUint8List(),flush:true);
    if(!mounted){repaired.dispose();return;}
    setState((){
      _sourceImage?.dispose();
      _sourceImage=repaired;
      _maskStrokes.clear();
    });
    await _save();
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Quick inpaint completed. This uses edge-colour propagation, so complex backgrounds may need manual cleanup.')));
  }

  Future<void> _applyCompositeToMainLayer() async {
    if(_sourceImage==null||widget.onApplyImage==null){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Import an image before applying a composite.')));
      return;
    }
    final image=_sourceImage!;
    final recorder=ui.PictureRecorder();
    final canvas=Canvas(recorder);
    final outputSize=Size(image.width.toDouble(),image.height.toDouble());
    final painter=_RigPainter(_bones,_selectedBone,_maskStrokes,_liquifyStrokes,_tab,_brush*image.width/500.0,_strength,image,_time,_duration,_effects);
    painter.paintComposite(canvas,outputSize);
    final picture=recorder.endRecording();
    final rendered=await picture.toImage(image.width,image.height);
    picture.dispose();
    final png=await rendered.toByteData(format:ui.ImageByteFormat.png);
    rendered.dispose();
    if(png==null||!mounted)return;
    final docs=await getApplicationDocumentsDirectory();
    final output=File('${docs.path}/mangacut_${widget.projectId}_composite.png');
    await output.writeAsBytes(png.buffer.asUint8List(),flush:true);
    widget.onApplyImage!(_target,output.path);
    if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Current frame composite applied to the main project. Animation is not baked into this still image.')));
      Navigator.of(context).pop();
    }
  }

  Future<void> _save() async { final p=await SharedPreferences.getInstance(); await p.setString(_storageKey,jsonEncode({'bones':_bones.map((b)=>b.toJson()).toList(),'effects':_effects.map((e)=>e.toJson()).toList(),'time':_time,'duration':_duration,'sourceImagePath':_sourceImagePath,'maskStrokes':_maskStrokes.map((stroke)=>stroke.map((p)=>[p.dx,p.dy]).toList()).toList(),'liquifyStrokes':_liquifyStrokes.map((stroke)=>stroke.map((p)=>[p.dx,p.dy]).toList()).toList()})); }
  void _changed(){setState((){});_save();}
  void _addBone(){
    final n=_bones.length+1; final x=.28+(n%3)*.16, y=.28+(n%4)*.11;
    _bones.add(_RigBone('bone_${DateTime.now().microsecondsSinceEpoch}','Bone $n',Offset(x,y),Offset(x+.12,y+.14),parent:_selectedBone>=0?_bones[_selectedBone].id:''));
    _selectedBone=_bones.length-1;_changed();
  }
  void _deleteBone(){if(_selectedBone<0||_selectedBone>=_bones.length)return;final id=_bones[_selectedBone].id;_bones.removeAt(_selectedBone);for(final b in _bones){if(b.parent==id)b.parent='';}_selectedBone=-1;_changed();}
  void _addEffect(String name){final e=MangaCutEffectClip('fx_${DateTime.now().microsecondsSinceEpoch}',name,_target,(_time/_duration).clamp(0.0,1.0),1);_effects.add(e);_selectedEffect=_effects.length-1;_changed();}
  void _addKey(){if(_selectedBone>=0){final b=_bones[_selectedBone];if(!b.keys.contains(_time))b.keys.add(_time);b.keys.sort();b.rotationKeys[_time]=b.rotation;}if(_selectedEffect>=0){final e=_effects[_selectedEffect];if(!e.keys.contains(_time))e.keys.add(_time);e.keys.sort();}_changed();}
  double _easeProgress(_RigBone bone,int segmentStart,double t){
    final mode=bone.easingKeys[segmentStart]??'Linear';
    var value=t;
    switch(mode){
      case 'Ease In': value=t*t*t; break;
      case 'Ease Out': value=1-math.pow(1-t,3).toDouble(); break;
      case 'Ease In Out': value=t<.5?4*t*t*t:1-math.pow(-2*t+2,3).toDouble()/2; break;
      case 'Overshoot':
        final amount=bone.overshootKeys[segmentStart]??.18;
        final c1=1.70158*(amount/.18);final c3=c1+1;
        value=1+c3*math.pow(t-1,3).toDouble()+c1*math.pow(t-1,2).toDouble();
        break;
      default: value=t;
    }
    return value;
  }
  double _rotationAt(_RigBone bone,int time){
    final frames=bone.rotationKeys.entries.toList()..sort((a,b)=>a.key.compareTo(b.key));
    if(frames.isEmpty)return bone.rotation;
    if(time<=frames.first.key)return frames.first.value;
    if(time>=frames.last.key)return frames.last.value;
    for(var i=1;i<frames.length;i++){
      if(time<=frames[i].key){
        final a=frames[i-1],b=frames[i];
        final t=(time-a.key)/(b.key-a.key);
        final eased=_easeProgress(bone,a.key,t);
        return a.value+(b.value-a.value)*eased;
      }
    }
    return bone.rotation;
  }
  Future<void> _openGraphEditor() async {
    if(_selectedBone<0||_selectedBone>=_bones.length)return;
    final bone=_bones[_selectedBone];
    final keys=bone.rotationKeys.keys.toList()..sort();
    if(keys.length<2){if(!bone.rotationKeys.containsKey(_time))_addKey();if(bone.rotationKeys.length<2){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Add at least two bone keyframes to edit a motion curve.')));return;}}
    final starts=bone.rotationKeys.keys.where((k)=>k<=_time).toList()..sort();
    final segment=starts.isEmpty?bone.rotationKeys.keys.reduce((a,b)=>a<b?a:b):starts.last;
    var mode=bone.easingKeys[segment]??'Linear';
    var amount=bone.overshootKeys[segment]??.18;
    await showDialog<void>(context:context,builder:(dialogContext)=>StatefulBuilder(builder:(context,setDialogState)=>AlertDialog(
      backgroundColor:_panel,
      title:Text('Motion curve · ${bone.name}'),
      content:SizedBox(width:360,child:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<String>(value:mode,decoration:const InputDecoration(labelText:'Interpolation'),items:const ['Linear','Ease In','Ease Out','Ease In Out','Overshoot'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setDialogState(()=>mode=v??mode)),
        if(mode=='Overshoot')Column(children:[const SizedBox(height:12),Text('Overshoot amount · ${amount.toStringAsFixed(2)}'),Slider(value:amount,min:0,max:.6,onChanged:(v)=>setDialogState(()=>amount=v))]),
        const SizedBox(height:12),SizedBox(height:110,width:300,child:CustomPaint(painter:_CurvePreviewPainter(mode,amount))),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext),child:const Text('Cancel')),FilledButton(onPressed:(){bone.easingKeys[segment]=mode;bone.overshootKeys[segment]=amount;_changed();Navigator.pop(dialogContext);},child:const Text('Apply curve'))],
    )));
  }
  void _togglePlayback(){if(_playing){_playTimer?.cancel();_playTimer=null;setState(()=>_playing=false);_save();return;}if(_time>=_duration)_time=0;setState(()=>_playing=true);_playTimer=Timer.periodic(const Duration(milliseconds:16),(timer){if(!mounted){timer.cancel();return;}final next=_time+16;if(next>=_duration){_time=_duration;timer.cancel();_playTimer=null;_playing=false;}else{_time=next;}for(final bone in _bones){bone.rotation=_rotationAt(bone,_time);}setState((){});});}
  @override void dispose(){_playTimer?.cancel();_sourceImage?.dispose();super.dispose();}
  double _timelineTimeAt(double x,double width)=>((x/width).clamp(0.0,1.0)*_duration).toDouble();
  void _timelinePanStart(Offset p,Size size){
    final row=math.max(22.0,size.height/(_bones.length+_effects.length+1)).toDouble();
    final rowIndex=(p.dy/row).floor();
    _timelineDragKind='';_timelineDragIndex=-1;_timelineDragKey=-1;
    if(rowIndex>=0&&rowIndex<_bones.length){
      final bone=_bones[rowIndex];
      final keys=bone.rotationKeys.isEmpty?bone.keys:bone.rotationKeys.keys.toList();
      for(final key in keys){
        final keyX=key/_duration*size.width;
        if((p.dx-keyX).abs()<13){_timelineDragKind='boneKey';_timelineDragIndex=rowIndex;_timelineDragKey=key;_selectedBone=rowIndex;break;}
      }
    }else if(rowIndex>=_bones.length&&rowIndex<_bones.length+_effects.length){
      final index=rowIndex-_bones.length;final effect=_effects[index];
      final left=effect.start*size.width,right=effect.end*size.width;
      if((p.dx-left).abs()<12){_timelineDragKind='effectStart';_timelineDragIndex=index;}
      else if((p.dx-right).abs()<12){_timelineDragKind='effectEnd';_timelineDragIndex=index;}
      else if(p.dx>=left&&p.dx<=right){_timelineDragKind='effectMove';_timelineDragIndex=index;_timelineDragOffset=p.dx-left;}
    }
    if(_timelineDragKind.isEmpty){_timelineDragKind='scrub';_time=_timelineTimeAt(p.dx,size.width).round();}
    setState((){});
  }
  void _timelinePanUpdate(Offset p,Size size){
    final t=_timelineTimeAt(p.dx,size.width).round().clamp(0,_duration).toInt();
    setState((){
      if(_timelineDragKind=='boneKey'&&_timelineDragIndex>=0&&_timelineDragIndex<_bones.length){
        final bone=_bones[_timelineDragIndex];final old=_timelineDragKey;
        if(bone.rotationKeys.containsKey(old)){final value=bone.rotationKeys.remove(old)!;bone.rotationKeys[t]=value;}
        final at=bone.keys.indexOf(old);if(at>=0)bone.keys[at]=t;
        bone.keys.sort();_timelineDragKey=t;
      }else if(_timelineDragIndex>=0&&_timelineDragIndex<_effects.length){
        final effect=_effects[_timelineDragIndex];final normalized=(t/_duration).clamp(0.0,1.0);
        if(_timelineDragKind=='effectStart')effect.start=normalized.clamp(0.0,effect.end-.01).toDouble();
        if(_timelineDragKind=='effectEnd')effect.end=normalized.clamp(effect.start+.01,1.0).toDouble();
        if(_timelineDragKind=='effectMove'){
          final width=(effect.end-effect.start);final start=((p.dx-_timelineDragOffset)/size.width).clamp(0.0,1.0-width).toDouble();
          effect.start=start;effect.end=start+width;
        }
      }else if(_timelineDragKind=='scrub'){_time=t;for(final bone in _bones){bone.rotation=_rotationAt(bone,_time);}}
    });
    _save();
  }
  void _timelinePanEnd(){_timelineDragKind='';_timelineDragIndex=-1;_timelineDragKey=-1;_save();}
  @override
  Widget build(BuildContext context){
    return Scaffold(backgroundColor:_bg,appBar:AppBar(backgroundColor:_bg,title:const Text('MangaCut Animation Studio',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800)),actions:[IconButton(onPressed:_save,icon:const Icon(Icons.save_outlined),tooltip:'Save workspace'),IconButton(onPressed:(){widget.onApplyEffects?.call(List.unmodifiable(_effects));},icon:const Icon(Icons.auto_awesome),tooltip:'Apply effects to main editor'),IconButton(onPressed:_applyCompositeToMainLayer,icon:const Icon(Icons.layers_outlined),tooltip:'Apply current image composite')]),
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
    onPanUpdate:(d){if(_tab==1||_tab==2){final p=Offset((d.localPosition.dx/c.maxWidth).clamp(0.0,1.0),(d.localPosition.dy/c.maxHeight).clamp(0.0,1.0));if(_tab==1&&_maskErase){
      final radius=(_brush/math.max(1.0,math.min(c.maxWidth,c.maxHeight))).clamp(.002,.5).toDouble();
      setState((){
        final remaining=<List<Offset>>[];
        for(final stroke in _maskStrokes){
          if(stroke.isEmpty)continue;
          final sampled=<Offset>[stroke.first];
          for(var i=1;i<stroke.length;i++){
            final from=stroke[i-1],to=stroke[i];final distance=(to-from).distance;
            final steps=math.max(1,(distance/(radius*.35)).ceil());
            for(var step=1;step<=steps;step++){sampled.add(Offset.lerp(from,to,step/steps)!);}
          }
          var segment=<Offset>[];
          for(final point in sampled){
            if((point-p).distance<=radius){
              if(segment.length>=2)remaining.add(segment);
              segment=<Offset>[];
            }else{segment.add(point);}
          }
          if(segment.length>=2)remaining.add(segment);
        }
        _maskStrokes..clear()..addAll(remaining);
      });
    }else{setState(()=>((_tab==1)?_maskStrokes:_liquifyStrokes).last.add(p));}_save();}else if(_tab==0&&_selectedBone>=0&&_selectedBone<_bones.length){final p=Offset((d.localPosition.dx/c.maxWidth).clamp(0.0,1.0),(d.localPosition.dy/c.maxHeight).clamp(0.0,1.0));setState(()=>_dragBoneEnd==0?_bones[_selectedBone].a=p:_bones[_selectedBone].b=p);}},
    child:CustomPaint(size:Size.infinite,painter:_RigPainter(_bones,_selectedBone,_maskStrokes,_liquifyStrokes,_tab,_brush,_strength,_sourceImage,_time,_duration,_effects)),
  )));
  Widget _timeline()=>Container(height:145,color:_panel,padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[const Text('TIMELINE',style:TextStyle(fontSize:10,fontWeight:FontWeight.w900,letterSpacing:1)),const Spacer(),Text('${(_time/1000).toStringAsFixed(2)}s',style:const TextStyle(color:Colors.white60,fontSize:11)),IconButton(onPressed:_addKey,icon:const Icon(Icons.add_box_outlined,size:19),tooltip:'Add keyframe'),IconButton(onPressed:_togglePlayback,icon:Icon(_playing?Icons.pause:Icons.play_arrow,size:20))]),
    Expanded(child:LayoutBuilder(builder:(context,c)=>GestureDetector(onPanStart:(d)=>_timelinePanStart(d.localPosition,Size(c.maxWidth,c.maxHeight)),onPanUpdate:(d)=>_timelinePanUpdate(d.localPosition,Size(c.maxWidth,c.maxHeight)),onPanEnd:(_)=>_timelinePanEnd(),child:CustomPaint(size:Size.infinite,painter:_StudioTimelinePainter(_bones,_effects,_time,_duration))))),
  ]));
  Widget _inspector()=>Container(color:_panel,padding:const EdgeInsets.all(12),child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[const Expanded(child:Text('WORKSPACE TOOLS',style:TextStyle(fontWeight:FontWeight.w900,fontSize:11,letterSpacing:1))),IconButton(onPressed:_pickSourceImage,icon:const Icon(Icons.add_photo_alternate_outlined,size:18),tooltip:'Import image'),IconButton(onPressed:_save,icon:const Icon(Icons.save,size:18))]),
    if(_tab==0)...[
      Row(children:[const Text('SKELETON',style:TextStyle(color:Colors.white60,fontSize:10)),const Spacer(),IconButton(onPressed:_addBone,icon:const Icon(Icons.add_circle,color:_accent)),IconButton(onPressed:_deleteBone,icon:const Icon(Icons.delete_outline,color:Colors.redAccent))]),
      for(int i=0;i<_bones.length;i++)ListTile(dense:true,selected:_selectedBone==i,leading:const Icon(Icons.account_tree,size:17),title:TextField(controller:TextEditingController(text:_bones[i].name),style:const TextStyle(fontSize:12),decoration:const InputDecoration(border:InputBorder.none,isDense:true),onSubmitted:(v){_bones[i].name=v;_changed();}),subtitle:Text(_bones[i].parent.isEmpty?'Root bone':'Child bone',style:const TextStyle(fontSize:9,color:Colors.white38)),onTap:()=>setState(()=>_selectedBone=i),trailing:IconButton(icon:const Icon(Icons.close,size:16),onPressed:()=>setState((){_selectedBone=i;_deleteBone();}))),
      if(_selectedBone>=0&&_selectedBone<_bones.length)DropdownButtonFormField<String>(value:_bones[_selectedBone].parent.isEmpty?null:_bones[_selectedBone].parent,decoration:const InputDecoration(labelText:'Parent bone'),items:[const DropdownMenuItem(value:'',child:Text('No parent')),for(final b in _bones.where((b)=>b.id!=_bones[_selectedBone].id))DropdownMenuItem(value:b.id,child:Text(b.name))],onChanged:(v){_bones[_selectedBone].parent=v??'';_changed();}),
    ] else if(_tab==1)...[
      const Text('Paint a mask directly on the canvas. Mask strokes are stored per workspace.',style:TextStyle(fontSize:11,color:Colors.white60)),SwitchListTile(value:_maskErase,onChanged:(v)=>setState(()=>_maskErase=v),title:const Text('Erase mask',style:TextStyle(fontSize:12))),_slider('Brush size',_brush,4,100,(v)=>setState(()=>_brush=v)),FilledButton.icon(onPressed:_sourceImage==null?null:_inpaintMaskedArea,icon:const Icon(Icons.auto_fix_high),label:const Text('Inpaint masked area')),TextButton.icon(onPressed:()=>setState(()=>_maskStrokes.clear()),icon:const Icon(Icons.delete_outline),label:const Text('Clear mask')),
    ] else if(_tab==2)...[
      const Text('Liquify brush · drag on the canvas to deform the preview mesh.',style:TextStyle(fontSize:11,color:Colors.white60)),_slider('Brush size',_brush,8,120,(v)=>setState(()=>_brush=v)),_slider('Strength',_strength,.05,1,(v)=>setState(()=>_strength=v)),TextButton.icon(onPressed:()=>setState(()=>_liquifyStrokes.clear()),icon:const Icon(Icons.refresh),label:const Text('Reset liquify')),
    ] else if(_tab==3)...[
      const Text('Select a bone, move its joints on the canvas, then add keyframes on the timeline.',style:TextStyle(fontSize:11,color:Colors.white60)),if(_selectedBone>=0&&_selectedBone<_bones.length)_slider('Rotation',_bones[_selectedBone].rotation,-math.pi,math.pi,(v){_bones[_selectedBone].rotation=v;_changed();}),FilledButton.icon(onPressed:_addKey,icon:const Icon(Icons.key),label:const Text('Keyframe selected')),const SizedBox(height:8),OutlinedButton.icon(onPressed:_openGraphEditor,icon:const Icon(Icons.show_chart),label:const Text('Graph / easing editor')),
    ] else ...[
      const Text('Add an effect clip and choose which layer receives it.',style:TextStyle(fontSize:11,color:Colors.white60)),
      DropdownButtonFormField<String>(value:_target,decoration:const InputDecoration(labelText:'Target layer'),items:[for(final n in (widget.layerNames.isEmpty?['Layer 1']:widget.layerNames))DropdownMenuItem(value:n,child:Text(n,overflow:TextOverflow.ellipsis))],onChanged:(v)=>setState(()=>_target=v??_target)),
      Wrap(spacing:6,children:[for(final name in ['Shake','Pulse','Bounce','Oscillate','Spin','Swing','Wobble','Impact','Drift','Twitch','Bend','Wind','Liquify'])ActionChip(label:Text(name),onPressed:()=>_addEffect(name))]),
      for(int i=0;i<_effects.length;i++)ListTile(dense:true,selected:_selectedEffect==i,title:Text(_effects[i].name,style:const TextStyle(fontSize:12)),subtitle:Text('Target: ${_effects[i].target}',style:const TextStyle(fontSize:9)),onTap:()=>setState(()=>_selectedEffect=i),trailing:IconButton(onPressed:(){_effects.removeAt(i);_selectedEffect=-1;_changed();},icon:const Icon(Icons.delete_outline,size:17))),
      if(_selectedEffect>=0&&_selectedEffect<_effects.length)_slider('Effect strength',_effects[_selectedEffect].strength,0,2,(v){_effects[_selectedEffect].strength=v;_changed();}),
    ],
  ])));
  Widget _slider(String title,double value,double min,double max,ValueChanged<double> change)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('$title  ${value.toStringAsFixed(2)}',style:const TextStyle(fontSize:11,color:Colors.white70)),Slider(value:value.clamp(min,max).toDouble(),min:min,max:max,onChanged:change,activeColor:_accent)]);
}

class _RigPainter extends CustomPainter {
  final List<_RigBone> bones; final int selected,tab,time,duration; final List<List<Offset>> masks,liquify; final List<MangaCutEffectClip> effects; final double brush,strength; final ui.Image? sourceImage;
  _RigPainter(this.bones,this.selected,this.masks,this.liquify,this.tab,this.brush,this.strength,this.sourceImage,this.time,this.duration,this.effects);
  void paintComposite(Canvas canvas,Size size){
    if(sourceImage==null)return;
    canvas.save();
    _applyMotionEffects(canvas,size);
    canvas.saveLayer(Offset.zero & size,Paint());
    _drawImageMesh(canvas,size,sourceImage!);
    final erase=Paint()..blendMode=BlendMode.dstOut..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round..strokeWidth=brush;
    for(final stroke in masks){
      if(stroke.length==1)canvas.drawCircle(Offset(stroke.first.dx*size.width,stroke.first.dy*size.height),brush/2,Paint()..blendMode=BlendMode.dstOut);
      for(var i=1;i<stroke.length;i++)canvas.drawLine(Offset(stroke[i-1].dx*size.width,stroke[i-1].dy*size.height),Offset(stroke[i].dx*size.width,stroke[i].dy*size.height),erase);
    }
    canvas.restore();
    canvas.restore();
  }
  @override void paint(Canvas c,Size s){
    final bg=Paint()..color=const Color(0xFF171A22);c.drawRect(Offset.zero & s,bg);
    final grid=Paint()..color=Colors.white.withOpacity(.045)..strokeWidth=1;
    for(double x=0;x<s.width;x+=24)c.drawLine(Offset(x,0),Offset(x,s.height),grid);
    for(double y=0;y<s.height;y+=24)c.drawLine(Offset(0,y),Offset(s.width,y),grid);
    final center=Offset(s.width*.5,s.height*.5);
    if(sourceImage!=null){
      paintComposite(c,s);
    } else {
      c.drawOval(Rect.fromCenter(center:center,width:s.width*.28,height:s.height*.48),Paint()..color=const Color(0xFF29364A));
      c.drawCircle(center.translate(0,-s.height*.31),s.width*.065,Paint()..color=const Color(0xFF52647B));
      for(final stroke in masks){final p=Paint()..color=Colors.white.withOpacity(.8)..strokeWidth=brush..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;for(int i=1;i<stroke.length;i++)c.drawLine(Offset(stroke[i-1].dx*s.width,stroke[i-1].dy*s.height),Offset(stroke[i].dx*s.width,stroke[i].dy*s.height),p);}
    }
    for(final stroke in liquify){final p=Paint()..color=const Color(0xFFB78BFF).withOpacity(.8)..strokeWidth=2..style=PaintingStyle.stroke;for(int i=1;i<stroke.length;i++)c.drawLine(Offset(stroke[i-1].dx*s.width,stroke[i-1].dy*s.height),Offset(stroke[i].dx*s.width,stroke[i].dy*s.height),p);}
    for(int i=0;i<bones.length;i++){final b=bones[i];final localA=Offset(b.a.dx*s.width,b.a.dy*s.height),localB=Offset(b.b.dx*s.width,b.b.dy*s.height);final rotatedB=localA+Offset((localB-localA).dx*math.cos(b.rotation)-(localB-localA).dy*math.sin(b.rotation),(localB-localA).dx*math.sin(b.rotation)+(localB-localA).dy*math.cos(b.rotation));final a=_applyParentTransforms(i,localA,s),z=_applyParentTransforms(i,rotatedB,s);final p=Paint()..color=(i==selected?const Color(0xFFFFD76A):const Color(0xFF71D8FF))..strokeWidth=(i==selected?5.0:3.0)..strokeCap=StrokeCap.round;c.drawLine(a,z,p);c.drawCircle(a,6,Paint()..color=Colors.white);c.drawCircle(z,7,Paint()..color=p.color);}
    if(tab==2){final p=Paint()..color=const Color(0xFFB78BFF).withOpacity(.12)..style=PaintingStyle.stroke..strokeWidth=1;for(int x=0;x<8;x++)for(int y=0;y<6;y++){final dx=s.width*x/7,dy=s.height*y/5;c.drawCircle(Offset(dx,dy),2,p);}}
  }
  Offset _applyParentTransforms(int index,Offset point,Size size){
    final visited=<int>{};var parentId=bones[index].parent;
    while(parentId.isNotEmpty){final parentIndex=bones.indexWhere((bone)=>bone.id==parentId);if(parentIndex<0||!visited.add(parentIndex))break;final parent=bones[parentIndex];final pivot=Offset(parent.a.dx*size.width,parent.a.dy*size.height);final dx=point.dx-pivot.dx,dy=point.dy-pivot.dy;point=pivot+Offset(dx*math.cos(parent.rotation)-dy*math.sin(parent.rotation),dx*math.sin(parent.rotation)+dy*math.cos(parent.rotation));parentId=parent.parent;}
    return point;
  }
  double _effectStrength(String name){
    final normalized=time/duration;
    var total=0.0;
    for(final effect in effects){
      if(effect.name.toLowerCase()!=name.toLowerCase())continue;
      if(normalized>=effect.start&&normalized<=effect.end)total+=effect.strength;
    }
    return total;
  }
  void _applyMotionEffects(Canvas canvas,Size size){
    final seconds=time/1000.0;
    final shake=_effectStrength('Shake')+_effectStrength('Twitch')*.45;
    final pulse=_effectStrength('Pulse')+_effectStrength('Bounce')*.35;
    final spin=_effectStrength('Spin');
    final swing=_effectStrength('Swing')+_effectStrength('Wobble')*.35;
    final drift=_effectStrength('Drift');
    final impact=_effectStrength('Impact');
    final center=Offset(size.width/2,size.height/2);
    final dx=math.sin(seconds*31)*shake*5+math.sin(seconds*2.2)*drift*size.width*.025;
    final dy=math.cos(seconds*27)*shake*3-math.abs(math.sin(seconds*5))*impact*size.height*.025;
    final scale=1+math.sin(seconds*5)*pulse*.035;
    final angle=math.sin(seconds*4)*swing*.08+seconds*spin*.35;
    canvas.translate(center.dx+dx,center.dy+dy);
    canvas.rotate(angle);
    canvas.scale(scale,scale);
    canvas.translate(-center.dx,-center.dy);
  }
  Offset _deformByBones(Offset point,Size size){
    final radius=math.max(24.0,math.min(size.width,size.height)*.22);
    for(var i=0;i<bones.length;i++){
      final bone=bones[i];
      if(bone.rotation.abs()<.0001)continue;
      final localA=Offset(bone.a.dx*size.width,bone.a.dy*size.height);
      final localB=Offset(bone.b.dx*size.width,bone.b.dy*size.height);
      final rotatedB=localA+Offset(
        (localB-localA).dx*math.cos(bone.rotation)-(localB-localA).dy*math.sin(bone.rotation),
        (localB-localA).dx*math.sin(bone.rotation)+(localB-localA).dy*math.cos(bone.rotation),
      );
      final a=_applyParentTransforms(i,localA,size);
      final b=_applyParentTransforms(i,rotatedB,size);
      final segment=b-a;
      final lengthSquared=segment.dx*segment.dx+segment.dy*segment.dy;
      final projection=lengthSquared==0?0.0:(((point-a).dx*segment.dx+(point-a).dy*segment.dy)/lengthSquared).clamp(0.0,1.0).toDouble();
      final nearest=a+segment*projection;
      final distance=(point-nearest).distance;
      if(distance>=radius)continue;
      final influence=1-distance/radius;
      final weight=influence*influence*(3-2*influence);
      final angle=bone.rotation*weight;
      final delta=point-a;
      point=a+Offset(delta.dx*math.cos(angle)-delta.dy*math.sin(angle),delta.dx*math.sin(angle)+delta.dy*math.cos(angle));
    }
    return point;
  }
  void _drawImageMesh(Canvas canvas,Size size,ui.Image image){
    const cols=24, rows=24;
    final positions=<Offset>[], tex=<Offset>[], indices=<int>[];
    for(var y=0;y<=rows;y++){
      for(var x=0;x<=cols;x++){
        final u=x/cols,v=y/rows;
        var px=u*size.width,py=v*size.height;
        final bend=_effectStrength('Bend');
        final wind=_effectStrength('Wind');
        if(bend>0){py+=math.sin(u*math.pi)*bend*size.height*.12;}
        if(wind>0){px+=math.sin(v*9+time*.006)*wind*size.width*.025*(1-v*.35);py+=math.cos(u*7+time*.004)*wind*size.height*.008;}
        {
          for(final stroke in liquify){
            for(var k=1;k<stroke.length;k++){
              final prev=stroke[k-1],cur=stroke[k];
              final dx=cur.dx-prev.dx,dy=cur.dy-prev.dy;
              final cx=cur.dx*size.width,cy=cur.dy*size.height;
              final vx=px-cx,vy=py-cy;
              final radius=brush*1.8,dist=math.sqrt(vx*vx+vy*vy);
              if(dist<radius){
                final falloff=1-dist/radius;
                px-=dx*size.width*strength*falloff*2.2;
                py-=dy*size.height*strength*falloff*2.2;
              }
            }
          }
        }
        final deformed=_deformByBones(Offset(px,py),size);
        positions.add(deformed);
        tex.add(Offset(u*image.width.toDouble(),v*image.height.toDouble()));
      }
    }
    for(var y=0;y<rows;y++)for(var x=0;x<cols;x++){
      final a=y*(cols+1)+x,b=a+1,d=a+cols+1,e=d+1;
      indices.addAll([a,b,d,b,e,d]);
    }
    final vertices=ui.Vertices(ui.VertexMode.triangles,positions,textureCoordinates:tex,indices:indices);
    final shader=ui.ImageShader(image,ui.TileMode.clamp,ui.TileMode.clamp,Float64List.fromList([1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]));
    canvas.drawVertices(vertices,BlendMode.src,Paint()..shader=shader);
  }
  @override bool shouldRepaint(covariant _RigPainter old)=>true;
}
class _CurvePreviewPainter extends CustomPainter {
  final String mode;final double overshoot;
  _CurvePreviewPainter(this.mode,this.overshoot);
  @override void paint(Canvas canvas,Size size){
    final grid=Paint()..color=Colors.white24..strokeWidth=1;
    canvas.drawLine(Offset(0,size.height),Offset(size.width,size.height),grid);
    canvas.drawLine(Offset(0,0),Offset(0,size.height),grid);
    final path=Path();
    for(var i=0;i<=100;i++){
      final t=i/100;double v=t;
      switch(mode){
        case 'Ease In':v=t*t*t;break;
        case 'Ease Out':v=1-math.pow(1-t,3).toDouble();break;
        case 'Ease In Out':v=t<.5?4*t*t*t:1-math.pow(-2*t+2,3).toDouble()/2;break;
        case 'Overshoot':final c1=1.70158*(overshoot/.18);final c3=c1+1;v=1+c3*math.pow(t-1,3).toDouble()+c1*math.pow(t-1,2).toDouble();break;
      }
      final point=Offset(t*size.width,size.height-v*size.height);
      if(i==0)path.moveTo(point.dx,point.dy);else path.lineTo(point.dx,point.dy);
    }
    canvas.drawPath(path,Paint()..color=const Color(0xFF8A68FF)..style=PaintingStyle.stroke..strokeWidth=3);
  }
  @override bool shouldRepaint(covariant _CurvePreviewPainter old)=>old.mode!=mode||old.overshoot!=overshoot;
}
class _StudioTimelinePainter extends CustomPainter{
  final List<_RigBone> bones;final List<MangaCutEffectClip> effects;final int time,duration;
  _StudioTimelinePainter(this.bones,this.effects,this.time,this.duration);
  @override void paint(Canvas c,Size s){
    final row=math.max(22.0,s.height/(bones.length+effects.length+1)).toDouble();final line=Paint()..color=Colors.white12;
    for(int i=0;i<bones.length+effects.length+1;i++)c.drawLine(Offset(0,row*i),Offset(s.width,row*i),line);
    var r=0;for(final b in bones){final y=row*(r+.5);c.drawTextMarker(Offset(4,y-6),b.name,Colors.white70);for(final k in (b.rotationKeys.isEmpty?b.keys:b.rotationKeys.keys.toList())){final x=k/duration*s.width;c.drawCircle(Offset(x.toDouble(),y),4,Paint()..color=const Color(0xFFFFD76A));}r++;}
    for(final e in effects){final y=row*(r+.5),x=e.start*s.width,w=(e.end-e.start)*s.width;c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x.toDouble(),y-8,w.clamp(0.0,s.width).toDouble(),16),const Radius.circular(3)),Paint()..color=const Color(0xFF7655E8));for(final k in e.keys)c.drawCircle(Offset(k/duration*s.width,y),3,Paint()..color=Colors.white);r++;}
    final x=time/duration*s.width;c.drawLine(Offset(x.toDouble(),0),Offset(x.toDouble(),s.height),Paint()..color=Colors.white..strokeWidth=2);
  }
  @override bool shouldRepaint(covariant _StudioTimelinePainter old)=>true;
}
extension on Canvas{void drawTextMarker(Offset p,String text,Color color){final tp=TextPainter(text:TextSpan(text:text,style:TextStyle(color:color,fontSize:9)),textDirection:TextDirection.ltr)..layout(maxWidth:110);tp.paint(this,p);}}
