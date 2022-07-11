import nimgl/[glfw]
import game/scenes/intro
#import game/scenes/level1
#import game/scenes/cutsc1
#import game/scenes/level2
#import game/scenes/level3
#import game/scenes/cutsc2
#import game/scenes/level4
#import game/scenes/cutsc3

include engine/base

goto_scene(IntroScene())


proc update() = 
    if glfw_window.windowShouldClose:
        should_quit = true

update_fnc = update

launch_game()