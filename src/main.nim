import nimgl/[glfw]
#import game/scenes/intro
#import game/scenes/level1
#import game/scenes/cutsc1
import game/scenes/level2

include engine/base

goto_scene(Level2Scene())


proc update() = 
    if glfw_window.windowShouldClose:
        should_quit = true

update_fnc = update

launch_game()