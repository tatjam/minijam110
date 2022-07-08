# As renderer, do not manually import, as this is an integral part of the engine

# Implements a basic scene manager based on OOP.
# Scenes may implement the following functions:
# -> init(): called on load of the scene
# -> update(): called every frame the scene is active
# -> render(): called every frame the scene is active / overlaid with rendering
# -> unload(): called on unloading of the scene
# Scenes may be overlaid, in such a way that the bottom scene renders but does not update
# (Useful for menus. Only one scene may be overlaid on top of another)
# Bottom scenes are always below top scenes via the adding of a big number to the layer of upper scene
# Scene travel works in a stack fashion

type Scene* = ref object of RootObj

method init(this: Scene) {.base.} = return
method update(this: Scene) {.base.} = return
method render(this: Scene) {.base.} = return
method unload(this: Scene) {.base.} = return

var scene_stack = newSeq[Scene]()
var overlaid = false

# Loads a new scene, optionally as an overlay
proc load_scene*(scene: Scene, overlay: bool = false) =
    scene_stack.add(scene)
    if overlay:
        assert scene_stack.len >= 2
        assert overlaid == false
        overlaid = true

# Goes to previous scene
proc leave_scene*() = 
    scene_stack.setLen(scene_stack.len - 1)
    if overlaid:
        overlaid = false

proc is_overlaid(): bool = return overlaid

proc scene_manager_update*() = 
    scene_stack[^1].update()

proc scene_manager_render*(renderer: Renderer) = 
    
    scene_stack[^1].render()
    if overlaid:
        renderer.layer_bias = true
        scene_stack[^2].render()
        renderer.layer_bias = false