import stb_image/read as stbi
import nimgl/opengl
import glm
import gl_rectangle
import shader
import std/tables
import yaml/serialization, streams

# An sprite allows displaying of an image, optionally clipped, colored, scaled and flipped
type Sprite* = ref object
    # optional, may be 0
    texture_id: GLuint
    # optional, may be 0
    fx_texture_id: GLuint
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
    rotation: float
    scale*: Vec2f
    # Movement in pixels respect to the sprite top-left corner
    # Also used for rotation
    scale_origin*: Vec2f

proc create_sprite*(image: GLuint, fx_image: GLuint, width: int, height: int): Sprite =
    return Sprite(texture_id: image, fx_texture_id: fx_image, texture_width: width, texture_height: height,
        clip: vec4f(0, 0, 1, 1),  tint: vec4f(1.0, 1.0, 1.0, 1.0),
        shader: load_shader("res/shader/sprite"), scale: vec2f(1.0, 1.0))

proc create_sprite*(image: string): Sprite = 
    var width, height, nCh : int
    var data = stbi.load(image, width, height, nCh, 4)

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

    return create_sprite(tex, 0, width, height);

proc create_fx_sprite*(image: string): Sprite = 
    var width, height, nCh : int
    var data = stbi.load(image, width, height, nCh, 4)

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

    return create_sprite(0, tex, width, height);

proc create_sprite*(image: string, fx_image: string): Sprite = 
    var width, height, nCh, fxwidth, fxheight : int
    var data = stbi.load(image, width, height, nCh, 0)
    var fxdata = stbi.load(fx_image, fxwidth, fxheight, nCh, 0)
    assert fxwidth == width and fxheight == height

    var tex, fxtex: Gluint
    glGenTextures(1, addr tex)
    glBindTexture(GL_TEXTURE_2D, tex)

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)

    # The OpenGL bindings are a bit annoying with the types of enums!
    glTexImage2D(GL_TEXTURE_2D, 0'i32, GL_RGBA.GLint, width.GLsizei, 
        height.GLsizei, 0.GLint, GL_RGBA, GL_UNSIGNED_BYTE, addr data[0])
    
    glGenTextures(1, addr fxtex)
    glBindTexture(GL_TEXTURE_2D, fxtex)

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)

    # The OpenGL bindings are a bit annoying with the types of enums!
    glTexImage2D(GL_TEXTURE_2D, 0'i32, GL_RGBA.GLint, width.GLsizei, 
        height.GLsizei, 0.GLint, GL_RGBA, GL_UNSIGNED_BYTE, addr fxdata[0])

    return create_sprite(tex, fxtex, width, height);

proc do_draw*(sprite: Sprite) = 
    # We do two passes, one for the texture, other for the effct
    sprite.shader.set_int("tex", 0)
    sprite.shader.set_int("flip_h", if sprite.flip_h: 1 else: 0)
    sprite.shader.set_int("flip_v", if sprite.flip_v: 1 else: 0)
    sprite.shader.set_vec4("tint", sprite.tint)
    sprite.shader.set_vec4("clip", sprite.clip)
    let w = sprite.texture_width.toFloat
    let h = sprite.texture_height.toFloat
    # Scale is applied respect to the center, so first center, scale, and uncenter
    # we also adjust the sprite so it's correctly clipped
    # Note that the whole sprite is being transformed!
    var stform = mat4f()
        .scale(sprite.clip.z, sprite.clip.w, 1.0)
        .scale(w, h, 1.0)
        .translate(sprite.scale_origin.x, sprite.scale_origin.y, 0.0)
        .scale(sprite.scale.x, sprite.scale.y, 1.0)
        .rotate(sprite.rotation, 0, 0, 1)
        .translate(-sprite.scale_origin.x, -sprite.scale_origin.y, 0.0)
    sprite.shader.set_mat4("sprite_tform", stform)

    if sprite.fx_texture_id != 0:
        glActiveTexture(GL_TEXTURE0)
        glBindTexture(GL_TEXTURE_2D, sprite.fx_texture_id)
        sprite.shader.set_int("has_fx", 1)
        glDepthMask(false)
        draw_rectangle()
    
    if sprite.texture_id != 0:
        glActiveTexture(GL_TEXTURE0)
        glBindTexture(GL_TEXTURE_2D, sprite.texture_id)
        sprite.shader.set_int("has_fx", 0)
        glDepthMask(true)
        draw_rectangle()


proc `center_position=`*(sprite: Sprite, pos: Vec2f) = 
    sprite.position = vec2f(
        pos.x - sprite.texture_width.toFloat * 0.5 * sprite.clip.z, 
        pos.y - sprite.texture_height.toFloat * 0.5 * sprite.clip.w)

