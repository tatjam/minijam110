import nimgl/opengl
import system

# A simple rectangle with UVs
let vertices: array[0..19, float32] = [
#   x    y    z     u    v
0.0'f32, 0.0, 0.0,  0.0, 0.0,
    0.0, 1.0, 0.0,  0.0, 1.0,
    1.0, 1.0, 0.0,  1.0, 1.0,
    1.0, 0.0, 0.0,  1.0, 0.0
]

let indices: array[0..5, int32] = [     
    0'i32, 1, 3, 1, 2, 3
]

var vao, vbo, ebo: GLuint = 0

proc get_rectangle(): GLuint =
    if vao == 0:
        glGenVertexArrays(1, addr vao)
        glGenBuffers(1, addr vbo)
        glGenBuffers(1, addr ebo)

        glBindVertexArray(vao)
        glBindBuffer(GL_ARRAY_BUFFER, vbo)
        glBufferData(GL_ARRAY_BUFFER, vertices.len * float32.sizeof, unsafeAddr vertices, GL_STATIC_DRAW)

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo)
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.len * int32.sizeof, unsafeAddr indices, GL_STATIC_DRAW)

        # position attribute
        glVertexAttribPointer(0'u32, 3'i32, EGL_FLOAT, false, 5 * float32.sizeof, cast[pointer](0))
        glEnableVertexAttribArray(0)

        glVertexAttribPointeR(1'u32, 2'i32, EGL_FLOAT, false, 5 * float32.sizeof, cast[pointer](3 * float32.sizeof))
        glEnableVertexAttribArray(1)

    return vao

proc draw_rectangle*() =
    glBindVertexArray(get_rectangle())
    glDrawElements(GL_TRIANGLES, 6.GLsizei, GL_UNSIGNED_INT, nil)

