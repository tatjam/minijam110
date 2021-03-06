import nimgl/[glfw, opengl]
import base/renderer as rnd
import base/scene_manager
import globals
import audio/audio_engine

assert glfwInit()

glfwWindowHint(GLFWContextVersionMajor, 3)
glfwWindowHint(GLFWContextVersionMinor, 3)
glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
glfwWindowHint(GLFWResizable, GLFW_FALSE)

glfw_window = glfwCreateWindow(1280, 768, "Minijam 110")
if glfw_window == nil:
    quit(-1)
    
glfw_window.makeContextCurrent()

# Active V-sync, useful to avoid FPS being in the thousands!
glfwSwapInterval(1)

assert glInit()

renderer = create_renderer("res/shader/fullscreen", 1280, 768, 2)

init_soloud()

proc launch_game*() =
    var last_time = glfwGetTime()

    # Launch the main loop
    while not should_quit:
        glfwPollEvents()

        update_fnc()
        renderer.update(dt)
        scene_manager_update()
        if should_quit:
            break

        renderer.before_render()
        if render_fnc != nil: render_fnc()
        scene_manager_render(renderer)
        renderer.render()

        glfw_window.swapBuffers()
        var new_time = glfwGetTime()
        dt = new_time - last_time
        if dt > 0.1:
            echo "Limiting delta-time!"
            dt = 0.1
        last_time = new_time

    if quit_fnc != nil: quit_fnc()

    glfw_window.destroyWindow()
    glfwTerminate()
    deinit_soloud()