proc center_position*(sprite: Sprite): Vec2f = 
    return vec2f(
    sprite.position.x + sprite.texture_width.toFloat * 0.5 * sprite.clip.z, 
    sprite.position.y + sprite.texture_height.toFloat * 0.5 * sprite.clip.w)

type AnimationFrame* = object
    frame: Vec4f
    time: float

type Animation* = ref object
    time: float
    frame: int
    loop*: bool
    frames*: seq[AnimationFrame]

# An animated sprite uses sprite to display an image that has animation
# by changing the clip of the sprite, using a set of named frames
# and a set of animations
type AnimatedSprite* = ref object
    sprite*: Sprite
    animations*: Table[string, Animation]
    cur_anim*: string
    paused*: bool

proc do_draw*(sprite: AnimatedSprite) = 
    sprite.sprite.do_draw()

proc position*(sprite: AnimatedSprite): Vec2f = 
    return sprite.sprite.position

proc `position=`*(sprite: var AnimatedSprite, pos: Vec2f) =
    sprite.sprite.position = pos

proc layer*(sprite: AnimatedSprite): int = 
    return sprite.sprite.layer

proc `layer=`*(sprite: var AnimatedSprite, layer:int) =
    sprite.sprite.layer = layer

proc scale*(sprite: AnimatedSprite): Vec2f =  
    return sprite.sprite.scale

proc `scale=`*(sprite: AnimatedSprite, s: Vec2f) =  
    sprite.sprite.scale = s

proc shader*(sprite: AnimatedSprite): Shader = 
    return sprite.sprite.shader

proc `center_position=`*(sprite: AnimatedSprite, pos: Vec2f) = 
    sprite.sprite.center_position = pos

proc center_position*(sprite: AnimatedSprite): Vec2f = 
    return sprite.sprite.center_position

proc `rotation=`*(sprite: AnimatedSprite, r: float) = 
    sprite.sprite.rotation = r

proc rotation*(sprite: AnimatedSprite): float = 
    return sprite.sprite.rotation

proc animate*(sprite: var AnimatedSprite, dt: float) = 
    if sprite.paused:
        return

    if sprite.animations.has_key(sprite.cur_anim):
        var anim = sprite.animations[sprite.cur_anim]
        if anim.frame < anim.frames.len:
            anim.time += dt
            if anim.time >= anim.frames[anim.frame].time:
                anim.time = 0.0
                inc anim.frame
                if anim.frame >= anim.frames.len and anim.loop:
                    anim.frame = 0
                if anim.frame < anim.frames.len:
                    sprite.sprite.clip = anim.frames[anim.frame].frame

proc start_anim*(sprite: AnimatedSprite, anim: string, restart: bool = false) =
    if sprite.cur_anim != anim or restart:
        sprite.cur_anim = anim
        if sprite.animations.has_key(sprite.cur_anim):
            sprite.animations[sprite.cur_anim].time = 0
            sprite.animations[sprite.cur_anim].frame = 0

type FrameData = object
    clip: array[4, int]
    duration: float

type AnimationData = object
    name: string
    loop: bool
    frames: seq[FrameData]

type AnimatedSpriteData = object
    sprite: string
    scale_origin: array[2, float]
    fx_sprite: string
    animations: seq[AnimationData]

# Takes the YAML of the sprite
proc create_animated_sprite*(path: string): AnimatedSprite = 
    var data: AnimatedSpriteData
    var s = newFileStream(path)
    load(s, data)
    s.close()

    var sprite: Sprite
    if data.fx_sprite != "none":
        sprite = create_sprite(data.sprite, data.fx_sprite)
    else:
        sprite = create_sprite(data.sprite)

    var animations: Table[string, Animation]
    var cur_anim = data.animations[0].name
    for animation in data.animations:
        var anim = Animation()
        anim.time = 0.0
        anim.frame = 0
        anim.loop = animation.loop
        var frames: seq[AnimationFrame]
        for frame in animation.frames:
            var f: AnimationFrame
            f.time = frame.duration
            f.frame = vec4f(frame.clip[0] / sprite.texture_width, frame.clip[1] / sprite.texture_height,
                frame.clip[2] / sprite.texture_width, frame.clip[3] / sprite.texture_height)
            frames.add(f)
        anim.frames = frames
        animations[animation.name] = anim

    sprite.clip = animations[cur_anim].frames[0].frame
    sprite.scale_origin = vec2f(
        data.scale_origin[0] / (sprite.texture_width.toFloat * sprite.clip.z), 
        data.scale_origin[1] / (sprite.texture_height.toFloat * sprite.clip.w))

    return AnimatedSprite(sprite: sprite, animations: animations, cur_anim: cur_anim, paused: false)
