import renderer as rnd

# Implements a basic scene manager based on OOP.
# Scenes may implement the following functions:
# -> init(): called on load of the scene
# -> update(): called every frame the scene is active
# -> paused_update(is_background): called every frame the scene is paused. is_background is true if we are 
#       the scene that is being overlayed (useful, for example, to muffle sounds)
# -> render(): called every frame the scene is active / overlaid with rendering
# -> unload(): called on unloading of the scene
# -> pause(): called when an scene is loaded on top (useful to pause sounds, etc...)
# -> resume(): called when resuming as another scene is unloaded
# Scenes may be overlaid, in such a way that the bottom scene renders but does not update
# (Useful for menus. Only one scene may be overlaid on top of another)
# Bottom scenes are always below top scenes via the adding of a big number to the layer of upper scene
# Scene travel works in a stack fashion

type Scene* = ref object of RootObj

method init(this: Scene) {.base.} = return
method update(this: Scene) {.base.} = return
method paused_update(this: Scene, is_background: bool) {.base.} = return
method render(this: Scene) {.base.} = return
method unload(this: Scene) {.base.} = return
method pause(this: Scene) {.base.} = return
method resume(this: Scene) {.base.} = return

var game_ended* = false
var scene_stack = newSeq[Scene]()
var overlaid = false

# Loads a new scene, optionally as an overlay. Overlays may not load further scenes!
proc load_scene*(scene: Scene, overlay: bool = false) =
    assert overlaid == false
    
    if scene_stack.len > 0:
        scene_stack[^1].pause()
    scene_stack.add(scene)
    if overlay:
        assert scene_stack.len >= 2
        overlaid = true
    scene.init()

# Drops all scene and goes to a new one, useful to reset the game
proc goto_scene*(scene: Scene) = 
    for scene in scene_stack:
        scene.unload()
    scene_stack.setLen(0)
    scene_stack.add(scene)
    overlaid = false
    scene.init()

# Goes to previous scene
proc leave_scene*() = 
    scene_stack[^1].unload()
    scene_stack.setLen(scene_stack.len - 1)
    if scene_stack.len == 0:
        echo "Game ended"
        game_ended = true
        return
    scene_stack[^1].resume()
    if overlaid:
        overlaid = false

proc is_overlaid(): bool = return overlaid

proc scene_manager_update*() = 
    scene_stack[^1].update()
    if scene_stack.len >= 2:
        scene_stack[^2].paused_update(overlaid)
    if scene_stack.len >= 3:
        for scene in scene_stack[0..^3]:
            scene.paused_update(false)

proc scene_manager_render*(renderer: Renderer) = 
    
    scene_stack[^1].render()
    if overlaid:
        renderer.layer_bias = true
        scene_stack[^2].render()
        renderer.layer_bias = false