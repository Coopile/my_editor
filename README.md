# EditShift

EditShift is a Flutter-based video and motion editor with a dark, violet-and-cyan creative workspace.

## Current features
- Project home with locally stored project-list metadata
- Create, open, and delete project entries
- Video import and preview
- Text and mesh layers
- Layer transform, color, opacity, timing, and audio controls
- 50 effect presets (color treatments and blur variants)
- Layer keyframes for position, scale, rotation, and opacity
- Draggable pivot editing: double-click a layer to enter pivot mode
- Experimental bend/shear control for layers

## Run
```sh
flutter pub get
flutter run
```

## Current limitations
Project names are saved locally, but full edit timelines and imported media are not yet serialized as reopenable project files. Export/rendering is not implemented yet. Some effect presets use color-matrix variations rather than dedicated GPU shaders, and the bend control is a shear-style warp rather than a full mesh-bend renderer.
