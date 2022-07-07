# Implements generic, layered drawing for drawables, binding
# only the most basic uniforms in the shaders:
#
import camera
import shader
import gl_rectangle
import glm

type Renderer* = ref object
    camera*: Camera 
    fullscreen_shader*: Shader

proc create_renderer*(shader_path: string): Renderer = 
    let shader = load_shader(shader_path)
    let camera = create_camera()
    return Renderer(camera: camera, fullscreen_shader: shader)

proc render*(renderer: Renderer) = 
    renderer.fullscreen_shader.use()
    var tform = translate(mat4f(), -1.0, -1.0, 0.0).scale(2.0, 2.0, 2.0)
    renderer.fullscreen_shader.set_mat4("tform", tform)
    draw_rectangle()

