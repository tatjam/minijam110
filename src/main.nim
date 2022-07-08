import nimgl/[glfw, opengl]

import engine/base
import engine/graphics/sprite
import engine/graphics/camera
import glm

type MenuScene = ref object of Scene

let scene = MenuScene()
method update(this: MenuScene) =
    return

method render(this: MenuScene) = 
    return

load_scene(scene)

proc update() = 
    if glfw_window.windowShouldClose:
        should_quit = true

update_fnc = update

launch_game()