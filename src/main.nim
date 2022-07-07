import nimgl/[glfw, opengl]

import "engine/base.nim"


proc update(dt: float, w: GLFWWindow) = 
    if w.windowShouldClose:
        should_quit = true


update_fnc = update

launch_game()