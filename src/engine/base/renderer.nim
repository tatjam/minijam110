# Do not "import" as it will cause issues with the global "renderer"!
# (it's already included by base)

# Implements generic, layered drawing for drawables, binding
# only the most basic uniforms in the shaders:
#    tform: camera + object transformation
# It renders to a framebuffer to allow fullscreen effects
# Layering is achieved by the use of the depth buffer!
# Drawables must implement:
# -> .position (returns Vec2f, position of the drawable), (optional if using draw_at)
# -> .shader (returns a shader to be used for the draw)
# -> .do_draw (calls the appropiate OpenGL for actually drawing the object, including additional shader stuff)
# -> .layer (returns int, the layer of the object)
# Keep layers below LAYER_CAP, as its used for scene overlaying

import ../graphics/camera
import ../graphics/shader
import ../graphics/gl_rectangle
import glm
import nimgl/opengl

const LAYER_CAP = 100000

type Renderer* = ref object
    camera*: Camera 
    fullscreen_shader*: Shader
    fbuffer, rnd_texture, depth_buffer: GLuint
    # All drawable calls while layer_bias is enabled get increased by LAYER_CAP
    layer_bias*: bool
    width*, height*: int

proc resize(renderer: var Renderer, width: int, height: int) = 
    glViewport(0, 0, width.GLsizei, height.GLsizei)

    renderer.width = width
    renderer.height = height

    # Remove the old buffers if present
    if renderer.fbuffer != 0:
        glDeleteFramebuffers(1, addr renderer.fbuffer)
        glDeleteTextures(1, addr renderer.rnd_texture)
        glDeleteRenderbuffers(1, addr renderer.depth_buffer)
    
    glGenFramebuffers(1, addr renderer.fbuffer)
    glBindFramebuffer(GL_FRAMEBUFFER, renderer.fbuffer)
    
    glGenTextures(1, addr renderer.rnd_texture)
    glBindTexture(GL_TEXTURE_2D, renderer.rnd_texture)

    glTexImage2D(GL_TEXTURE_2D, 0'i32, GL_RGB.GLint, width.GLsizei, height.GLsizei, 0.GLint, GL_RGB, GL_UNSIGNED_BYTE, nil)

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.GLint)

    glGenRenderbuffers(1, addr renderer.depth_buffer)
    glBindRenderbuffer(GL_RENDERBUFFER, renderer.depth_buffer)
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, width.GLsizei, height.GLsizei)
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, renderer.depth_buffer)

    glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, renderer.rnd_texture, 0)
    var dbuffers = [GL_COLOR_ATTACHMENT_0]
    glDrawBuffers(1, addr dbuffers[0])



proc create_renderer*(shader_path: string, width: int, height: int): Renderer = 
    let shader = load_shader(shader_path)
    let camera = create_camera()
    var rnd = Renderer(camera: camera, fullscreen_shader: shader)
    rnd.resize(width, height)
    return rnd

# Render stuff to the framebuffer after this call
proc before_render*(renderer: Renderer) =
    glBindFramebuffer(GL_FRAMEBUFFER, renderer.fbuffer)

# Stop rendering stuff to the framebuffer after this call
proc render*(renderer: Renderer) = 

    # Draw the fullscreen rectangle, binding texture 0
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    renderer.fullscreen_shader.use()
    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, renderer.rnd_texture)
    renderer.fullscreen_shader.set_int("tex", 0)

    var tform = translate(mat4f(), -1.0, -1.0, 0.0).scale(2.0, 2.0, 2.0)
    renderer.fullscreen_shader.set_mat4("tform", tform)
    draw_rectangle()

proc draw*[T](renderer: Renderer, drawable: T) =
    drawable.shader.use()
    
    let pos = drawable.position
    var layer = drawable.layer
    assert layer < LAYER_CAP
    if renderer.layer_bias:
        layer += LAYER_CAP
    var tform = renderer.camera.get_transform_matrix()
    tform = tform.translate(pos.x, pos.y, layer.toFloat())

    drawable.shader.set_mat4("tform", tform)
    drawable.do_draw()

proc draw_at*[T](renderer: Renderer, drawable: T, pos: Vec2f) =
    drawable.shader.use()
    
    var layer = drawable.layer
    assert layer < LAYER_CAP
    if renderer.layer_bias:
        layer += LAYER_CAP
    var tform = renderer.camera.get_transform_matrix()
    tform = tform.translate(pos.x, pos.y, layer.toFloat())

    drawable.shader.set_mat4("tform", tform)
    drawable.do_draw()