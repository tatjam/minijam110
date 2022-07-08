import nimgl/[glfw, opengl]
import os
include base/renderer
include base/scene_manager

var should_quit* = false
var renderer*: Renderer = nil
var dt*: float32

var update_fnc*: proc() = nil
var render_fnc*: proc() = nil
var quit_fnc*: proc() = nil

assert glfwInit()

glfwWindowHint(GLFWContextVersionMajor, 3)
glfwWindowHint(GLFWContextVersionMinor, 3)
glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
glfwWindowHint(GLFWResizable, GLFW_FALSE)

let glfw_window*: GLFWWindow = glfwCreateWindow(800, 600, "Minijam 110")
if glfw_window == nil:
    quit(-1)
    
glfw_window.makeContextCurrent()

# Active V-sync, useful to avoid FPS being in the thousands!
glfwSwapInterval(1)

assert glInit()

renderer = create_renderer("res/shader/fullscreen", 800, 600)

proc launch_game*() =
    assert scene_stack.len > 0, "Remember to add a scene before starting the game"

    var last_time = glfwGetTime()

    # Launch the main loop
    while not should_quit:
        glfwPollEvents()

        update_fnc()
        scene_manager_update()
        
        glClearColor(0.0, 0.0, 0.0, 1.0)
        glClear(GL_COLOR_BUFFER_BIT)

        renderer.before_render()
        if render_fnc != nil: render_fnc()
        scene_manager_render(renderer)
        renderer.render()

        glfw_window.swapBuffers()
        var new_time = glfwGetTime()
        dt = new_time - last_time
        last_time = new_time

    if quit_fnc != nil: quit_fnc()

    glfw_window.destroyWindow()
    glfwTerminate()