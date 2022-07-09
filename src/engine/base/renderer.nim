# Implements generic, layered drawing for drawables, binding
# only the most basic uniforms in the shaders:
#    tform: camera + object transformation
# It renders to a framebuffer to allow fullscreen effects,
# and also has a effect texture, used for lighting in this case
# Layering is achieved by the use of the depth buffer!
# Drawables must implement:
# -> .position (returns Vec2f, position of the drawable), (optional if using draw_at)
# -> .shader (returns a shader to be used for the draw)
# -> .do_draw (calls the appropiate OpenGL for actually drawing the object, including additional shader stuff)
# -> .layer (returns int, the layer of the object)
# Keep layers below LAYER_CAP, as its used for scene overlaying
# Note that layering doesn't work with alpha blending! You must manually implement sorting if needed

import ../graphics/camera
import ../graphics/shader
import ../graphics/gl_rectangle
import glm
import nimgl/opengl

const LAYER_CAP = 100000

type Renderer* = ref object
    camera*: Camera 
    int_t: float
    fullscreen_shader*: Shader
    fbuffer, rnd_texture, light_texture, depth_buffer: GLuint
    # All drawable calls while layer_bias is enabled get increased by LAYER_CAP
    layer_bias*: bool
    width*, height*: int
    # global scale factor
    scale*: int

proc resize(renderer: var Renderer, width: int, height: int) = 

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
    
    glTexImage2D(GL_TEXTURE_2D, 0'i32, GL_RGBA.GLint, width.GLsizei, height.GLsizei, 0.GLint, GL_RGBA, GL_UNSIGNED_BYTE, nil)
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.GLint)
    
    glGenTextures(1, addr renderer.light_texture)
    glBindTexture(GL_TEXTURE_2D, renderer.light_texture)

    glTexImage2D(GL_TEXTURE_2D, 0'i32, GL_RGBA.GLint, width.GLsizei, height.GLsizei, 0.GLint, GL_RGBA, GL_UNSIGNED_BYTE, nil)

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.GLint)

    glGenRenderbuffers(1, addr renderer.depth_buffer)
    glBindRenderbuffer(GL_RENDERBUFFER, renderer.depth_buffer)
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, width.GLsizei, height.GLsizei)
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, renderer.depth_buffer)

    glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, renderer.rnd_texture, 0)
    glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, renderer.light_texture, 0)
    var dbuffers = [GL_COLOR_ATTACHMENT_0, GL_COLOR_ATTACHMENT1]
    glDrawBuffers(2, addr dbuffers[0])



proc create_renderer*(shader_path: string, width: int, height: int, scale: int): Renderer = 
    let shader = load_shader(shader_path)
    let camera = create_camera()
    var rnd = Renderer(camera: camera, fullscreen_shader: shader, scale: scale)
    rnd.resize(toInt(width / scale), toInt(height / scale))
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    return rnd

# Call to get timed effect
proc update*(renderer: Renderer, dt: float) = 
    renderer.int_t += dt

# Render stuff to the framebuffer after this call
proc before_render*(renderer: Renderer) =
    glViewport(0, 0, renderer.width.GLsizei, renderer.height.GLsizei)
    glBindFramebuffer(GL_FRAMEBUFFER, renderer.fbuffer) 
    glClearColor(0.0, 0.0, 0.0, 1.0)
    glClear(GL_COLOR_BUFFER_BIT)

# Stop rendering stuff to the framebuffer after this call
proc render*(renderer: Renderer) = 
    glViewport(0, 0, (renderer.width * renderer.scale).GLsizei, (renderer.height * renderer.scale).GLsizei)
    # Draw the fullscreen rectangle, binding texture 0
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    renderer.fullscreen_shader.use()
    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, renderer.rnd_texture)
    renderer.fullscreen_shader.set_int("tex", 0)
    glActiveTexture(GL_TEXTURE1)
    glBindTexture(GL_TEXTURE_2D, renderer.light_texture)
    renderer.fullscreen_shader.set_int("fxtex", 1)
    
    renderer.fullscreen_shader.set_float("t", renderer.int_t)

    var tform = translate(mat4f(), -1.0, -1.0, 0.0)
        .scale(vec3f(2.0))
    renderer.fullscreen_shader.set_mat4("tform", tform)
    draw_rectangle()

proc draw*[T](renderer: Renderer, drawable: T) =
    drawable.shader.use()
    
    let pos = drawable.position
    var layer = drawable.layer
    assert layer < LAYER_CAP
    if renderer.layer_bias:
        layer += LAYER_CAP
    var tform = renderer.camera.get_transform_matrix(renderer.width, renderer.height)
    tform = tform.translate(pos.x, pos.y, layer.toFloat())

    drawable.shader.set_mat4("tform", tform)
    drawable.do_draw()

proc draw_at*[T](renderer: Renderer, drawable: T, pos: Vec2f) =
    drawable.shader.use()
    
    var layer = drawable.layer
    assert layer < LAYER_CAP
    if renderer.layer_bias:
        layer += LAYER_CAP
    var tform = renderer.camera.get_transform_matrix(renderer.width, renderer.height)
    tform = tform.translate(pos.x, pos.y, layer.toFloat())

    drawable.shader.set_mat4("tform", tform)
    drawable.do_draw()