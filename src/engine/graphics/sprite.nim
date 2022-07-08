import stb_image/read as stbi
import nimgl/opengl
import glm
import gl_rectangle
import shader

# An sprite allows displaying of an image, optionally clipped, colored, scaled and flipped
type Sprite* = ref object
    texture_id: GLuint
    shader*: Shader
    texture_width*, texture_height*: int
    # In UV coordinates
    clip*: Vec4f
    # Tint color
    tint*: Vec4f
    flip_h*, flip_v*: bool
    layer*: int
    # Position, to be used with the renderer
    position*: Vec2f
    scale*: Vec2f

proc create_sprite*(image: GLuint, width: int, height: int): Sprite =
    return Sprite(texture_id: image, texture_width: width, texture_height: height,
        clip: vec4f(0, 0, 1, 1),  tint: vec4f(1.0, 1.0, 1.0, 1.0),
        shader: load_shader("res/shader/sprite"), scale: vec2f(1.0, 1.0))

proc create_sprite*(image: string): Sprite = 
    var width, height, nCh : int
    var data = stbi.load(image, width, height, nCh, 0)

    var tex: Gluint
    glGenTextures(1, addr tex)
    glBindTexture(GL_TEXTURE_2D, tex)

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)

    # The OpenGL bindings are a bit annoying with the types of enums!
    glTexImage2D(GL_TEXTURE_2D, 0'i32, GL_RGBA.GLint, width.GLsizei, 
        height.GLsizei, 0.GLint, GL_RGBA, GL_UNSIGNED_BYTE, addr data[0])

    return create_sprite(tex, width, height);

proc do_draw*(sprite: Sprite) = 
    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, sprite.texture_id)
    # Shader is already used by renderer draw
    sprite.shader.set_int("tex", 0)
    sprite.shader.set_int("flip_h", if sprite.flip_h: 1 else: 0)
    sprite.shader.set_int("flip_v", if sprite.flip_v: 1 else: 0)
    sprite.shader.set_vec4("tint", sprite.tint)
    sprite.shader.set_vec4("clip", sprite.clip)
    var stform = mat4f().scale(sprite.scale.x * sprite.texture_width.toFloat, 
        sprite.scale.y * sprite.texture_height.toFloat, 1.0)
    sprite.shader.set_mat4("sprite_tform", stform)
    draw_rectangle()

# An animated sprite uses sprite to display an image that has animation