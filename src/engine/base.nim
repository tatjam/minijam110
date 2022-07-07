import nimgl/[glfw, opengl]
import graphics/sprite
import graphics/renderer as rnd

var should_quit* = false
var renderer*: Renderer = nil

var update_fnc*: proc(dt: float, w: GLFWWindow) = nil
var render_fnc*: proc() = nil
var quit_fnc*: proc(w: GLFWWindow) = nil

proc launch_game*() =
    assert glfwInit()

    glfwWindowHint(GLFWContextVersionMajor, 3)
    glfwWindowHint(GLFWContextVersionMinor, 3)
    glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
    glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
    glfwWindowHint(GLFWResizable, GLFW_FALSE)

    let w: GLFWWindow = glfwCreateWindow(800, 600, "Minijam 110")
    if w == nil:
        quit(-1)
        
    w.makeContextCurrent()

    assert glInit()

    renderer = create_renderer("res/shader/fullscreen")

    var dt = 0.0
    # Launch the main loop
    while not should_quit:
        glfwPollEvents()

        update_fnc(dt, w)
        
        glClearColor(0.0, 0.0, 0.0, 1.0)
        glClear(GL_COLOR_BUFFER_BIT)

        renderer.render()
        if render_fnc != nil: render_fnc()

        w.swapBuffers()

    if quit_fnc != nil: quit_fnc(w)

    w.destroyWindow()
    glfwTerminate()