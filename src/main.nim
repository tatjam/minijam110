import nimgl/[glfw, opengl]
import game/scenes/intro

include engine/base

load_scene(Level1Scene())

proc update() = 
    if glfw_window.windowShouldClose:
        should_quit = true

update_fnc = update

launch_game()