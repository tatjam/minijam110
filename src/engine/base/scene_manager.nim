import renderer as rnd
import macros

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

# Entities are an utility to avoid manually having to keep track of many objects,
# there is no full fledged ECS system. They are neatly integrated into Scenes
# Entities may be created, but they are not deleted until scene is unloaded
# this is made so we avoid having to reference count, and is not a bad idea
# TODO: It's a bad idea if the game grows more! Implement reference counting

type EntityID* = distinct int

type 
    Scene* = ref object of RootObj
        entities*: seq[Entity]
    Entity* = ref object of RootObj
        # Dead entities dont get updated, nor rendered
        alive: bool
        id: EntityID

# called when the entity is added to the scene
method init(this: Entity) {.base.} = return
method update(this: Entity, scene: ptr Scene) {.base.} = return
method paused_update(this: Entity, scene: ptr Scene, is_background: bool) {.base.} = return
method render(this: Entity) {.base.} = return
method unload(this: Entity) {.base.} = return
method on_die(this: Entity) {.base.} = return
method pause(this: Entity) {.base.} = return
method resume(this: Entity) {.base.} = return

method get_id*(this: Entity): EntityID = return this.id
method kill*(this: Entity) = 
    if not this.alive:
        this.on_die()
        this.alive = false

# Do not forget to call those ALWAYS if you override!
macro base_update*() = quote do:
    for ent in this.entities:
        update(ent, cast[ptr Scene](addr this))
macro base_paused_update*(is_background: bool) = quote do:
    for ent in this.entities:
        paused_update(ent, cast[ptr Scene](addr this), is_background)
macro base_render*() = quote do:
    for ent in this.entities:
        ent.render()
macro base_unload*() = quote do:
    for ent in this.entities:
        ent.unload()
macro base_pause*() = quote do:
    for ent in this.entities:
        ent.pause()
macro base_resume*() = quote do:
    for ent in this.entities:
        ent.resume()


method init(this: var Scene) {.base.} = return
method update(this: var Scene) {.base.} = base_update()
method paused_update(this: var Scene, is_background: bool) {.base.} = base_paused_update(is_background)
method render(this: var Scene) {.base.} = base_render()
method unload(this: var Scene) {.base.} = base_unload()
method pause(this: var Scene) {.base.} = base_pause()
method resume(this: var Scene) {.base.} = base_resume()


# You may hold the pointer for as long as the scene is alive
# TODO: Implement reference counting here
method `[]`*(scene: Scene, id: EntityID): ptr Entity {.base.} = 
    let idint = cast[int](id)
    assert idint >= 0 and idint < scene.entities.len
    return addr scene.entities[idint] 

macro create_entity*(ent: untyped): untyped = 
    quote do:
        this.entities.add(`ent`)
        this.entities[^1].id = cast[EntityID](this.entities.len - 1)
        this.entities[^1].init()
        this.entities[^1].id

var game_ended* = false
var scene_stack = newSeq[Scene]()
var overlaid = false

# Loads a new scene, optionally as an overlay. Overlays may not load further scenes!
proc load_scene*(scene: Scene, overlay: bool = false) =
    assert overlaid == false
    var nscene = new(type(scene))
    
    if scene_stack.len > 0:
        scene_stack[^1].pause()
    scene_stack.add(nscene)
    if overlay:
        assert scene_stack.len >= 2
        overlaid = true
    nscene.init()

# Drops all scene and goes to a new one, useful to reset the game
proc goto_scene*(scene: Scene) = 
    for scene in mitems(scene_stack):
        scene.unload()
    scene_stack.setLen(0)
    scene_stack.add(scene)
    overlaid = false
    scene_stack[^1].init()

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
        for i in countup(0, scene_stack.len - 3):
            scene_stack[i].paused_update(false)

proc scene_manager_render*(renderer: Renderer) = 
    
    scene_stack[^1].render()
    if overlaid:
        renderer.layer_bias = true
        scene_stack[^2].render()
        renderer.layer_bias = false
