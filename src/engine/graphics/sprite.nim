import stb_image/read as stbi
import nimgl/opengl
import glm


# An sprite allows displaying of an image, optionally clipped and colored
type Sprite* = ref object
    texture_id: GLuint
    texture_width*, texture_height*: int
    # In UV coordinates
    clip*: Vec4f
    # Tint color
    color*: Vec4f


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
        height.GLsizei, 0.GLint, GL_RGBA, GL_UNSIGNED_BYTE, addr data)

    return Sprite(texture_id: tex, texture_width: width, texture_height: height, 
        clip: vec4f(0, 0, 1, 1), color: vec4f(1.0, 1.0, 1.0, 1.0))




# An animated sprite uses sprite to display an image that has animation