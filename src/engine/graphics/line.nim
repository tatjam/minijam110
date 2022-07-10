import nimgl/opengl
import glm
import shader

# Draws a connected line, with width
type Line* = ref object
    vbo: GLuint
    vao: GLuint
    width*: float
    shader*: Shader
    position*: Vec2f
    rotation*: float
    scale*: Vec2f
    points: int
    layer*: int

    color*: Vec4f
    fx_color*: Vec4f

proc create_line*(points: seq[Vec2f], width: float = 1.0): Line =
    let shader = load_shader("res/shader/line")
    var verts: seq[float32]
    for point in points:
        verts.add(point.x)
        verts.add(point.y)
        verts.add(0.0)

    var vao: GLuint
    var vbo: GLuint
    glGenVertexArrays(1, addr vao)
    glGenBuffers(1, addr vbo) 

    glBindVertexArray(vao)

    glBindBuffer(GL_ARRAY_BUFFER, vbo)
    glBufferData(GL_ARRAY_BUFFER, verts.len * sizeof(float32), unsafeAddr verts[0], GL_STATIC_DRAW)
        
    # position attribute
    glVertexAttribPointer(0'u32, 3'i32, EGL_FLOAT, false, 3 * float32.sizeof, cast[pointer](0))
    glEnableVertexAttribArray(0)

    return Line(width: width, shader: shader, vbo: vbo, points: points.len, 
        fx_color: vec4f(0, 0, 0, 0), color: vec4f(1, 1, 1, 1), vao: vao, scale: vec2f(1.0, 1.0))

proc do_draw*(line: Line) = 
    var subtform = mat4f(1.0)
    subtform = subtform.rotate(line.rotation, 0, 0, 1).scale(line.scale.x, line.scale.y, 1.0)
    line.shader.set_mat4("subtform", subtform)
    line.shader.set_vec4("tint", line.color)
    line.shader.set_vec4("fx_tint", line.fx_color)

    glLineWidth(1.0)
    glBindVertexArray(line.vao)
    glDrawArrays(GL_LINE_STRIP, 0.GLint, line.points.GLsizei)