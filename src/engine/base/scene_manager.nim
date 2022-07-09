import renderer as rnd

# Implements a basic scene manager based on OOP.
# Scenes may implement the following functions:
# -> init(): called on load of the scene
# -> update(): called every frame the scene is active
# -> render(): called every frame the scene is active / overlaid with rendering
# -> unload(): called on unloading of the scene
#
# Scenes may or may not use polymorph, as they wish 
#
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


method init(this: Scene) {.base.} = return
method update(this: Scene) {.base.} = return
method render(this: Scene) {.base.} = return
method unload(this: Scene) {.base.} = return

var current_scene: Scene

# Drops all scene and goes to a new one, useful to reset the game
proc goto_scene*(scene: Scene) = 
    scene.init()
    current_scene = scene

proc scene_manager_update*() = 
    current_scene.update()

proc scene_manager_render*(renderer: Renderer) = 
    current_scene.render()
